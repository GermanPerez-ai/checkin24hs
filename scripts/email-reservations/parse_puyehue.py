"""Parser confirmaciones Puyehue / Termas Aguas Calientes (reservas@checkin24hs.com)."""
from __future__ import annotations

import re
from typing import Optional

from parse_huilo import (
    field,
    html_to_text,
    parse_huilo_date,
    parse_passengers,
    strip_quoted_reply,
)

_SUBJECT_PUYEHUE = re.compile(
    r"Confirmaci[oó]n de Reserva(?:\s+Web)?\s+Hotel Puyehue\s+([A-Z0-9]{4,10})\b",
    re.I,
)
_SUBJECT_AGUAS = re.compile(
    r"Confirmaci[oó]n de Reserva(?:\s+Web)?\s+Termas Aguas Calientes\s+([A-Z0-9]{4,10})\b",
    re.I,
)
_CODE_BODY = re.compile(
    r"c[oó]digo de reserva(?:\s+temporal)?\s+es\s+([A-Z0-9]{4,10})\b",
    re.I,
)
_SKIP = re.compile(r"undeliverable|delivery status|propuesta comercial", re.I)


def looks_puyehue(from_addr: str, subject: str, text: str = "") -> bool:
    blob = f"{subject} {text[:800]}".lower()
    if _SKIP.search(subject or ""):
        return False
    if _SUBJECT_PUYEHUE.search(subject or ""):
        return True
    if _SUBJECT_AGUAS.search(subject or ""):
        return True
    if "puyehue.cl" in (from_addr or "").lower():
        return True
    if "reservas puyehue" in blob:
        return True
    return bool(re.search(r"hotel termas de puyehue|termas aguas calientes", blob, re.I))


def _subject_meta(subject: str) -> Optional[dict]:
    subj = str(subject or "").strip()
    is_web = bool(re.search(r"\bReserva\s+Web\b", subj, re.I))
    m = _SUBJECT_PUYEHUE.search(subj)
    if m:
        return {
            "hotel_key": "puyehue_web" if is_web else "puyehue",
            "reservation_code": m.group(1).upper(),
            "is_web": is_web,
        }
    m = _SUBJECT_AGUAS.search(subj)
    if m:
        return {
            "hotel_key": "aguas_calientes_web" if is_web else "aguas_calientes",
            "reservation_code": m.group(1).upper(),
            "is_web": is_web,
        }
    return None


def _extract_code(subject: str, text: str) -> Optional[str]:
    meta = _subject_meta(subject)
    if meta:
        return meta["reservation_code"]
    m = _CODE_BODY.search(text or "")
    if m:
        return m.group(1).upper()
    m = re.search(r"\b([A-Z][A-Z0-9]{4,8})\b", subject or "")
    return m.group(1).upper() if m else None


def _parse_puyehue_date(raw, ref_date=None) -> Optional[str]:
    if not raw:
        return None
    s = re.sub(r"\s+", " ", str(raw).strip())
    s = re.sub(r"^(lun|mar|mi[eé]|jue|vie|s[aá]b|dom)\s*,?\s*", "", s, flags=re.I)
    s = s.replace(",", " ").strip()
    return parse_huilo_date(s, ref_date)


def _parse_money(raw: str) -> float:
    s = (raw or "").strip()
    if "," in s and "." in s:
        s = s.replace(".", "").replace(",", ".")
    elif "," in s:
        s = s.replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return 0.0


def _parse_amount_usd(text: str) -> tuple[float, str]:
    """Preferir TOTAL / Total neto (no Subtotal ni Cupón)."""
    patterns = (
        r"(?im)^\s*TOTAL\s*[:：]\s*US\$\s*([\d.,]+)",
        r"(?im)^\s*Total neto[^\n]*?US\$\s*([\d.,]+)",
        r"(?im)\bTOTAL\s*[:：]\s*US\$\s*([\d.,]+)",
    )
    for pat in patterns:
        m = re.search(pat, text or "")
        if m:
            return _parse_money(m.group(1)), "USD"
    # Último recurso: último US$ del cuerpo (suele ser el total)
    amounts = re.findall(r"US\$\s*([\d.,]+)", text or "", re.I)
    if amounts:
        return _parse_money(amounts[-1]), "USD"
    return 0.0, "USD"


_PUYEHUE_LABELS = (
    r"Hotel",
    r"Pasajeros",
    r"Check-?in",
    r"Check-?out",
    r"Noches",
    r"Programa",
    r"Habitaciones",
    r"Contacto",
    r"Pasajero",
    r"Agente",
    r"Agencia",
    r"Email",
    r"Correo",
    r"Tel[eé]fono",
    r"Direcci[oó]n",
    r"Ciudad",
    r"Pa[ií]s",
    r"Solicitudes especiales",
    r"Subtotal",
    r"TOTAL",
    r"Total neto[^\n:]*",
)


def _normalize_puyehue_text(text: str) -> str:
    """Une Label\\nValor → Label: Valor (mails HTML de Puyehue)."""
    s = str(text or "")
    labels = "|".join(_PUYEHUE_LABELS)
    s = re.sub(rf"(?im)(^|\n)\s*({labels})\s*\n\s*", r"\1\2: ", s)
    return s.strip()


def _body_text(mail: dict) -> str:
    text = mail.get("text") or ""
    html = mail.get("html") or ""
    parts = []
    if text.strip():
        parts.append(strip_quoted_reply(text))
    if html.strip():
        parts.append(strip_quoted_reply(html_to_text(html)))
    return _normalize_puyehue_text("\n".join(parts))


def _is_agency_mail(text: str) -> bool:
    """Mail de agencia: trae Agente + Agencia (el de cliente solo trae Contacto)."""
    has_agente = bool(field(text, r"Agente"))
    has_agencia = bool(field(text, r"Agencia"))
    return has_agente and has_agencia


def _parse_client(text: str, subject: str, meta: dict, ref_date=None) -> Optional[dict]:
    code = meta.get("reservation_code") or _extract_code(subject, text)
    if not code:
        return None

    name = (
        field(text, r"Contacto")
        or field(text, r"Pasajero")
        or field(text, r"Nombre")
    )
    email = field(text, r"Email") or field(text, r"Correo")
    phone = field(text, r"Tel[eé]fono") or field(text, r"Telefono")

    check_in = _parse_puyehue_date(field(text, r"Check-in") or field(text, r"Check in"), ref_date)
    check_out = _parse_puyehue_date(field(text, r"Check-out") or field(text, r"Check out"), ref_date)
    if not check_in or not check_out:
        return None

    pasajeros = field(text, r"Pasajeros") or ""
    adults, children = parse_passengers(pasajeros)
    total_amount, currency = _parse_amount_usd(text)
    programa = field(text, r"Programa")
    habitaciones = field(text, r"Habitaciones")
    noches = field(text, r"Noches")
    solicitudes = field(text, r"Solicitudes especiales")

    hotel_name = field(text, r"Hotel") or (
        "Cabañas Termas de Aguas Calientes"
        if "aguas" in meta.get("hotel_key", "")
        else "Hotel Termas de Puyehue"
    )

    notes_parts = [
        f"Hotel: {hotel_name}" if hotel_name else None,
        f"Programa: {programa}" if programa else None,
        f"Habitaciones: {habitaciones}" if habitaciones else None,
        f"Noches: {noches}" if noches else None,
        f"Pasajeros: {pasajeros}" if pasajeros else None,
        f"Solicitudes: {solicitudes}" if solicitudes else None,
        "Canal: Ventas Web" if meta.get("is_web") else "Canal: Agencia",
        "Origen: email Puyehue (IMAP)",
    ]
    notes = " | ".join(x for x in notes_parts if x)

    return {
        "kind": "client",
        "hotel_key": meta["hotel_key"],
        "is_web": meta.get("is_web", False),
        "reservation_code": code,
        "client_name": (name or "").strip(),
        "client_email": (email or "").strip(),
        "client_phone": (phone or "").strip(),
        "check_in": check_in,
        "check_out": check_out,
        "total_amount": total_amount,
        "currency": currency,
        "adults": adults,
        "children": children,
        "notes": notes,
    }


def _parse_agency(text: str, subject: str, meta: dict) -> Optional[dict]:
    code = meta.get("reservation_code") or _extract_code(subject, text)
    if not code:
        return None
    agent = field(text, r"Agente")
    agency = field(text, r"Agencia")
    if not agent:
        return None
    agent_display = agent.strip()
    if agency:
        agent_display = f"{agent_display} ({agency.strip()})"
    return {
        "kind": "agency",
        "hotel_key": meta["hotel_key"],
        "is_web": meta.get("is_web", False),
        "reservation_code": code,
        "agent_name": agent_display,
        "agency_name": (agency or "").strip(),
    }


def parse_puyehue_mail(mail: dict) -> Optional[dict]:
    """Un mail cliente (subir reserva) o agencia (solo agente)."""
    subject = str(mail.get("subject") or "")
    from_addr = str(mail.get("from") or "")
    if not looks_puyehue(from_addr, subject):
        return None
    meta = _subject_meta(subject)
    if not meta:
        return None
    text = _body_text(mail)
    if not text:
        return None
    ref_date = mail.get("date")
    if _is_agency_mail(text):
        return _parse_agency(text, subject, meta)
    return _parse_client(text, subject, meta, ref_date)


def parse_puyehue_confirmations(mail: dict) -> list[dict]:
    row = parse_puyehue_mail(mail)
    return [row] if row else []
