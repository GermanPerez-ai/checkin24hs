"""Parser confirmaciones RateHawk (b2b@news.ratehawk.com, b2b@email.ratehawk.com)."""
from __future__ import annotations

import re
from typing import Optional

from parse_huilo import (
    field as field_colon,
    html_to_text,
    parse_huilo_date,
    strip_quoted_reply,
)

_SUBJECT_CONFIRM = re.compile(
    r"Confirmaci[oó]n de reserva referencia\s+(\d+)",
    re.I,
)
_SUBJECT_CANCEL = re.compile(
    r"Cancelaci[oó]n de reserva referencia\s+(\d+)",
    re.I,
)
_SUBJECT_MODIFY = re.compile(
    r"Modificaci[oó]n de reserva referencia\s+(\d+)",
    re.I,
)

_MARKETING_SKIP = re.compile(
    r"descuento|alquiler de coches|c[oó]digo promocional|oferta|promoci[oó]n",
    re.I,
)


def looks_ratehawk(from_addr: str, subject: str, text: str = "") -> bool:
    """Detecta emails transaccionales de RateHawk (no marketing)."""
    from_lower = (from_addr or "").lower()
    
    if not ("ratehawk.com" in from_lower or "b2b@" in from_lower):
        return False
    
    if _MARKETING_SKIP.search(subject or ""):
        return False
    
    if (_SUBJECT_CONFIRM.search(subject or "") or 
        _SUBJECT_CANCEL.search(subject or "") or
        _SUBJECT_MODIFY.search(subject or "")):
        return True
    
    blob = f"{subject} {text[:1000]}".lower()
    if "número de reserva" in blob and "ratehawk" in blob:
        return True
    
    return False


def _extract_code(subject: str, text: str) -> Optional[str]:
    """Extrae el código de reserva del asunto o cuerpo."""
    m = _SUBJECT_CONFIRM.search(subject or "")
    if m:
        return m.group(1)
    
    m = _SUBJECT_CANCEL.search(subject or "")
    if m:
        return m.group(1)
    
    m = _SUBJECT_MODIFY.search(subject or "")
    if m:
        return m.group(1)
    
    m = re.search(r"N[uú]mero de reserva\s*[:：]?\s*(\d{8,12})", text or "", re.I)
    if m:
        return m.group(1)
    
    return None


def _normalize_ratehawk_text(text: str) -> str:
    """Limpia caracteres de padding U+2800 y normaliza espacios."""
    s = str(text or "")
    s = s.replace("\u2800", "")
    s = re.sub(r"[ \t]+", " ", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def field(text: str, label: str) -> Optional[str]:
    """
    Extrae campo de RateHawk donde el valor está en la línea siguiente.
    Formato: Label\nValor o Label: Valor
    """
    m = re.search(
        r"(?:^|\n)\s*" + label + r"\s*[:：]?\s*\n\s*([^\n]+)",
        text,
        re.I | re.M,
    )
    if m:
        return m.group(1).strip()
    
    return field_colon(text, label)


def _body_text(mail: dict) -> str:
    """Extrae texto del mail, prioriza HTML convertido."""
    text = mail.get("text") or ""
    html = mail.get("html") or ""
    
    parts = []
    if html.strip():
        parts.append(strip_quoted_reply(html_to_text(html)))
    if text.strip():
        parts.append(strip_quoted_reply(text))
    
    return _normalize_ratehawk_text("\n".join(parts))


def _parse_money(raw: str) -> float:
    """Parsea montos con comas o puntos."""
    s = (raw or "").strip()
    s = re.sub(r"[^\d.,]", "", s)
    
    if "," in s and "." in s:
        s = s.replace(".", "").replace(",", ".")
    elif "," in s:
        s = s.replace(",", ".")
    
    try:
        return float(s)
    except ValueError:
        return 0.0


def _parse_amounts(text: str) -> tuple[float, float, str]:
    """
    Extrae total (PVP sale price), net, y currency.
    Returns (total_pvp, net_amount, currency).
    
    RateHawk comisión = 10% del precio de venta (PVP).
    Entonces: net = PVP * 0.90, o PVP = net / 0.90
    
    Busca primero el precio de venta/cliente explícito, luego calcula desde el neto.
    """
    currency = "USD"
    
    # Primero buscar precio de venta / cliente / PVP explícito
    sale_patterns = [
        r"Precio sin servicios adicionales\s*[:：]?\s*([^\n]+)",
        r"Precio de venta\s*[:：]?\s*([^\n]+)",
        r"Precio cliente\s*[:：]?\s*([^\n]+)",
        r"PVP\s*[:：]?\s*([^\n]+)",
        r"Total\s*[:：]?\s*US\$?\s*([\d.,]+)",
    ]
    
    for pattern in sale_patterns:
        m = re.search(pattern, text, re.I | re.M)
        if m:
            amount_text = m.group(1).strip()
            amount_match = re.search(r"([\d.,]+)", amount_text)
            if amount_match:
                sale_price = _parse_money(amount_match.group(1))
                if sale_price > 0:
                    # Calcular neto desde sale price (10% comisión del PVP)
                    net = round(sale_price * 0.90, 2)
                    return sale_price, net, currency
    
    # Si no hay precio de venta, extraer neto (Importe a pagar)
    net = 0.0
    m = re.search(r"Importe a pagar\s*[:：]?\s*([^\n]+)", text, re.I | re.M)
    if m:
        amount_text = m.group(1).strip()
        if "$" in amount_text or "USD" in amount_text.upper():
            amount_match = re.search(r"([\d.,]+)", amount_text)
            if amount_match:
                net = _parse_money(amount_match.group(1))
    
    if net == 0.0:
        m = re.search(r"([\d.,]+)\s*\$", text, re.I)
        if m:
            net = _parse_money(m.group(1))
    
    # Calcular PVP desde neto: net = PVP * 0.90, entonces PVP = net / 0.90
    if net > 0:
        sale_price = round(net / 0.90, 2)
        return sale_price, net, currency
    
    return 0.0, 0.0, currency


def _detect_forwarded(subject: str, text: str) -> tuple[str, str]:
    """Detecta y extrae contenido de forwards."""
    subj = subject
    body = text
    
    if re.match(r"^(Fwd|FW|RV):\s*", subject, re.I):
        subj_match = re.search(
            r"Confirmaci[oó]n de reserva referencia\s+\d+",
            text,
            re.I
        )
        if subj_match:
            subj = subj_match.group(0)
    
    return subj, body


def parse_ratehawk_mail(mail: dict) -> Optional[dict]:
    """Parsea un mail de confirmación, cancelación o modificación de RateHawk."""
    subject = str(mail.get("subject") or "")
    from_addr = str(mail.get("from") or "")
    
    if not looks_ratehawk(from_addr, subject):
        return None
    
    text = _body_text(mail)
    if not text:
        return None
    
    subject, text = _detect_forwarded(subject, text)
    
    ref_date = mail.get("date")
    
    reservation_code = _extract_code(subject, text)
    if not reservation_code:
        return None
    
    is_cancel = bool(_SUBJECT_CANCEL.search(subject))
    
    actual_hotel_name = field(text, r"Hotel") or ""
    if not actual_hotel_name:
        m = re.search(
            r"Reserva en\s+(.+?)\s+confirmada",
            text,
            re.I | re.DOTALL
        )
        if m:
            actual_hotel_name = m.group(1).strip()
    
    actual_hotel_name = actual_hotel_name.split("\n")[0].strip() if actual_hotel_name else ""
    
    # Extraer todos los huéspedes/pasajeros
    client_name_raw = (
        field(text, r"Nombre del hu[eé]sped") or
        field(text, r"Hu[eé]sped") or
        ""
    ).strip()
    
    # Buscar nombres adicionales después de "Nombre del huésped"
    guest_section = re.search(
        r"Nombre del hu[eé]sped\s*\n((?:[^\n]+\n?){1,5})",
        text,
        re.I
    )
    
    if guest_section:
        guest_text = guest_section.group(1)
        # Separar por líneas y buscar nombres en cada línea
        lines = [l.strip() for l in guest_text.split("\n") if l.strip()]
        names = []
        for line in lines:
            # Buscar patrón: Nombre Apellido (dos o más palabras capitalizadas)
            if re.match(r"^[A-Z][a-záéíóúñ]+(?:\s+[A-Z][a-záéíóúñ]+)+$", line):
                names.append(line)
            elif re.search(r"Check-in|Check-out|Habitaci[oó]n", line, re.I):
                # Si llegamos a otra sección, parar
                break
        
        if len(names) > 1:
            client_name = ", ".join(names)
        elif names:
            client_name = names[0]
        else:
            client_name = client_name_raw
    else:
        client_name = client_name_raw
    
    check_in_raw = field(text, r"Check-in")
    check_out_raw = field(text, r"Check-out")
    
    check_in = None
    check_out = None
    
    if check_in_raw:
        check_in = parse_huilo_date(check_in_raw, ref_date)
    
    if check_out_raw:
        check_out = parse_huilo_date(check_out_raw, ref_date)
    
    if not check_in or not check_out:
        return None
    
    # Extraer total (PVP sale price) y neto
    total_pvp, net_amount, currency = _parse_amounts(text)
    commission_amt = round(total_pvp - net_amount, 2) if total_pvp > 0 and net_amount > 0 else 0.0
    commission_pct = round((commission_amt / total_pvp * 100), 1) if total_pvp > 0 else 0.0
    
    invoice_number = field(text, r"N[uú]mero de factura") or ""
    due_date = field(text, r"Fecha de vencimiento") or ""
    if due_date:
        due_date = parse_huilo_date(due_date, ref_date) or due_date
    
    free_cancel = None
    cancel_match = re.search(
        r"Cancelaci[oó]n gratuita\s*\n?\s*antes del\s+([^\n,]+)",
        text,
        re.I
    )
    if cancel_match:
        free_cancel = parse_huilo_date(cancel_match.group(1).strip(), ref_date)
    
    provider_id = ""
    provider_match = re.search(r"\b(19\d{10,12})\b", text)
    if provider_match:
        provider_id = provider_match.group(1)
    
    notes_parts = [
        "Fuente: RateHawk",
        f"Hotel: {actual_hotel_name}" if actual_hotel_name else None,
        f"Neto: USD {net_amount:.2f}" if net_amount > 0 else None,
        f"Comisión: USD {commission_amt:.2f} ({commission_pct:.0f}%)" if commission_amt > 0 else None,
        f"Proveedor ID: {provider_id}" if provider_id else None,
        f"Factura: {invoice_number}" if invoice_number else None,
        f"Vencimiento: {due_date}" if due_date else None,
        f"Cancelación gratuita hasta: {free_cancel}" if free_cancel else None,
    ]
    notes = " | ".join(x for x in notes_parts if x)
    
    status = "Cancelada" if is_cancel else "Confirmada"
    
    return {
        "kind": "client",
        "hotel_key": "ratehawk",
        "reservation_code": reservation_code,
        "client_name": client_name,
        "client_email": "",
        "client_phone": "",
        "hotel_name": "RateHawk",
        "check_in": check_in,
        "check_out": check_out,
        "total_amount": total_pvp,
        "currency": currency,
        "status": status,
        "notes": notes,
    }


def parse_ratehawk_confirmations(mail: dict) -> list[dict]:
    """Retorna lista de confirmaciones (compatible con sync.py)."""
    row = parse_ratehawk_mail(mail)
    return [row] if row else []
