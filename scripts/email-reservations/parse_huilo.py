import re
import unicodedata

MONTHS_ES = {
    "enero": 1,
    "febrero": 2,
    "marzo": 3,
    "abril": 4,
    "mayo": 5,
    "junio": 6,
    "julio": 7,
    "agosto": 8,
    "septiembre": 9,
    "setiembre": 9,
    "octubre": 10,
    "noviembre": 11,
    "diciembre": 12,
}


def strip_html(html: str) -> str:
    s = str(html or "")
    s = re.sub(r"<br\s*/?>", "\n", s, flags=re.I)
    s = re.sub(r"</p>", "\n", s, flags=re.I)
    s = re.sub(r"</tr>", "\n", s, flags=re.I)
    s = re.sub(r"</div>", "\n", s, flags=re.I)
    s = re.sub(r"<[^>]+>", " ", s)
    s = s.replace("&nbsp;", " ").replace("&amp;", "&").replace("\r", "")
    s = re.sub(r"[ \t]+\n", "\n", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    s = re.sub(r"[ \t]{2,}", " ", s)
    return s.strip()


def _fold(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def parse_huilo_date(raw):
    if not raw:
        return None
    s = re.sub(r"\s+", " ", str(raw).strip().lower())
    m = re.match(r"^(\d{1,2})[-\s/]+([a-záéíóú]+)[-\s/]+(\d{2,4})$", s, re.I)
    if m:
        day = int(m.group(1))
        month = MONTHS_ES.get(_fold(m.group(2)))
        year = int(m.group(3))
        if year < 100:
            year += 2000
        if not month or not day:
            return None
        return f"{year:04d}-{month:02d}-{day:02d}"
    m = re.match(r"^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})$", s)
    if m:
        day, month, year = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if year < 100:
            year += 2000
        if month < 1 or month > 12 or day < 1 or day > 31:
            return None
        return f"{year:04d}-{month:02d}-{day:02d}"
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


def parse_huilo_confirmation(mail: dict):
    from_addr = str(mail.get("from") or "").lower()
    subject = str(mail.get("subject") or "")
    text = mail.get("text") or strip_html(mail.get("html") or "")

    looks = (
        "huilohuilo.com" in from_addr
        or re.search(r"huilo", subject, re.I)
        or re.search(r"Confirmaci[oó]n de reserva", text, re.I)
        or re.search(r"N[uú]mero de confirmaci[oó]n", text, re.I)
    )
    if not looks:
        return None
    if not re.search(r"confirmaci[oó]n", subject, re.I) and not re.search(
        r"Confirmaci[oó]n de reserva", text, re.I
    ):
        return None

    code = field(text, r"N[uú]mero de confirmaci[oó]n")
    if not code:
        m = re.search(r"N[uú]mero de confirmaci[oó]n\s*[:：]?\s*(\d{6,})", text, re.I)
        code = m.group(1) if m else None
    nombre = field(text, r"Nombre")
    if not code or not nombre:
        return None

    pasajeros_raw = field(text, r"Pasajeros") or ""
    adults, children = parse_passengers(pasajeros_raw)
    fechas_block = field(text, r"Fechas") or ""
    in_m = re.search(r"\bIn\s*[:：]?\s*(.+?)(?=\s*Out\b|$)", fechas_block, re.I)
    out_m = re.search(r"\bOut\s*[:：]?\s*(.+)$", fechas_block, re.I)
    in_line = re.search(r"\bIn\s*[:：]\s*([^\n]+)", text, re.I)
    out_line = re.search(r"\bOut\s*[:：]\s*([^\n]+)", text, re.I)
    check_in = parse_huilo_date(in_m.group(1) if in_m else None) or parse_huilo_date(
        in_line.group(1) if in_line else None
    )
    check_out = parse_huilo_date(out_m.group(1) if out_m else None) or parse_huilo_date(
        out_line.group(1) if out_line else None
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
