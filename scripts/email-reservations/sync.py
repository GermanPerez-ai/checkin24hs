#!/usr/bin/env python3
"""Sync IMAP (Dovecot LOGIN) → Supabase. Huilo, Corralco, Puyehue y Aguas Calientes."""
from __future__ import annotations

import argparse
import datetime as dt
import email
import imaplib
import json
import re
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
from email.header import decode_header
from email.utils import parseaddr, parsedate_to_datetime
from pathlib import Path

from parse_corralco import looks_corralco, parse_corralco_confirmations
from parse_huilo import parse_huilo_confirmations, strip_html
from parse_puyehue import looks_puyehue, parse_puyehue_mail

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


def find_hotel(key: str = "huilo"):
    key = (key or "huilo").lower().replace("_web", "")
    if key == "corralco":
        q = "hotels?select=id,name&name.ilike.*corralco*&limit=8"
        fallback = "Hotel Corralco Resort"
        token = "corralco"
    elif key == "puyehue":
        q = "hotels?select=id,name&name.ilike.*puyehue*&limit=8"
        fallback = "Hotel Termas de Puyehue"
        token = "puyehue"
    elif key == "aguas_calientes":
        q = "hotels?select=id,name&name.ilike.*aguas*calientes*&limit=8"
        fallback = "Cabañas Termas de Aguas Calientes"
        token = "aguas calientes"
    else:
        q = "hotels?select=id,name&or=(name.ilike.*huilo*,name.ilike.*Huilo*)&limit=5"
        fallback = "Huilo Huilo"
        token = "huilo"
    data = sb("GET", q)
    if not isinstance(data, list) or not data:
        return {"id": None, "name": fallback}
    preferred = next(
        (
            h
            for h in data
            if token in (h.get("name") or "").lower() and "pack" not in (h.get("name") or "").lower()
        ),
        data[0],
    )
    return {"id": preferred.get("id"), "name": preferred.get("name") or fallback}


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


def upsert_reservation(parsed, hotel, agent_name: str):
    row = {
        "reservation_code": parsed["reservation_code"],
        "client_name": parsed["client_name"],
        "client_email": parsed.get("client_email") or "",
        "client_phone": parsed.get("client_phone") or "",
        "hotel_id": hotel.get("id"),
        "hotel_name": hotel.get("name"),
        "check_in": parsed["check_in"],
        "check_out": parsed["check_out"],
        "reservation_date": dt.date.today().isoformat(),
        "agent_name": agent_name,
        "status": "Confirmada",
        "total_amount": parsed.get("total_amount") or 0,
        "notes": parsed.get("notes"),
    }
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


def parse_reservation_mail(from_addr, subject, text, html, msg_dt):
    mail = {
        "from": from_addr,
        "subject": subject,
        "text": text,
        "html": html,
        "date": msg_dt,
    }
    blob = f"{from_addr} {subject} {text[:2000]} {(html or '')[:500]}".lower()
    if re.search(r"undeliverable|propuesta comercial|jahuel|delivery status", subject, re.I):
        return None, []
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
    return None, []


def agent_for(hotel_key: str, parsed: dict | None = None, pending_agent: str = "") -> str:
    if pending_agent:
        return pending_agent
    if parsed and parsed.get("kind") == "agency":
        return parsed.get("agent_name") or ""
    is_web = bool((parsed or {}).get("is_web")) or str(hotel_key or "").endswith("_web")
    hk = (hotel_key or "").replace("_web", "")
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
    return "Email Huilo"


def hotel_lookup_key(hotel_key: str) -> str:
    return (hotel_key or "huilo").replace("_web", "")


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
    print(f"📅 SINCE {since_imap}{' (DRY-RUN)' if args.dry_run else ''}{' (retry skipped)' if args.retry_skipped else ''}")

    hotels = {
        "huilo": {"id": None, "name": "Huilo Huilo"},
        "corralco": {"id": None, "name": "Hotel Corralco Resort"},
        "puyehue": {"id": None, "name": "Hotel Termas de Puyehue"},
        "aguas_calientes": {"id": None, "name": "Cabañas Termas de Aguas Calientes"},
    }
    if not args.dry_run:
        for hk in list(hotels.keys()):
            hotels[hk] = find_hotel(hk)
    print(
        f"🏨 Huilo: {hotels['huilo']['name']} | Corralco: {hotels['corralco']['name']} | "
        f"Puyehue: {hotels['puyehue']['name']} | Aguas Cal.: {hotels['aguas_calientes']['name']}"
    )

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
            hotel = hotels.get(lookup) or hotels["huilo"]
            try:
                for parsed in parsed_list:
                    if parsed.get("kind") == "agency":
                        continue
                    code = parsed.get("reservation_code", "")
                    agent_name = agent_for(hotel_key, parsed, pending_agents.get(code, ""))
                    upsert_reservation(parsed, hotel, agent_name)
                    stats["imported"] += 1
                client_codes = [
                    p["reservation_code"] for p in parsed_list if p.get("kind") != "agency"
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
