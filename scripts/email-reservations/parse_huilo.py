import datetime as dt
import html as html_lib
import re
import unicodedata

MONTHS_ES = {
    "enero": 1,
    "ene": 1,
    "febrero": 2,
    "feb": 2,
    "marzo": 3,
    "mar": 3,
    "abril": 4,
    "abr": 4,
    "mayo": 5,
    "may": 5,
    "junio": 6,
    "jun": 6,
    "julio": 7,
    "jul": 7,
    "agosto": 8,
    "ago": 8,
    "septiembre": 9,
    "setiembre": 9,
    "sep": 9,
    "set": 9,
    "octubre": 10,
    "oct": 10,
    "noviembre": 11,
    "nov": 11,
    "diciembre": 12,
    "dic": 12,
}

_LABELS = (
    r"Nombre",
    r"Alojamiento",
    r"N[uú]mero de confirmaci[oó]n",
    r"Pasajeros",
    r"Categor[ií]a de habitaci[oó]n",
    r"Tipo de habitaci[oó]n",
    r"Plan de alimentaci[oó]n",
    r"Traslados",
    r"Fechas",
    r"Tarifa final a pagar",
)


def html_to_text(html: str) -> str:
    """Tablas HTML de Huilo: <td>Label</td><td>valor</td> → Label: valor."""
    s = str(html or "")
    s = html_lib.unescape(s)
    s = s.replace("\xa0", " ").replace("\u200b", "")
    s = re.sub(r"(?i)<br\s*/?>", "\n", s)
    s = re.sub(r"(?i)</(p|div|tr|h[1-6]|li|table)>", "\n", s)
    s = re.sub(r"(?i)</t[dh]>\s*<t[dh][^>]*>", ": ", s)
    s = re.sub(r"(?i)</t[dh]>", "\n", s)
    s = re.sub(r"<[^>]+>", " ", s)
    s = s.replace("\r", "")
    s = re.sub(r"[ \t]+\n", "\n", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    s = re.sub(r"[ \t]{2,}", " ", s)
    labels = "|".join(_LABELS)
    s = re.sub(rf"(?im)(^|\n)\s*({labels})\s*\n\s*", r"\1\2: ", s)
    s = re.sub(r"(?im)(^|\n)\s*(In|Out)\s*\n\s*", r"\1\2: ", s)
    return s.strip()


def strip_html(html: str) -> str:
    return html_to_text(html)


def nombre_from_subject(subject: str):
    s = str(subject or "").strip()
    s = re.sub(r"^(RE|RV|FW|Fwd)\s*:\s*", "", s, flags=re.I)
    m = re.match(r"^Confirmaci[oó]n\s+(.+)$", s, re.I)
    if not m:
        return None
    name = m.group(1).strip()
    if re.search(r"fotograf|congreso|consulta|tarifas|fauna", name, re.I):
        return None
    return name or None


def _fold(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def _as_date(ref_date):
    if ref_date is None:
        return None
    if isinstance(ref_date, dt.datetime):
        return ref_date.date()
    if isinstance(ref_date, dt.date):
        return ref_date
    s = str(ref_date)[:10]
    try:
        return dt.date.fromisoformat(s)
    except ValueError:
        return None


def _ymd(day, month, year):
    try:
        return dt.date(year, month, day).isoformat()
    except ValueError:
        return None


def _year_for_md(day, month, ref):
    """Si el mail dice IN 16-07 (sin año), usar el año del mail; si ya pasó, el siguiente."""
    if ref is None:
        ref = dt.date.today()
    year = ref.year
    try:
        candidate = dt.date(year, month, min(day, 28))
    except ValueError:
        return year
    if candidate < ref - dt.timedelta(days=45):
        return year + 1
    return year


def parse_huilo_date(raw, ref_date=None):
    if not raw:
        return None
    s = re.sub(r"\s+", " ", str(raw).strip().lower())
    s = re.sub(r"\s*[-–]\s*$", "", s).strip()
    ref = _as_date(ref_date)

    m = re.search(r"(\d{1,2})[-\s/]+([a-záéíóú]+)[-\s/]+(\d{2,4})", s, re.I)
    if m:
        day = int(m.group(1))
        month = MONTHS_ES.get(_fold(m.group(2)))
        year = int(m.group(3))
        if year < 100:
            year += 2000
        if not month or not day:
            return None
        return _ymd(day, month, year)

    m = re.search(r"(\d{1,2})[-\s/]+([a-záéíóú]+)\b", s, re.I)
    if m:
        day = int(m.group(1))
        month = MONTHS_ES.get(_fold(m.group(2)))
        if month and day:
            return _ymd(day, month, _year_for_md(day, month, ref))

    m = re.search(r"(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})", s)
    if m:
        day, month, year = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if year < 100:
            year += 2000
        if month < 1 or month > 12 or day < 1 or day > 31:
            return None
        return _ymd(day, month, year)

    m = re.search(r"(\d{1,2})[/\-.](\d{1,2})\b", s)
    if m:
        day, month = int(m.group(1)), int(m.group(2))
        if 1 <= month <= 12 and 1 <= day <= 31:
            return _ymd(day, month, _year_for_md(day, month, ref))
    return None


def parse_passengers(raw):
    t = str(raw or "").lower()
    adults_m = re.search(r"(\d+)\s*adulto", t)
    child_m = re.search(r"\+\s*0?(\d+)\s*niñ", t)
    adults = int(adults_m.group(1)) if adults_m else 1
    children = int(child_m.group(1)) if child_m else 0
    return adults, children


def field(text, label):
    m = re.search(
        r"(?:^|\n)\s*" + label + r"\s*[:：]\s*(.+?)\s*(?=\n|$)",
        text,
        re.I | re.M,
    )
    return re.sub(r"\s+", " ", m.group(1)).strip() if m else None


def strip_quoted_reply(text: str) -> str:
    """No reparsear el hilo citado de Outlook (De: … Enviado el:)."""
    s = str(text or "")
    s = re.split(r"(?im)^De:\s+.+\nEnviado el:", s)[0]
    s = re.split(r"(?im)^From:\s+.+\nSent:", s)[0]
    s = re.split(r"(?im)^-{5,}Original Message-{5,}", s)[0]
    return s.strip()


def split_confirmation_blocks(text: str):
    starts = [
        m.start()
        for m in re.finditer(
            r"(?:^|\n)\s*(?:\d+\.-\s*)?Confirmaci[oó]n de reserva\b",
            text,
            re.I,
        )
    ]
    if not starts:
        return [text]
    blocks = []
    for i, start in enumerate(starts):
        end = starts[i + 1] if i + 1 < len(starts) else len(text)
        blocks.append(text[start:end].strip())
    return blocks


def _from_block(text: str, subject: str, ref_date=None):
    code = field(text, r"N[uú]mero de confirmaci[oó]n")
    if not code:
        m = re.search(r"N[uú]mero de confirmaci[oó]n\s*[:：]?\s*(.+)", text, re.I)
        code = m.group(1).strip() if m else None
    if code:
        nums = re.findall(r"\b\d{9}\b", code)
        if nums:
            code = " y ".join(dict.fromkeys(nums))
    if not code:
        nums = re.findall(r"\b\d{9}\b", text)
        if nums:
            code = " y ".join(dict.fromkeys(nums))
    nombre = field(text, r"Nombre") or nombre_from_subject(subject)
    if not code or not nombre:
        return None

    pasajeros_raw = field(text, r"Pasajeros") or ""
    adults, children = parse_passengers(pasajeros_raw)
    fechas_block = field(text, r"Fechas") or ""
    in_m = re.search(r"\bIn\s*[:：]?\s*(.+?)(?=\s*Out\b|$)", fechas_block, re.I)
    out_m = re.search(r"\bOut\s*[:：]?\s*(.+)$", fechas_block, re.I)
    in_line = re.search(r"\bIn\s*[:：]?\s*([^\n]+)", text, re.I)
    out_line = re.search(r"\bOut\s*[:：]?\s*([^\n]+)", text, re.I)
    check_in = parse_huilo_date(in_m.group(1) if in_m else None, ref_date) or parse_huilo_date(
        in_line.group(1) if in_line else None, ref_date
    )
    check_out = parse_huilo_date(out_m.group(1) if out_m else None, ref_date) or parse_huilo_date(
        out_line.group(1) if out_line else None, ref_date
    )

    tarifa_raw = field(text, r"Tarifa final a pagar") or ""
    if not tarifa_raw:
        m = re.search(r"Tarifa final a pagar\s*[:：]?\s*(.+)", text, re.I)
        tarifa_raw = m.group(1) if m else ""
    currency = "USD" if re.search(r"USD|US\$", tarifa_raw, re.I) else ("CLP" if re.search(r"CLP|\$", tarifa_raw) else "USD")
    amount_m = re.search(r"([\d]+(?:[.,]\d{2})?)", str(tarifa_raw).replace(".", ""))
    total_amount = float(amount_m.group(1).replace(",", ".")) if amount_m else 0.0

    if not check_in or not check_out:
        return None

    alojamiento = field(text, r"Alojamiento")
    room_category = field(text, r"Categor[ií]a de habitaci[oó]n")
    room_type = field(text, r"Tipo de habitaci[oó]n")
    meal_plan = field(text, r"Plan de alimentaci[oó]n")
    notes = " | ".join(
        x
        for x in [
            f"Alojamiento: {alojamiento}" if alojamiento else None,
            f"Habitación: {room_category}" if room_category else None,
            f"Tipo: {room_type}" if room_type else None,
            f"Plan: {meal_plan}" if meal_plan else None,
            f"Pasajeros: {pasajeros_raw}" if pasajeros_raw else None,
            f"Moneda: {currency}",
            "Origen: email Huilo (IMAP)",
        ]
        if x
    )
    return {
        "hotel_key": "huilo",
        "reservation_code": str(code).strip(),
        "client_name": nombre.strip(),
        "alojamiento": alojamiento,
        "room_category": room_category,
        "room_type": room_type,
        "meal_plan": meal_plan,
        "adults": adults,
        "children": children,
        "check_in": check_in,
        "check_out": check_out,
        "total_amount": total_amount,
        "currency": currency,
        "notes": notes,
    }


def _looks_confirmation(text: str, subject: str, from_addr: str) -> bool:
    looks = (
        "huilohuilo.com" in from_addr
        or re.search(r"huilo", subject, re.I)
        or re.search(r"Confirmaci[oó]n de reserva", text, re.I)
        or re.search(r"N[uú]mero de confirmaci[oó]n", text, re.I)
        or bool(nombre_from_subject(subject))
    )
    if not looks:
        return False
    if (
        not re.search(r"confirmaci[oó]n", subject, re.I)
        and not re.search(r"Confirmaci[oó]n de reserva", text, re.I)
        and not nombre_from_subject(subject)
    ):
        return False
    return True


def parse_huilo_confirmations(mail: dict):
    from_addr = str(mail.get("from") or "").lower()
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
        if not _looks_confirmation(body, subject, from_addr):
            continue
        found = []
        for block in split_confirmation_blocks(body):
            parsed = _from_block(block, subject, ref_date)
            if parsed:
                found.append(parsed)
        if found:
            return found
        parsed = _from_block(body, subject, ref_date)
        if parsed:
            return [parsed]
    return []


def parse_huilo_confirmation(mail: dict):
    rows = parse_huilo_confirmations(mail)
    return rows[0] if rows else None
