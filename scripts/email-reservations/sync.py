#!/usr/bin/env python3
"""Sync IMAP → Supabase.
Confirmaciones: Huilo, Corralco, Puyehue, Aguas Calientes, RateHawk (parsers específicos)
                + CUALQUIER hotel del catálogo (parser genérico).
Anular/modificar: CUALQUIER hotel del catálogo (asunto = acción + hotel + código)."""
from __future__ import annotations

import argparse
import datetime as dt
import email
import imaplib
import json
import re
import ssl
import sys
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from email.header import decode_header
from email.utils import parseaddr, parsedate_to_datetime
from pathlib import Path

from parse_corralco import looks_corralco, parse_corralco_confirmations
from parse_generic import parse_generic_confirmation
from parse_huilo import parse_huilo_confirmations, strip_html
from parse_lifecycle import is_internal_sender, parse_lifecycle_mail
from parse_puyehue import looks_puyehue, parse_puyehue_mail
from parse_ratehawk import looks_ratehawk, parse_ratehawk_confirmations

DIR = Path(__file__).resolve().parent


def load_env(path: Path) -> dict:
    env = {}
    if not path.exists():
        return env
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env


ENV = {**load_env(DIR / ".env")}


def env(key, default=""):
    import os

    return (os.environ.get(key) or ENV.get(key) or default).strip()


IMAP_HOST = env("IMAP_HOST", "127.0.0.1")
IMAP_PORT = int(env("IMAP_PORT", "143") or "143")
IMAP_USER = env("IMAP_USER", "reservas")
IMAP_PASS = env("IMAP_PASS")
MAILBOX = env("EMAIL_SYNC_MAILBOX", "INBOX")
SUPABASE_URL = env("SUPABASE_URL").rstrip("/")
SUPABASE_KEY = env("SUPABASE_SERVICE_ROLE_KEY") or env("SUPABASE_ANON_KEY")


def sb(method: str, path: str, body=None):
    url = f"{SUPABASE_URL}/rest/v1/{path}"
    data = None if body is None else json.dumps(body).encode("utf-8")
    prefer = (
        "return=representation,resolution=merge-duplicates"
        if method == "POST"
        else "return=representation"
    )
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "application/json",
            "Prefer": prefer,
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode("utf-8") or "null"
            return json.loads(raw)
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"Supabase {e.code}: {err[:500]}") from e


def decode_mime(val) -> str:
    if val is None:
        return ""
    if not isinstance(val, str):
        val = str(val)
    parts = []
    for chunk, enc in decode_header(val):
        if isinstance(chunk, bytes):
            parts.append(chunk.decode(enc or "utf-8", errors="replace"))
        else:
            parts.append(chunk)
    return "".join(parts)


def body_text(msg: email.message.Message) -> tuple[str, str]:
    text, html = "", ""
    if msg.is_multipart():
        for part in msg.walk():
            ctype = part.get_content_type()
            disp = str(part.get("Content-Disposition") or "")
            if "attachment" in disp.lower():
                continue
            payload = part.get_payload(decode=True) or b""
            charset = part.get_content_charset() or "utf-8"
            decoded = payload.decode(charset, errors="replace")
            if ctype == "text/plain" and not text:
                text = decoded
            elif ctype == "text/html" and not html:
                html = decoded
    else:
        payload = msg.get_payload(decode=True) or b""
        charset = msg.get_content_charset() or "utf-8"
        decoded = payload.decode(charset, errors="replace")
        if msg.get_content_type() == "text/html":
            html = decoded
        else:
            text = decoded
    if not text and html:
        text = strip_html(html)
    return text, html


def msg_date(msg):
    try:
        return parsedate_to_datetime(msg.get("Date")).date()
    except Exception:
        return None


def msg_datetime(msg):
    """Fecha+hora del mail con zona (UTC si el header no trae zona)."""
    try:
        d = parsedate_to_datetime(msg.get("Date"))
        if d.tzinfo is None:
            d = d.replace(tzinfo=dt.timezone.utc)
        return d
    except Exception:
        return None


def connect_imap():
    if IMAP_PORT == 993:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        client = imaplib.IMAP4_SSL(IMAP_HOST, IMAP_PORT, ssl_context=ctx)
    else:
        client = imaplib.IMAP4(IMAP_HOST, IMAP_PORT)
    client.login(IMAP_USER, IMAP_PASS)
    return client


# IDs canónicos (catálogo Checkin24hs). Evitan el bug histórico:
# query ilike fallida → data[0] → "Hotel Cabaña Del Lago Puerto Varas".
# IDs opcionales vía env (si el UUID está mal, _hotel_by_id falla y se usa ilike).
# No hardcodear Puyehue: un UUID inventado rompe el FK reservations_hotel_id_fkey.
HOTEL_IDS = {
    "corralco": env("HOTEL_ID_CORRALCO", "42f41707-866d-4afc-a2af-2a1012c6950c"),
    "puyehue": env("HOTEL_ID_PUYEHUE", ""),
    "aguas_calientes": env("HOTEL_ID_AGUAS_CALIENTES", ""),
    "huilo": env("HOTEL_ID_HUILO", ""),
}
FORBIDDEN_HOTEL_SUBSTR = (
    "cabaña del lago",
    "cabana del lago",
)


def _is_forbidden_hotel_name(name: str) -> bool:
    n = (name or "").lower()
    if any(s in n for s in FORBIDDEN_HOTEL_SUBSTR):
        return True
    if "puerto varas" in n and "puyehue" not in n and "corralco" not in n and "huilo" not in n:
        return True
    return False


def _fold_name(name: str) -> str:
    n = unicodedata.normalize("NFD", str(name or "").lower())
    return "".join(c for c in n if unicodedata.category(c) != "Mn")


def _hotel_name_ok(name: str, tokens: list[str]) -> bool:
    n = _fold_name(name)
    if not n or "pack" in n or _is_forbidden_hotel_name(name):
        return False
    return all(t in n for t in tokens)


def _hotel_by_id(hotel_id: str) -> dict | None:
    hid = (hotel_id or "").strip()
    if not hid:
        return None
    q = "hotels?select=id,name&id=eq." + urllib.parse.quote(hid, safe="") + "&limit=1"
    data = sb("GET", q)
    if isinstance(data, list) and data:
        row = data[0]
        name = row.get("name") or ""
        if _is_forbidden_hotel_name(name):
            return None
        return {"id": row.get("id"), "name": name}
    return None


_KNOWN_HOTELS = {
    "corralco": {
        "patterns": ["*corralco*"],
        "fallback": "Corralco",
        "tokens_list": [["corralco"]],
    },
    "puyehue": {
        "patterns": ["*puyehue*", "*termas*puyehue*"],
        "fallback": "Hotel Termas Puyehue Wellness & Spa Resort",
        "tokens_list": [["puyehue"], ["termas", "puyehue"]],
    },
    "aguas_calientes": {
        "patterns": ["*aguas*calientes*", "*aguas calientes*"],
        "fallback": "Cabañas Termas de Aguas Calientes",
        "tokens_list": [["aguas", "calientes"]],
    },
    "huilo": {
        "patterns": ["*huilo*"],
        "fallback": "Huilo Huilo",
        "tokens_list": [["huilo"]],
    },
}

_HOTEL_CATALOG: list[dict] | None = None


def hotel_catalog() -> list[dict]:
    global _HOTEL_CATALOG
    if _HOTEL_CATALOG is None:
        data = sb("GET", "hotels?select=id,name&limit=1000")
        _HOTEL_CATALOG = data if isinstance(data, list) else []
    return _HOTEL_CATALOG


def _tokens_from_key(key: str) -> list[str]:
    return [t for t in re.split(r"[_\s-]+", _fold_name(key)) if len(t) >= 3]


def _pretty_hotel_name(key: str) -> str:
    return " ".join(w.capitalize() for w in re.split(r"[_\s-]+", key) if w) or "Hotel (revisar)"


def _pick_hotel(candidates: list[dict], tokens_list: list[list[str]], fallback: str) -> dict | None:
    for tokens in tokens_list:
        scored = []
        for h in candidates:
            name = h.get("name") or ""
            if not _hotel_name_ok(name, tokens):
                continue
            folded = _fold_name(name)
            score = 1000 * sum(len(t) for t in tokens) - len(folded)
            scored.append((score, h))
        if scored:
            scored.sort(key=lambda x: x[0], reverse=True)
            best = scored[0][1]
            return {"id": best.get("id"), "name": best.get("name") or fallback}
    return None


def find_hotel(key: str = ""):
    """Resuelve cualquier hotel del catálogo. Nunca usa data[0] ni Cabaña Del Lago."""
    key = hotel_lookup_key(key)
    known = _KNOWN_HOTELS.get(key)
    if key == "unknown":
        return {"id": None, "name": "Hotel (revisar)"}

    if known:
        by_id = _hotel_by_id(HOTEL_IDS.get(key) or "")
        if by_id:
            return by_id
        patterns = known["patterns"]
        fallback = known["fallback"]
        tokens_list = known["tokens_list"]
        candidates: list[dict] = []
        seen_ids: set[str] = set()
        for pat in patterns:
            q = "hotels?select=id,name&name.ilike." + urllib.parse.quote(pat, safe="") + "&limit=20"
            data = sb("GET", q)
            if not isinstance(data, list):
                continue
            for h in data:
                hid = str(h.get("id") or "")
                if hid and hid in seen_ids:
                    continue
                if hid:
                    seen_ids.add(hid)
                candidates.append(h)
        picked = _pick_hotel(candidates, tokens_list, fallback)
        if picked:
            return picked
        print(f"⚠️ find_hotel({key}): sin match confiable en catálogo → fallback '{fallback}' (id=null)")
        return {"id": None, "name": fallback}

    tokens = _tokens_from_key(key)
    fallback = _pretty_hotel_name(key)
    if not tokens:
        return {"id": None, "name": fallback}
    picked = _pick_hotel(hotel_catalog(), [tokens], fallback)
    if picked:
        return picked
    print(f"⚠️ find_hotel({key}): sin match en catálogo → fallback '{fallback}' (id=null)")
    return {"id": None, "name": fallback}


def already_imported(message_id: str, retry_skipped: bool = False) -> bool:
    q = (
        "email_reservation_imports?select=id,status&message_id=eq."
        + urllib.parse.quote(message_id, safe="")
        + "&limit=1"
    )
    data = sb("GET", q)
    if not isinstance(data, list) or not data:
        return False
    if retry_skipped and (data[0].get("status") or "") == "skipped":
        return False
    return True


def mark_imported(row: dict):
    sb("POST", "email_reservation_imports?on_conflict=message_id", [row])


def find_reservation_by_natural_key(hotel_id: str, client_name: str, check_in: str) -> dict | None:
    """Busca reserva por clave natural: hotel+huésped+fecha (para casos sin código)."""
    if not hotel_id or not client_name or not check_in:
        return None
    
    # Normalizar nombre para búsqueda fuzzy
    name_normalized = re.sub(r"\s+", " ", str(client_name).strip().lower())[:50]
    
    q = (
        "reservations?select=id,reservation_code,status,check_in,check_out,total_amount,notes,updated_at,client_name"
        f"&hotel_id=eq.{urllib.parse.quote(str(hotel_id), safe='')}"
        f"&check_in=eq.{urllib.parse.quote(str(check_in), safe='')}"
        "&limit=10"
    )
    
    try:
        data = sb("GET", q)
        if not isinstance(data, list):
            return None
        
        # Buscar match por nombre (fuzzy)
        for row in data:
            row_name = re.sub(r"\s+", " ", str(row.get("client_name") or "").strip().lower())[:50]
            if row_name == name_normalized:
                return row
        
        return None
    except Exception:
        return None


def upsert_reservation(parsed, hotel, agent_name: str):
    hotel = dict(hotel or {})
    # Red de seguridad: nunca persistir Cabaña Del Lago / Puerto Varas fantasma
    if _is_forbidden_hotel_name(hotel.get("name") or ""):
        lookup = hotel_lookup_key(parsed.get("hotel_key") or "")
        print(
            f"⛔ Hotel prohibido '{hotel.get('name')}' en upsert "
            f"{parsed.get('reservation_code')} → re-resolviendo ({lookup})"
        )
        hotel = find_hotel(lookup)
    if _is_forbidden_hotel_name(hotel.get("name") or ""):
        # Sin UUID inventado: FK hotels exige id real o null
        hotel = {"id": None, "name": hotel.get("name") or "Hotel (revisar)"}
    
    new_code = parsed["reservation_code"]
    is_hotel_confirmation = parsed.get("is_hotel_confirmation", True)
    
    # Estado: pedido interno → "En gestión", confirmación del hotel → "Confirmada"
    # (solo para fuente genérica; parsers específicos siempre son "Confirmada")
    status = "Confirmada"
    if parsed.get("source") == "generic" and not is_hotel_confirmation:
        status = "En gestión"
    
    row = {
        "reservation_code": new_code,
        "client_name": parsed["client_name"],
        "client_email": parsed.get("client_email") or "",
        "client_phone": parsed.get("client_phone") or "",
        "hotel_id": hotel.get("id"),
        "hotel_name": hotel.get("name"),
        "check_in": parsed["check_in"],
        "check_out": parsed["check_out"],
        "reservation_date": dt.date.today().isoformat(),
        "agent_name": agent_name,
        "status": status,
        "total_amount": parsed.get("total_amount") or 0,
        "notes": parsed.get("notes"),
    }
    
    # Buscar si ya existe una reserva con este código o su número base
    existing = find_reservation_row(new_code)
    
    # Si no existe por código, buscar por clave natural (hotel+huésped+fecha)
    # para evitar duplicar cuando llega confirmación del hotel después del pedido interno
    if not existing and hotel.get("id"):
        existing = find_reservation_by_natural_key(
            hotel.get("id"),
            parsed["client_name"],
            parsed["check_in"]
        )
    
    if existing:
        existing_code = str(existing.get("reservation_code") or "")
        existing_status = str(existing.get("status") or "")
        existing_id = existing.get("id")
        existing_updated = existing.get("updated_at")
        
        # Protección: no degradar estados cerrados (Confirmada, Cancelada, etc)
        if existing_status in _CLOSED_STATUSES and status not in _CLOSED_STATUSES:
            print(f"   ⏭️  Skip actualización: reserva ya está en estado '{existing_status}'")
            return existing
        
        # Protección: si es una confirmación del hotel sobre una reserva "En gestión", actualizar a "Confirmada"
        should_upgrade = (
            existing_status == "En gestión" 
            and status == "Confirmada" 
            and is_hotel_confirmation
        )
        
        # Protección: el email debe ser más nuevo que updated_at
        if existing_updated:
            try:
                from datetime import datetime, timezone
                if isinstance(existing_updated, str):
                    existing_dt = datetime.fromisoformat(existing_updated.replace("Z", "+00:00"))
                else:
                    existing_dt = existing_updated
                
                msg_date = parsed.get("_msg_date")
                if msg_date:
                    msg_datetime = datetime.combine(msg_date, datetime.min.time())
                    msg_datetime = msg_datetime.replace(tzinfo=timezone.utc)
                    
                    if existing_dt.tzinfo is None:
                        existing_dt = existing_dt.replace(tzinfo=timezone.utc)
                    
                    if msg_datetime <= existing_dt and not should_upgrade:
                        print(f"   ⏭️  Skip: email no es más nuevo que la reserva existente")
                        return existing
            except (ValueError, AttributeError, TypeError):
                pass
        
        # Actualizar código si es diferente o si es upgrade a Confirmada
        if (existing_code != new_code or should_upgrade) and existing_id:
            if existing_code != new_code:
                print(f"   🔄 Actualizando código: '{existing_code}' → '{new_code}'")
            if should_upgrade:
                print(f"   ⬆️  Actualizando estado: '{existing_status}' → '{status}'")
            
            path = "reservations?id=eq." + urllib.parse.quote(str(existing_id), safe="")
            row["updated_at"] = dt.datetime.utcnow().isoformat() + "Z"
            try:
                return sb("PATCH", path, row)
            except RuntimeError as e:
                if "notes" in str(e).lower() or "column" in str(e).lower():
                    row.pop("notes", None)
                    return sb("PATCH", path, row)
                raise
    
    # Si no existe o el código es el mismo, hacer upsert normal
    try:
        return sb("POST", "reservations?on_conflict=reservation_code", [row])
    except RuntimeError as e:
        if "notes" in str(e).lower() or "column" in str(e).lower():
            row.pop("notes", None)
            return sb("POST", "reservations?on_conflict=reservation_code", [row])
        raise


def patch_reservation_agent(reservation_code: str, agent_name: str):
    if not reservation_code or not agent_name:
        return None
    q = (
        "reservations?reservation_code=eq."
        + urllib.parse.quote(str(reservation_code).strip(), safe="")
        + "&select=id,reservation_code,agent_name"
    )
    existing = sb("GET", q)
    if not isinstance(existing, list) or not existing:
        return None
    row_id = existing[0].get("id")
    if not row_id:
        return None
    path = "reservations?id=eq." + urllib.parse.quote(str(row_id), safe="")
    return sb(
        "PATCH",
        path,
        {"agent_name": agent_name, "updated_at": dt.datetime.utcnow().isoformat() + "Z"},
    )


_CLOSED_STATUSES = ("Confirmada", "Cancelada", "Modificada", "No show")


def _append_note(existing, line: str) -> str:
    prev = str(existing or "").strip()
    if line in prev:
        return prev
    return (prev + "\n" if prev else "") + line


def _extract_base_numbers(code: str) -> list[str]:
    """Extrae números base (9-10 dígitos) de un código de confirmación.
    
    Ejemplos:
        '602052775 / CI-261103-021' → ['602052775']
        '602052775' → ['602052775']
        '597391343 y 597391675' → ['597391343', '597391675']
    """
    if not code:
        return []
    nums = re.findall(r"\b\d{9,10}\b", str(code))
    return list(dict.fromkeys(nums))


def find_reservation_row(reservation_code: str):
    code = str(reservation_code or "").strip()
    if not code:
        return None
    # 1. Búsqueda exacta
    q = (
        "reservations?reservation_code=eq."
        + urllib.parse.quote(code, safe="")
        + "&select=id,reservation_code,status,check_in,check_out,total_amount,notes,updated_at,hotel_name,client_name,customer_name,adults,children"
        + "&limit=1"
    )
    existing = sb("GET", q)
    if isinstance(existing, list) and existing:
        return existing[0]
    
    # 2. Búsqueda por número base (para códigos Huilo con/sin CI)
    base_nums = _extract_base_numbers(code)
    for base_num in base_nums:
        q_base = (
            "reservations?reservation_code=ilike."
            + urllib.parse.quote("*" + base_num + "*", safe="*")
            + "&select=id,reservation_code,status,check_in,check_out,total_amount,notes,updated_at,hotel_name,client_name,customer_name,adults,children"
            + "&limit=5"
        )
        existing = sb("GET", q_base)
        if isinstance(existing, list) and existing:
            # Verificar que realmente contenga el número base
            for row in existing:
                row_code = str(row.get("reservation_code") or "")
                if base_num in row_code:
                    return row
    
    # 3. Búsqueda genérica (fallback)
    q2 = (
        "reservations?reservation_code=ilike."
        + urllib.parse.quote("*" + code + "*", safe="*")
        + "&select=id,reservation_code,status,check_in,check_out,total_amount,notes,updated_at,hotel_name,client_name,customer_name,adults,children"
        + "&limit=3"
    )
    existing = sb("GET", q2)
    if isinstance(existing, list) and existing:
        return existing[0]
    return None


_PENDING_STATUSES = ("Modificación pedida", "Anulación pedida", "En gestión")
_UNCLEAR_VERDICTS = ("unclear", "hotel_reply_unclear")
_REQUEST_MARGIN = dt.timedelta(minutes=10)
_PEDIDO_RX = re.compile(r"\[PEDIDO (anular|modificar) (\d{4}-\d{2}-\d{2}T[\d:.]+Z?)\]")
_FIELD_LABELS = {
    "check_in": "Check-in",
    "check_out": "Check-out",
    "adults": "Adultos",
    "children": "Niños",
    "total_amount": "Tarifa USD",
}


def _to_utc(value):
    """str ISO / datetime / date → datetime UTC (date = 00:00 UTC). None si no se puede."""
    if value is None or value == "":
        return None
    try:
        if isinstance(value, str):
            value = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
        if isinstance(value, dt.datetime):
            if value.tzinfo is None:
                value = value.replace(tzinfo=dt.timezone.utc)
            return value.astimezone(dt.timezone.utc)
        if isinstance(value, dt.date):
            return dt.datetime.combine(value, dt.time.min, tzinfo=dt.timezone.utc)
    except (ValueError, TypeError, AttributeError):
        return None
    return None


def request_time(row: dict, kind: str):
    """Momento del último pedido al hotel de este tipo ([PEDIDO … <iso>] en notas); si no hay, updated_at."""
    want = "anular" if kind == "cancel" else "modificar"
    stamps = [m.group(2) for m in _PEDIDO_RX.finditer(str(row.get("notes") or "")) if m.group(1) == want]
    for raw in reversed(stamps):
        t = _to_utc(raw)
        if t:
            return t
    return _to_utc(row.get("updated_at"))


def _reply_is_newer(row: dict, kind: str, msg_when) -> bool:
    """La respuesta cuenta si llegó después del pedido (con margen). Con fecha+hora se compara
    exacto (respuestas del mismo día sí cuentan); si solo hay fecha, se mantiene la regla vieja."""
    if not msg_when:
        return True
    if isinstance(msg_when, dt.datetime):
        req = request_time(row, kind)
        msg_utc = _to_utc(msg_when)
        if not req or not msg_utc:
            return True
        return msg_utc >= req - _REQUEST_MARGIN
    updated = _to_utc(row.get("updated_at"))
    msg_utc = _to_utc(msg_when)
    if not updated or not msg_utc:
        return True
    return msg_utc > updated


def _fmt_val(key, value):
    if value in (None, ""):
        return "—"
    if key == "total_amount":
        try:
            return f"{float(value):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
        except (TypeError, ValueError):
            return str(value)
    return str(value)[:10] if key in ("check_in", "check_out") else str(value)


def _same(key, old, new) -> bool:
    if key == "total_amount":
        try:
            return abs(float(old or 0) - float(new or 0)) < 0.01
        except (TypeError, ValueError):
            return False
    if key in ("check_in", "check_out"):
        return str(old or "")[:10] == str(new or "")[:10]
    try:
        return int(old or 0) == int(new or 0)
    except (TypeError, ValueError):
        return str(old) == str(new)


def modification_diff(row: dict, parsed: dict):
    """→ (updates, cambios[(campo, viejo, nuevo)], motivo_confuso|None). Solo campos afirmados por el hotel."""
    ch = parsed.get("changes")
    if ch is None:  # compatibilidad: parser viejo
        ch = {k: parsed.get(k) for k in ("check_in", "check_out", "total_amount") if parsed.get(k)}
    ch = dict(ch or {})
    if ch.get("ambiguous"):
        return {}, [], "no se entiende bien: " + ", ".join(ch["ambiguous"])
    if ch.get("nights") and not ch.get("check_in") and not ch.get("check_out") and row.get("check_in"):
        cin = dt.date.fromisoformat(str(row["check_in"])[:10])
        ch["check_out"] = (cin + dt.timedelta(days=int(ch["nights"]))).isoformat()
    if ch.get("total_pax") and "adults" not in ch and "children" not in ch:
        if int(row.get("children") or 0) == 0:
            ch["adults"] = ch["total_pax"]
        else:
            return {}, [], "dice cantidad total de personas sin separar adultos/niños"
    updates, changes = {}, []
    for key in ("check_in", "check_out", "adults", "children", "total_amount"):
        if ch.get(key) in (None, ""):
            continue
        new = ch[key]
        if key == "total_amount" and not (float(new) > 0):
            continue
        old = row.get(key)
        if _same(key, old, new):
            continue
        updates[key] = new
        changes.append((key, old, new))
    cin = updates.get("check_in") or row.get("check_in")
    cout = updates.get("check_out") or row.get("check_out")
    if cin and cout and str(cout)[:10] <= str(cin)[:10]:
        return {}, [], "las fechas resultantes no cierran (salida antes que entrada)"
    if not changes:
        return {}, [], "dice que la modificó pero no se ve qué cambió"
    return updates, changes, None


def patch_reservation_lifecycle(reservation_code: str, kind: str, parsed: dict | None = None, from_addr: str = "",
                                msg_date=None, message_id: str = "", send_alerts: bool = True):
    """Ventas pide; el hotel cierra solo si el cuerpo confirma de forma inequívoca."""
    parsed = parsed or {}
    codes = [c for c in ([reservation_code] + list(parsed.get("reservation_codes") or [])) if c]
    seen = []
    for c in codes:
        c = str(c).strip()
        if not c or c in seen:
            continue
        seen.append(c)
        row = find_reservation_row(c)
        if row:
            result = _apply_lifecycle_row(row, kind, parsed, from_addr, msg_date)
            if send_alerts and result.get("alert"):
                try:
                    result["alert_sent"] = send_lifecycle_alert(result["alert"], message_id)
                except Exception as e:  # nunca romper el sync por WhatsApp
                    result["alert_sent"] = {"ok": False, "error": str(e)[:200]}
            return result
    return {"ok": False, "reason": "no_existe"}


def _alert_base(row: dict, kind: str, parsed: dict, from_addr: str, msg_date) -> dict:
    return {
        "code": row.get("reservation_code") or "",
        "hotel": row.get("hotel_name") or parsed.get("hotel_key") or "Hotel",
        "guest": row.get("client_name") or row.get("customer_name") or "",
        "track": "Anulación" if kind == "cancel" else "Modificación",
        "check_in": str(row.get("check_in") or "")[:10],
        "from": from_addr,
        "when": msg_date,
        "excerpt": parsed.get("own_text") or "",
    }


def _apply_lifecycle_row(row: dict, kind: str, parsed: dict, from_addr: str, msg_date=None):
    rid = row.get("id")
    if not rid:
        return {"ok": False, "reason": "sin_id"}
    parsed = parsed or {}
    current = str(row.get("status") or "")
    closed = current in _CLOSED_STATUSES
    verdict = parsed.get("hotel_verdict") or "unclear"
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%MZ")
    internal = is_internal_sender(from_addr)

    # Check 1: Skip reservations with check_in in the past
    check_in_str = row.get("check_in")
    if check_in_str:
        try:
            if isinstance(check_in_str, str):
                check_in_date = dt.datetime.fromisoformat(check_in_str.replace("Z", "+00:00")).date()
            else:
                check_in_date = check_in_str
            if check_in_date < dt.date.today():
                return {"ok": True, "status": current, "reason": "check_in_pasado", "skip": True}
        except (ValueError, AttributeError):
            pass

    # Check 2: For internal senders, don't downgrade closed statuses
    if internal and closed:
        return {"ok": True, "status": current, "reason": "ya_cerrada", "skip": True}

    # Check 3: respuestas del hotel anteriores al pedido no cuentan (fecha+hora, margen de 10 min)
    if not internal and verdict in ("confirm_cancel", "confirm_modify", "reject") + _UNCLEAR_VERDICTS:
        if not _reply_is_newer(row, kind, msg_date):
            return {"ok": True, "status": current, "reason": "email_no_mas_nuevo", "skip": True}

    # Check 4: respuesta confusa → no se toca la reserva; si está pendiente, avisar por WhatsApp
    if verdict in _UNCLEAR_VERDICTS + ("ya_cerrada",):
        out = {"ok": True, "status": current, "reason": verdict, "skip": True}
        if not internal and verdict in _UNCLEAR_VERDICTS and current in _PENDING_STATUSES:
            out["alert"] = {**_alert_base(row, kind, parsed, from_addr, msg_date), "type": "confusa"}
        return out

    body = {}
    alert = None

    if internal:
        body["status"] = "Anulación pedida" if kind == "cancel" else "Modificación pedida"
    elif verdict == "confirm_cancel":
        if current == "Cancelada":
            return {"ok": True, "status": current, "reason": "ya_cerrada", "skip": True}
        body["status"] = "Cancelada"
        body["notes"] = _append_note(
            row.get("notes"), f"[HOTEL confirmó anulación — auto {stamp}] {current or '—'} → Cancelada"
        )
        alert = {**_alert_base(row, kind, parsed, from_addr, msg_date), "type": "aplicada",
                 "old_status": current, "new_status": "Cancelada", "changes": []}
    elif verdict == "confirm_modify":
        if current == "Modificada":
            return {"ok": True, "status": current, "reason": "ya_cerrada", "skip": True}
        updates, changes, confusing = modification_diff(row, parsed)
        if confusing:
            out = {"ok": True, "status": current, "reason": "modificacion_confusa", "skip": True, "detail": confusing}
            if current in _PENDING_STATUSES:
                out["alert"] = {**_alert_base(row, kind, parsed, from_addr, msg_date), "type": "confusa",
                                "detail": confusing}
            return out
        body.update(updates)
        body["status"] = "Modificada"
        detail = "; ".join(f"{k} {_fmt_val(k, o)}→{_fmt_val(k, n)}" for k, o, n in changes)
        ignored = (parsed.get("changes") or {}).get("ignored") or []
        if ignored:
            detail += " | ignorado: " + "; ".join(ignored)
        body["notes"] = _append_note(row.get("notes"), f"[HOTEL confirmó modificación — auto {stamp}] {detail}")
        alert = {**_alert_base(row, kind, parsed, from_addr, msg_date), "type": "aplicada",
                 "old_status": current, "new_status": "Modificada", "changes": changes, "ignored": ignored}
    elif verdict == "reject":
        if closed:
            return {"ok": True, "status": current, "reason": "ya_cerrada", "skip": True}
        if current == "En gestión":
            return {"ok": True, "status": current, "reason": "ya_cerrada", "skip": True}
        body["status"] = "En gestión"
        body["notes"] = _append_note(row.get("notes"), "[HOTEL no confirmó / no se puede — auto " + stamp + "]")
    else:
        return {"ok": True, "status": current, "reason": verdict, "skip": True}

    path = "reservations?id=eq." + urllib.parse.quote(str(rid), safe="")
    try:
        sb("PATCH", path, body)
    except RuntimeError as e:
        msg = str(e).lower()
        if "notes" in body and "notes" in msg:
            body.pop("notes", None)
            sb("PATCH", path, body)
        elif "updated_at" in msg:
            sb("PATCH", path, body)
        else:
            raise
    out = {"ok": True, "status": body.get("status"), "fields": list(body.keys()), "verdict": verdict}
    if alert:
        out["alert"] = alert
    return out


# ===== Avisos WhatsApp del ciclo anular/modificar =====

def _env_with_monitor_fallback(key: str) -> str:
    """Reusa la config del email-monitor (mismo grupo de avisos de reservas) si el .env del sync no la tiene."""
    val = env(key)
    if val:
        return val
    return (_MONITOR_ENV.get(key) or "").strip()


_MONITOR_ENV = load_env(DIR.parent.parent / "email-monitor" / ".env")


def _art_when(value) -> str:
    t = _to_utc(value)
    if not t:
        return "fecha n/d"
    if isinstance(value, dt.date) and not isinstance(value, dt.datetime):
        return value.strftime("%d/%m/%Y")
    try:
        from zoneinfo import ZoneInfo

        local = t.astimezone(ZoneInfo("America/Argentina/Buenos_Aires"))
    except Exception:
        local = t.astimezone(dt.timezone(dt.timedelta(hours=-3)))
    return local.strftime("%d/%m/%Y %H:%M") + " (hora ARG)"


def _excerpt(text: str, limit: int = 300) -> str:
    s = re.sub(r"\s+", " ", str(text or "")).strip().replace('"', "'")
    return s if len(s) <= limit else s[: limit - 1].rstrip() + "…"


def build_lifecycle_alert_text(alert: dict) -> str:
    who = alert.get("code") or ""
    if alert.get("guest"):
        who += f" · {alert['guest']}"
    cin = f" · Check-in {alert['check_in']}" if alert.get("check_in") else ""
    if alert.get("type") == "confusa":
        lines = [
            "⚠️ *El hotel respondió pero la respuesta es confusa*",
            f"🏨 {alert.get('hotel') or 'Hotel'}",
            f"🔖 {who}",
            f"📝 Pedido: {alert.get('track')}{cin}",
            f"📨 De: {alert.get('from') or 'n/d'} · {_art_when(alert.get('when'))}",
        ]
        if alert.get("detail"):
            lines.append(f"❓ {alert['detail']}")
        lines.append(f"💬 \"{_excerpt(alert.get('excerpt')) or '(sin texto propio)'}\"")
        lines.append("Revisá el mail y cerrá a mano desde el dashboard.")
        return "\n".join(lines)
    lines = [
        f"✅ *Hotel confirmó {alert.get('track', '').lower()} — aplicado en el dashboard*",
        f"🏨 {alert.get('hotel') or 'Hotel'}",
        f"🔖 {who}",
        f"📌 Estado: {alert.get('old_status') or '—'} → *{alert.get('new_status')}*",
    ]
    for key, old, new in alert.get("changes") or []:
        lines.append(f"• {_FIELD_LABELS.get(key, key)}: {_fmt_val(key, old)} → *{_fmt_val(key, new)}*")
    for item in alert.get("ignored") or []:
        lines.append(f"• No aplicado: {item}")
    lines.append(f"📨 De: {alert.get('from') or 'n/d'} · {_art_when(alert.get('when'))}")
    lines.append(f"💬 \"{_excerpt(alert.get('excerpt'), 200)}\"")
    lines.append("Revisalo; si algo no corresponde, corregilo desde el dashboard.")
    return "\n".join(lines)


def _alert_already_sent(kind: str, fingerprint: str) -> bool:
    q = (
        "ana_alerts_log?select=id&sent_ok=eq.true&kind=eq."
        + urllib.parse.quote(kind, safe="")
        + "&fingerprint=eq."
        + urllib.parse.quote(fingerprint, safe="")
        + "&limit=1"
    )
    data = sb("GET", q)
    return isinstance(data, list) and len(data) > 0


def _post_whatsapp(text: str) -> dict:
    api = _env_with_monitor_fallback("WHATSAPP_API_URL").rstrip("/")
    key = _env_with_monitor_fallback("WHATSAPP_API_KEY")
    dest = _env_with_monitor_fallback("LIFECYCLE_WHATSAPP_TO") or _env_with_monitor_fallback("WHATSAPP_GROUP_ID")
    if not api or not dest:
        return {"ok": False, "error": "falta WHATSAPP_API_URL / WHATSAPP_GROUP_ID"}
    req = urllib.request.Request(
        f"{api}/api/send",
        data=json.dumps({"number": dest, "text": text}).encode("utf-8"),
        method="POST",
        headers={"Content-Type": "application/json", "x-api-key": key},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8", errors="ignore") or "{}"
        try:
            data = json.loads(raw)
        except ValueError:
            data = {}
        ok = bool(data.get("success", True)) if isinstance(data, dict) else True
        return {"ok": ok, "error": None if ok else str(data.get("error") or "respuesta sin success")[:200]}
    except urllib.error.HTTPError as e:
        return {"ok": False, "error": f"WhatsApp {e.code}"}
    except Exception as e:
        return {"ok": False, "error": str(e)[:200]}


def send_lifecycle_alert(alert: dict, message_id: str) -> dict:
    """Un aviso por mail (message-id) y tipo; deja rastro en ana_alerts_log. Nunca lanza excepción."""
    if env("LIFECYCLE_WHATSAPP_ALERTS", "1") == "0":
        return {"ok": False, "skipped": True, "reason": "desactivado"}
    kind = "lifecycle_confusa" if alert.get("type") == "confusa" else "lifecycle_aplicada"
    fingerprint = f"{message_id or 'sin-id'}:{alert.get('code') or ''}"
    try:
        if _alert_already_sent(kind, fingerprint):
            return {"ok": True, "skipped": True, "reason": "ya_enviada"}
    except Exception:
        pass  # si no se puede consultar, preferimos avisar
    text = build_lifecycle_alert_text(alert)
    res = _post_whatsapp(text)
    try:
        sb(
            "POST",
            "ana_alerts_log?on_conflict=kind,fingerprint",
            [
                {
                    "kind": kind,
                    "fingerprint": fingerprint,
                    "channel": "whatsapp",
                    "payload": {"code": alert.get("code"), "type": alert.get("type"), "text": text[:1500]},
                    "sent_ok": bool(res.get("ok")),
                    "error": res.get("error"),
                }
            ],
        )
    except Exception as e:
        res["log_error"] = str(e)[:200]
    return res


def parse_reservation_mail(from_addr, subject, text, html, msg_dt):
    mail = {
        "from": from_addr,
        "subject": subject,
        "text": text,
        "html": html,
        "date": msg_dt,
    }
    if re.search(r"undeliverable|propuesta comercial|jahuel|delivery status", subject, re.I):
        return None, []
    
    # 1. Parsers de modificación/anulación (parse_lifecycle) - prioridad máxima
    life = parse_lifecycle_mail(mail)
    if life:
        return life.get("hotel_key") or "unknown", [life]
    
    blob = f"{from_addr} {subject} {text[:2000]} {(html or '')[:500]}".lower()
    
    # 2. Parsers específicos por hotel (con códigos propios, formatos únicos)
    if looks_ratehawk(from_addr, subject, text):
        rows = parse_ratehawk_confirmations(mail)
        if rows:
            return rows[0].get("hotel_key") or "ratehawk", rows
        return "ratehawk", []
    
    if looks_puyehue(from_addr, subject, f"{text}\n{html or ''}"):
        row = parse_puyehue_mail(mail)
        if row:
            return row.get("hotel_key") or "puyehue", [row]
        return "puyehue", []
    
    is_corralco = looks_corralco(from_addr, subject, f"{text}\n{html or ''}")
    is_huilo = "huilohuilo.com" in from_addr.lower() or "huilo" in subject.lower()
    
    if is_corralco and not is_huilo:
        rows = parse_corralco_confirmations(mail)
        return "corralco", rows
    
    if is_huilo:
        rows = parse_huilo_confirmations(mail)
        return "huilo", rows
    
    if "corralco" in blob:
        rows = parse_corralco_confirmations(mail)
        return "corralco", rows
    
    # 3. Parser genérico (fallback para cualquier hotel del catálogo)
    generic = parse_generic_confirmation(mail)
    if generic:
        # Agregar msg_date para protección de timestamps en upsert
        generic["_msg_date"] = msg_dt
        hotel_key = generic.get("hotel_key") or "unknown"
        return hotel_key, [generic]
    
    return None, []


def agent_for(hotel_key: str, parsed: dict | None = None, pending_agent: str = "") -> str:
    if pending_agent:
        return pending_agent
    if parsed and parsed.get("kind") == "agency":
        return parsed.get("agent_name") or ""
    is_web = bool((parsed or {}).get("is_web")) or str(hotel_key or "").endswith("_web")
    hk = (hotel_key or "").replace("_web", "")
    
    # Para parsers genéricos, usar nombre detectado si está disponible
    if parsed and parsed.get("source") == "generic":
        hotel_name_detected = parsed.get("hotel_name") or ""
        if hotel_name_detected and hotel_name_detected != "Hotel (revisar)":
            return f"Email {hotel_name_detected}"
    
    if is_web:
        if hk == "aguas_calientes":
            return "Ventas Web Aguas Calientes"
        if hk == "puyehue":
            return "Ventas Web Puyehue"
    if hk == "corralco":
        return "Email Corralco"
    if hk == "puyehue":
        return "Email Puyehue"
    if hk == "aguas_calientes":
        return "Email Aguas Calientes"
    if hk == "huilo":
        return "Email Huilo"
    if hk == "ratehawk" or "ratehawk" in hk:
        return "Email RateHawk"
    if hk and hk != "unknown":
        return "Email " + _pretty_hotel_name(hk)
    return "Email reservas"


def hotel_lookup_key(hotel_key: str) -> str:
    return (hotel_key or "").replace("_web", "").strip().lower() or "unknown"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--retry-skipped", action="store_true", help="Reprocesar mails marcados skipped (HTML/tabla)")
    ap.add_argument("--subject-contains", default="", help="Solo mails cuyo asunto contiene este texto")
    ap.add_argument("--since-days", type=int, default=int(env("EMAIL_SYNC_SINCE_DAYS", "60") or "60"))
    args = ap.parse_args()

    if not IMAP_PASS:
        print("Falta IMAP_PASS en .env", file=sys.stderr)
        sys.exit(1)
    if not args.dry_run and (not SUPABASE_URL or not SUPABASE_KEY):
        print("Falta SUPABASE_URL / clave en .env", file=sys.stderr)
        sys.exit(1)

    since = dt.date.today() - dt.timedelta(days=max(1, args.since_days))
    since_imap = since.strftime("%d-%b-%Y")
    print(f"📬 IMAP {IMAP_USER}@{IMAP_HOST}:{IMAP_PORT} mailbox={MAILBOX}")
    if str(IMAP_HOST).strip() in ("127.0.0.1", "localhost", "mail.checkin24hs.com"):
        print(
            "⚠️  El dashboard manda por smtp.hostinger.com. Si el hotel responde a reservas@, "
            "esta casilla local NO ve esa respuesta. En .env: IMAP_HOST=imap.hostinger.com "
            "IMAP_PORT=993 IMAP_USER=reservas@checkin24hs.com"
        )
    print(f"📅 SINCE {since_imap}{' (DRY-RUN)' if args.dry_run else ''}{' (retry skipped)' if args.retry_skipped else ''}")

    hotels: dict[str, dict] = {}

    def resolve_hotel(key: str) -> dict:
        lookup = hotel_lookup_key(key)
        if lookup not in hotels:
            if args.dry_run:
                hotels[lookup] = {"id": None, "name": _pretty_hotel_name(lookup)}
            else:
                hotels[lookup] = find_hotel(lookup)
        return hotels[lookup]

    if not args.dry_run:
        for hk in ("huilo", "corralco", "puyehue", "aguas_calientes"):
            resolve_hotel(hk)
    print(
        "🏨 Procesamiento:\n"
        "   · Anular/modificar: CUALQUIER hotel del catálogo (asunto = acción + nombre + código)\n"
        "   · Confirmaciones: Huilo, Corralco, Puyehue, Aguas Calientes, RateHawk (parsers específicos)\n"
        "                     + CUALQUIER hotel del catálogo (parser genérico, fallback)"
    )
    if not args.dry_run:
        for hk, h in hotels.items():
            print(f"   · {hk}: id={h.get('id') or 'NULL'} name={h.get('name')}")

    stats = {"scanned": 0, "parsed": 0, "imported": 0, "agents": 0, "skipped": 0, "errors": 0}
    pending_agents: dict[str, str] = {}
    client = connect_imap()
    try:
        typ, _ = client.select(MAILBOX, readonly=True)
        if typ != "OK":
            raise RuntimeError(f"No se pudo abrir {MAILBOX}: {typ}")
        typ, data = client.search(None, "SINCE", since_imap)
        ids = (data[0] or b"").split()
        print(f"🔍 Mensajes desde {since_imap}: {len(ids)}")
        for uid in ids:
            stats["scanned"] += 1
            typ, fetched = client.fetch(uid, "(RFC822)")
            if typ != "OK" or not fetched or not fetched[0]:
                stats["errors"] += 1
                continue
            raw = fetched[0][1]
            msg = email.message_from_bytes(raw)
            from_addr = parseaddr(msg.get("From") or "")[1]
            subject = decode_mime(msg.get("Subject"))
            message_id = (msg.get("Message-ID") or f"uid-{uid.decode()}").strip()
            text, html = body_text(msg)

            if args.subject_contains and args.subject_contains.lower() not in subject.lower():
                continue

            hotel_key, parsed_list = parse_reservation_mail(
                from_addr, subject, text, html, msg_date(msg)
            )
            if not hotel_key:
                continue

            is_life = bool(parsed_list) and parsed_list[0].get("kind") in ("cancel", "modify")
            if not args.dry_run and already_imported(message_id, args.retry_skipped):
                stats["skipped"] += 1
                continue

            if not parsed_list:
                print(f"⏭️  No parseable ({hotel_key}): {subject}")
                if not args.dry_run:
                    try:
                        mark_imported(
                            {
                                "message_id": message_id,
                                "reservation_code": None,
                                "hotel_key": hotel_key,
                                "subject": subject,
                                "from_addr": from_addr,
                                "status": "skipped",
                                "error_detail": "no_parse",
                            }
                        )
                    except Exception:
                        pass
                stats["skipped"] += 1
                continue

            stats["parsed"] += len(parsed_list)
            for parsed in parsed_list:
                kind = parsed.get("kind", "client")
                code = parsed.get("reservation_code", "")
                if kind in ("cancel", "modify"):
                    tag = "🚫" if kind == "cancel" else "✏️"
                    print(f"{tag} [{hotel_key}] {kind} {code} | {subject[:80]}")
                    if args.dry_run:
                        print(f"   · from={from_addr} verdict={parsed.get('hotel_verdict')}")
                        own = (parsed.get("own_text") or "").replace("\n", " ")[:220]
                        if own:
                            print(f"   · cuerpo: {own}")
                        if parsed.get("changes"):
                            print(f"   · cambios leídos: {parsed.get('changes')}")
                        continue
                    try:
                        result = patch_reservation_lifecycle(
                            code, kind, parsed, from_addr, msg_datetime(msg) or msg_date(msg), message_id=message_id
                        )
                        if result.get("ok"):
                            if result.get("skip"):
                                stats["skipped"] += 1
                                reason = result.get("reason") or ""
                                print(f"   ⏭️  skip {code} ({reason})")
                            if result.get("alert_sent") is not None:
                                sent = result["alert_sent"]
                                state = "ya enviado" if sent.get("skipped") else ("ok" if sent.get("ok") else f"falló: {sent.get('error')}")
                                print(f"   📲 aviso WhatsApp ({result['alert'].get('type')}): {state}")
                            else:
                                stats["imported"] += 1
                                extra = result.get("reason") or result.get("verdict") or ""
                                print(f"   → {result.get('status')} {code}" + (f" ({extra})" if extra else ""))
                        else:
                            print(f"   ⚠️ no se aplicó {code}: {result.get('reason')}")
                        mark_imported(
                            {
                                "message_id": message_id,
                                "reservation_code": code,
                                "hotel_key": hotel_key,
                                "subject": subject,
                                "from_addr": from_addr,
                                "status": "imported" if (result.get("ok") and not result.get("skip")) else "skipped",
                                "error_detail": (
                                    None
                                    if result.get("ok") and not result.get("skip")
                                    else (str(result.get("reason") or "") + (f": {result['detail']}" if result.get("detail") else "")
                                          + (" +aviso" if (result.get("alert_sent") or {}).get("ok") else ""))[:300]
                                ),
                            }
                        )
                    except Exception as e:
                        stats["errors"] += 1
                        print(f"❌ Error {kind} {code}: {e}")
                    continue
                if kind == "agency":
                    pending_agents[code] = parsed.get("agent_name") or ""
                    print(f"👤 [{hotel_key}] agente {code} → {pending_agents[code]}")
                    if args.dry_run:
                        continue
                    try:
                        if patch_reservation_agent(code, pending_agents[code]):
                            stats["agents"] += 1
                        mark_imported(
                            {
                                "message_id": message_id,
                                "reservation_code": code,
                                "hotel_key": hotel_key,
                                "subject": subject,
                                "from_addr": from_addr,
                                "status": "imported",
                            }
                        )
                    except Exception as e:
                        stats["errors"] += 1
                        print(f"❌ Error agente {code}: {e}")
                    continue

                agent_name = agent_for(hotel_key, parsed, pending_agents.get(code, ""))
                print(
                    f"✅ [{hotel_key}] {parsed['reservation_code']} | {parsed['client_name']} | "
                    f"{parsed['check_in']}→{parsed['check_out']} | {parsed.get('currency', 'USD')} "
                    f"{parsed['total_amount']} | {agent_name}"
                )
            if args.dry_run:
                continue
            lookup = hotel_lookup_key(hotel_key)
            hotel = resolve_hotel(lookup)
            try:
                for parsed in parsed_list:
                    if parsed.get("kind") in ("agency", "cancel", "modify"):
                        continue
                    code = parsed.get("reservation_code", "")
                    agent_name = agent_for(hotel_key, parsed, pending_agents.get(code, ""))
                    upsert_reservation(parsed, hotel, agent_name)
                    stats["imported"] += 1
                client_codes = [
                    p["reservation_code"]
                    for p in parsed_list
                    if p.get("kind") not in ("agency", "cancel", "modify")
                ]
                if client_codes:
                    mark_imported(
                        {
                            "message_id": message_id,
                            "reservation_code": " | ".join(client_codes),
                            "hotel_key": hotel_key,
                            "subject": subject,
                            "from_addr": from_addr,
                            "status": "imported",
                        }
                    )
            except Exception as e:
                stats["errors"] += 1
                first = next((p for p in parsed_list if p.get("kind") != "agency"), parsed_list[0])
                print(f"❌ Error importando {first.get('reservation_code')}: {e}")
    finally:
        try:
            client.logout()
        except Exception:
            pass

    print("———")
    print(
        f"Listo. scanned={stats['scanned']} parsed={stats['parsed']} "
        f"imported={stats['imported']} agents={stats['agents']} "
        f"skipped={stats['skipped']} errors={stats['errors']}"
    )


if __name__ == "__main__":
    main()
