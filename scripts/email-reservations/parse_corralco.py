"""Parser de confirmaciones Corralco en reservas@checkin24hs.com."""
from __future__ import annotations

import re
from typing import Optional

from parse_huilo import (
    MONTHS_ES,
    _fold,
    _ymd,
    field,
    html_to_text,
    parse_huilo_date,
    parse_passengers,
    strip_html,
)

_CODE_LABEL = (
    r"(?:N[uú]mero de (?:reserva|confirmaci[oó]n)|Localizador|"
    r"C[oó]digo(?: de reserva)?|Folio|Reserva\s*N[°ºo]?|Rsva\.?)"
)
_NAME_LABEL = r"(?:Nombre|Hu[eé]sped|Titular|Pasajero|Cliente|Guest)"
_CORRALCO_LABELS = (
    r"Nombre",
    r"Hu[eé]sped",
    r"Titular",
    r"Pasajero",
    r"Cliente",
    r"Guest",
    r"Localizador",
    r"Folio",
    r"Rsva\.?",
    r"N[uú]mero de (?:reserva|confirmaci[oó]n)",
    r"C[oó]digo(?: de reserva)?",
    r"Fecha de (?:llegada|salida|ingreso|egreso)",
    r"Check[\s-]?in",
    r"Check[\s-]?out",
    r"Ingreso",
    r"Salida",
    r"Llegada",
    r"Arrival",
    r"Departure",
    r"Tarifa",
    r"Total",
    r"Monto",
    r"Habitaci[oó]n",
)

_SKIP_SUBJECT = re.compile(
    r"undeliverable|propuesta comercial|jahuel|delivery status",
    re.I,
)


def looks_corralco(from_addr: str, subject: str, text: str) -> bool:
    blob = f"{from_addr} {subject} {text[:4000]}".lower()
    if "huilohuilo.com" in (from_addr or "").lower():
        return False
    if re.search(r"\bhuilo\b", subject or "", re.I) and "corralco" not in blob:
        return False
    if re.search(r"#\d{6,8}\b|rsva\.?\s*\d{6,8}", subject or "", re.I) and "corralco" in blob:
        return True
    return "corralco" in blob or bool(re.search(r"rsva\.?\s*\d{6,8}", subject or "", re.I))


def html_to_text_corralco(html: str) -> str:
    s = html_to_text(html)
    labels = "|".join(_CORRALCO_LABELS)
    s = re.sub(rf"(?im)(^|\n)\s*({labels})\s*\n\s*", r"\1\2: ", s)
    return s.strip()


def parse_corralco_date(raw, ref_date=None):
    if not raw:
        return None
    s = re.sub(r"\s+", " ", str(raw).strip())
    s = re.sub(r"\s+de\s+", "-", s, flags=re.I)
    d = parse_huilo_date(s, ref_date)
    if d:
        return d
    m = re.search(r"(\d{4})-(\d{2})-(\d{2})", str(raw))
    if m:
        return f"{m.group(1)}-{m.group(2)}-{m.group(3)}"
    m = re.search(r"(\d{1,2})\s+de\s+([a-záéíóú]+)(?:\s+de)?\s+(\d{2,4})", str(raw), re.I)
    if m:
        month = MONTHS_ES.get(_fold(m.group(2).lower()))
        year = int(m.group(3))
        if year < 100:
            year += 2000
        if month:
            return _ymd(int(m.group(1)), month, year)
    return parse_huilo_date(raw, ref_date)


def extract_code(text: str, subject: str = "") -> Optional[str]:
    blob = f"{subject}\n{text}"
    from_subject = re.findall(r"(?:#|Rsva\.?\s*)(\d{6,8})\b", subject or "", re.I)
    if not from_subject:
        from_subject = re.findall(r"Corralco\s*#\s*(\d{6,8})", subject or "", re.I)
    if from_subject:
        return " y ".join(dict.fromkeys(from_subject))
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
    for n in re.findall(r"(?:#|Rsva\.?\s*)(\d{6,8})\b", blob, re.I):
        nums.append(n)
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
        nombre = re.sub(r"^(Sr\.?|Sra\.?|Srta\.?|Don|Doña)\s+", "", nombre, flags=re.I)
        if 2 <= len(nombre) <= 80 and not re.match(r"^[\d|#]+$", nombre):
            return nombre
    s = re.sub(r"^(RE|RV|FW|Fwd)\s*:\s*", "", str(subject or "").strip(), flags=re.I)
    m = re.search(r"\b(Sr\.?|Sra\.?|Srta\.?)\s+(.+?)\s*[-–]\s*Rsva", s, re.I)
    if m:
        return re.sub(r"\s+", " ", m.group(2)).strip(" -–|")
    m = re.search(r"\|\s*(Sr\.?|Sra\.?|Srta\.?)\s+([^|#]+)", s, re.I)
    if m:
        name = re.sub(r"\s+", " ", m.group(2)).strip(" -–|")
        name = re.split(r"\s+-\s+Rsva", name, flags=re.I)[0].strip()
        if 2 <= len(name) <= 80:
            return name
    return None


def collect_dates(text: str, ref_date=None):
    found = []
    patterns = [
        r"\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}",
        r"\d{1,2}\s+de\s+[a-záéíóú]+(?:\s+de)?\s+\d{2,4}",
        r"\d{4}-\d{2}-\d{2}",
        r"\d{1,2}[-\s/]+[a-záéíóú]+[-\s/]+\d{2,4}",
    ]
    for pat in patterns:
        for m in re.finditer(pat, text or "", re.I):
            d = parse_corralco_date(m.group(0), ref_date)
            if d and d not in found:
                found.append(d)
    return found


def extract_dates(text: str, ref_date=None):
    check_in = check_out = None
    fechas = field(text, r"Fechas") or ""
    in_m = re.search(
        r"\b(?:In|Check[\s-]?in|Ingreso|Llegada|Entrada|Arrival|Fecha de (?:llegada|ingreso))\s*[:：]?\s*(.+?)(?=\s*(?:Out|Check[\s-]?out|Salida|Egreso|Departure|Fecha de (?:salida|egreso))\b|$)",
        fechas,
        re.I,
    )
    out_m = re.search(
        r"\b(?:Out|Check[\s-]?out|Salida|Egreso|Departure|Fecha de (?:salida|egreso))\s*[:：]?\s*(.+)$",
        fechas,
        re.I,
    )
    if in_m:
        check_in = parse_corralco_date(in_m.group(1), ref_date)
    if out_m:
        check_out = parse_corralco_date(out_m.group(1), ref_date)

    if not check_in:
        m = re.search(
            r"\b(?:Check[\s-]?in|Ingreso|Llegada|Entrada|Arrival|Fecha de (?:llegada|ingreso))\s*[:：]?\s*([^\n]+)",
            text,
            re.I,
        )
        check_in = parse_corralco_date(m.group(1) if m else None, ref_date)
    if not check_out:
        m = re.search(
            r"\b(?:Check[\s-]?out|Salida|Egreso|Departure|Fecha de (?:salida|egreso))\s*[:：]?\s*([^\n]+)",
            text,
            re.I,
        )
        check_out = parse_corralco_date(m.group(1) if m else None, ref_date)

    if not check_in or not check_out:
        m = re.search(
            r"\b(?:del|desde)\s+(.+?)\s+(?:al|hasta|a)\s+(.+?)(?:\.|,|\n|$)",
            text,
            re.I,
        )
        if m:
            check_in = check_in or parse_corralco_date(m.group(1), ref_date)
            check_out = check_out or parse_corralco_date(m.group(2), ref_date)

    if not check_in or not check_out:
        found = collect_dates(text, ref_date)
        if len(found) >= 2:
            check_in = check_in or found[0]
            check_out = check_out or found[1]
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
    if not nombre and code:
        nombre = f"Reserva Corralco {str(code).split()[0]}"
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
    if _SKIP_SUBJECT.search(subject):
        return []
    text = mail.get("text") or ""
    html = mail.get("html") or ""
    ref_date = mail.get("date")
    candidates = []
    if text.strip():
        candidates.append(text)
    if html.strip():
        candidates.append(html_to_text_corralco(html))
        candidates.append(strip_html(html))
    if not candidates:
        candidates.append("")
    for body in candidates:
        blob = f"{subject}\n{body}"
        if not looks_corralco(from_addr, subject, blob):
            continue
        if not re.search(
            r"confirmaci[oó]n|reserva|localizador|check[\s-]?in|ingreso|rsva|#\d{6}",
            blob,
            re.I,
        ):
            continue
        parsed = _from_body(body, subject, ref_date)
        if parsed:
            return [parsed]
    parsed = _from_body("", subject, mail.get("date"))
    if parsed:
        return [parsed]
    return []


def parse_corralco_confirmation(mail: dict):
    rows = parse_corralco_confirmations(mail)
    return rows[0] if rows else None
