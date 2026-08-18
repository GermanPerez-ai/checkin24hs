"""Parser de confirmaciones Corralco en reservas@checkin24hs.com."""
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

_CODE_LABEL = (
    r"(?:N[uú]mero de (?:reserva|confirmaci[oó]n)|Localizador|"
    r"C[oó]digo(?: de reserva)?|Folio|Reserva\s*N[°ºo]?)"
)
_NAME_LABEL = r"(?:Nombre|Hu[eé]sped|Titular|Pasajero|Cliente)"


def looks_corralco(from_addr: str, subject: str, text: str) -> bool:
    blob = f"{from_addr} {subject} {text[:4000]}".lower()
    if "huilohuilo.com" in (from_addr or "").lower():
        return False
    if re.search(r"\bhuilo\b", subject or "", re.I) and "corralco" not in blob:
        return False
    return "corralco" in blob


def extract_code(text: str, subject: str = "") -> Optional[str]:
    blob = f"{subject}\n{text}"
    labeled = field(text, _CODE_LABEL)
    if not labeled:
        m = re.search(_CODE_LABEL + r"\s*[:：#]?\s*([A-Za-z0-9\-]{5,24})", blob, re.I)
        labeled = m.group(1).strip() if m else None
    if labeled:
        labeled = re.split(r"\s{2,}|\s+[-–]\s+", labeled)[0].strip()
        nums = re.findall(r"\b\d{6,12}\b", labeled)
        if nums:
            return " y ".join(dict.fromkeys(nums))
        token = re.sub(r"[^A-Za-z0-9\-]", "", labeled)
        if len(token) >= 5:
            return token.upper()
    nums = []
    for n in re.findall(r"\b\d{6,12}\b", blob):
        if n.startswith("54") and len(n) >= 10:
            continue
        if n in {"2024", "2025", "2026", "2027", "2028", "2029", "2030"}:
            continue
        nums.append(n)
    if nums:
        return " y ".join(dict.fromkeys(nums))
    m = re.search(r"\b(?:COR|CRC)[- ]?\d{4,}\b", blob, re.I)
    if m:
        return re.sub(r"\s+", "", m.group(0)).upper()
    return None


def extract_name(text: str, subject: str) -> Optional[str]:
    nombre = field(text, _NAME_LABEL)
    if nombre:
        nombre = re.split(r"\s{2,}|,", nombre)[0].strip()
        if 2 <= len(nombre) <= 80:
            return nombre
    s = re.sub(r"^(RE|RV|FW|Fwd)\s*:\s*", "", str(subject or "").strip(), flags=re.I)
    m = re.match(r"^Confirmaci[oó]n(?: de reserva)?(?:\s*[-–:]\s*|\s+)(.+)$", s, re.I)
    if m:
        name = re.sub(r"\bcorralco\b", "", m.group(1), flags=re.I).strip(" -–:")
        if name and not re.search(r"consulta|tarifas|fotograf", name, re.I):
            return name
    return None


def extract_dates(text: str, ref_date=None):
    check_in = check_out = None
    fechas = field(text, r"Fechas") or ""
    in_m = re.search(r"\b(?:In|Check[\s-]?in|Ingreso|Llegada|Entrada)\s*[:：]?\s*(.+?)(?=\s*(?:Out|Check[\s-]?out|Salida|Egreso)\b|$)", fechas, re.I)
    out_m = re.search(r"\b(?:Out|Check[\s-]?out|Salida|Egreso)\s*[:：]?\s*(.+)$", fechas, re.I)
    if in_m:
        check_in = parse_huilo_date(in_m.group(1), ref_date)
    if out_m:
        check_out = parse_huilo_date(out_m.group(1), ref_date)

    if not check_in:
        m = re.search(
            r"\b(?:Check[\s-]?in|Ingreso|Llegada|Entrada|In)\s*[:：]?\s*([^\n]+)",
            text,
            re.I,
        )
        check_in = parse_huilo_date(m.group(1) if m else None, ref_date)
    if not check_out:
        m = re.search(
            r"\b(?:Check[\s-]?out|Salida|Egreso|Out)\s*[:：]?\s*([^\n]+)",
            text,
            re.I,
        )
        check_out = parse_huilo_date(m.group(1) if m else None, ref_date)

    if not check_in or not check_out:
        m = re.search(
            r"\b(?:del|desde)\s+(\d{1,2}[/\-.](?:\d{1,2}|[a-záéíóú]+)[/\.-]?\d{0,4})\s+"
            r"(?:al|hasta|a)\s+(\d{1,2}[/\-.](?:\d{1,2}|[a-záéíóú]+)[/\.-]?\d{0,4})",
            text,
            re.I,
        )
        if m:
            check_in = check_in or parse_huilo_date(m.group(1), ref_date)
            check_out = check_out or parse_huilo_date(m.group(2), ref_date)
    return check_in, check_out


def extract_amount(text: str):
    tarifa_raw = (
        field(text, r"(?:Tarifa final a pagar|Tarifa|Total|Monto|Importe|Valor)")
        or ""
    )
    if not tarifa_raw:
        m = re.search(
            r"(?:Tarifa final a pagar|Tarifa|Total|Monto|Importe|Valor)\s*[:：]?\s*([^\n]+)",
            text,
            re.I,
        )
        tarifa_raw = m.group(1) if m else ""
    currency = "USD" if re.search(r"USD|US\$", tarifa_raw, re.I) else (
        "CLP" if re.search(r"CLP|\$", tarifa_raw) else "CLP"
    )
    amount_m = re.search(r"([\d]+(?:[.,]\d{2})?)", str(tarifa_raw).replace(".", ""))
    total_amount = float(amount_m.group(1).replace(",", ".")) if amount_m else 0.0
    return total_amount, currency, tarifa_raw


def _from_body(text: str, subject: str, ref_date=None):
    code = extract_code(text, subject)
    nombre = extract_name(text, subject)
    if not code or not nombre:
        return None
    check_in, check_out = extract_dates(text, ref_date)
    if not check_in or not check_out:
        return None
    total_amount, currency, tarifa_raw = extract_amount(text)
    pasajeros_raw = field(text, r"Pasajeros") or ""
    adults, children = parse_passengers(pasajeros_raw)
    habitacion = field(text, r"(?:Habitaci[oó]n|Categor[ií]a|Tipo de habitaci[oó]n)")
    plan = field(text, r"(?:Plan(?: de alimentaci[oó]n)?|R[eé]gimen)")
    notes = " | ".join(
        x
        for x in [
            f"Habitación: {habitacion}" if habitacion else None,
            f"Plan: {plan}" if plan else None,
            f"Pasajeros: {pasajeros_raw}" if pasajeros_raw else None,
            f"Moneda: {currency}",
            "Origen: email Corralco (IMAP)",
        ]
        if x
    )
    return {
        "hotel_key": "corralco",
        "reservation_code": str(code).strip(),
        "client_name": nombre.strip(),
        "adults": adults,
        "children": children,
        "check_in": check_in,
        "check_out": check_out,
        "total_amount": total_amount,
        "currency": currency,
        "notes": notes,
        "tarifa_raw": tarifa_raw,
    }


def parse_corralco_confirmations(mail: dict):
    from_addr = str(mail.get("from") or "")
    subject = str(mail.get("subject") or "")
    text = mail.get("text") or ""
    html = mail.get("html") or ""
    ref_date = mail.get("date")
    candidates = []
    if text.strip():
        candidates.append(strip_quoted_reply(text))
    if html.strip():
        candidates.append(strip_quoted_reply(html_to_text(html)))
    if not candidates:
        return []
    for body in candidates:
        if not looks_corralco(from_addr, subject, body):
            continue
        if not re.search(
            r"confirmaci[oó]n|reserva|localizador|check[\s-]?in|ingreso",
            f"{subject}\n{body}",
            re.I,
        ):
            continue
        parsed = _from_body(body, subject, ref_date)
        if parsed:
            return [parsed]
    return []


def parse_corralco_confirmation(mail: dict):
    rows = parse_corralco_confirmations(mail)
    return rows[0] if rows else None
