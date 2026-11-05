"""Parser genérico para confirmaciones, modificaciones y anulaciones de cualquier hotel del catálogo.

Este parser se usa como fallback cuando ningún parser específico (Huilo, Corralco, Puyehue, RateHawk) detecta el email.
Intenta extraer datos estructurados de emails de hoteles genéricos, priorizando señales claras de reserva real.
"""
from __future__ import annotations

import re
import unicodedata
from typing import Optional

from parse_huilo import (
    MONTHS_ES,
    html_to_text,
    parse_huilo_date,
    strip_quoted_reply,
)
from parse_lifecycle import (
    is_hotel_sender,
    is_internal_sender,
    own_reply_text,
)


# Palabras clave que indican confirmación/reserva real
_CONFIRMATION_SIGNALS = re.compile(
    r"\b("
    r"confirmaci[oó]n|confirmamos|confirmar|"
    r"reserva confirmada|reserva realizada|reserva exitosa|"
    r"nueva reserva|booking confirmed|confirmation|"
    r"n[uú]mero de reserva|c[oó]digo de reserva|"
    r"reservation number|booking number|booking code"
    r")\b",
    re.I,
)

# Señales de que NO es una reserva real
_SKIP_SIGNALS = re.compile(
    r"\b("
    r"undeliverable|delivery status|propuesta comercial|"
    r"newsletter|bolet[ií]n|marketing|promoci[oó]n|oferta especial|"
    r"descuento|cupón|cupon|feliz a[ñn]o|felices fiestas|"
    r"encuesta|survey|feedback|reseña|rese[ñn]a|review|"
    r"recordatorio de pago|payment reminder|factura pendiente|"
    r"mayr prevent|travel sale|jahuel"
    r")\b",
    re.I,
)

# Extracción de nombre del huésped
_GUEST_PATTERNS = [
    re.compile(r"(?:^|\n)\s*(?:Nombre|Name|Guest|Hu[eé]sped|Cliente|Client|Pasajero|Passenger)\s*[:：]\s*([^\n]{3,60})", re.I | re.M),
    re.compile(r"(?:^|\n)\s*(?:Reserva para|Reservation for|Booking for)\s*[:：]?\s*([^\n]{3,60})", re.I | re.M),
    # Saludos: "Estimado/a Juan Pérez", "Dear John Smith"
    re.compile(r"(?:^|\n)\s*(?:Estimad[oa]|Dear|Hola|Hello)\s+([A-ZÁÉÍÓÚ][a-záéíóúA-ZÁÉÍÓÚ\s]{2,50}?)\s*[,\n]", re.M),
    re.compile(r"(?:^|\n)\s*(?:Sr\.|Sra\.|Mr\.|Mrs\.|Ms\.)\s+([A-Z][^\n]{2,50})", re.M),
]

# Extracción de fechas (varios formatos)
_DATE_IN_PATTERNS = [
    re.compile(r"(?:Check[- ]?in|Entrada|Llegada|In|Arrival)\s*[:：]?\s*([^\n]{3,50})", re.I),
    re.compile(r"(?:Fecha de entrada|Fecha entrada|Date in)\s*[:：]?\s*([^\n]{3,50})", re.I),
]

_DATE_OUT_PATTERNS = [
    re.compile(r"(?:Check[- ]?out|Salida|Out|Departure)\s*[:：]?\s*([^\n]{3,50})", re.I),
    re.compile(r"(?:Fecha de salida|Fecha salida|Date out)\s*[:：]?\s*([^\n]{3,50})", re.I),
]

# Formato "5/11 por 2 noches" o "del 5/11 al 7/11"
_DATE_RANGE_NIGHTS = re.compile(
    r"(?:del?\s+)?(\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?)\s+(?:por|durante|x)\s+(\d+)\s+(?:noche|night)s?",
    re.I
)
_DATE_RANGE_TO = re.compile(
    r"(?:del?\s+)?(\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?)\s+(?:al|hasta|to|-|–)\s+(\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?)",
    re.I
)

# Formato "In 26/11/2026 Out 28/11/2026"
_IN_OUT_COMPACT = re.compile(
    r"\b(?:In|Entrada)\s+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\s+(?:Out|Salida)\s+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b",
    re.I
)

# Extracción de monto (precio total, no seña)
_AMOUNT_PATTERNS = [
    re.compile(r"(?:Precio|Price|Total|Amount|Monto total|Tarifa|Rate)\s*[:：]?\s*(?:USD?|US\$|CLP|\$)\s*([\d.,]+)", re.I),
    re.compile(r"(?:USD?|US\$)\s*([\d.,]+)(?:\s+(?:total|bruto|final))?", re.I),
    re.compile(r"(?:CLP|\$)\s*([\d.,]+)(?:\s+(?:total|bruto|final))?", re.I),
]

# Extracción de contacto
_EMAIL_PATTERN = re.compile(r"\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b")
_PHONE_PATTERN = re.compile(r"(?:Tel[eé]fono|Phone|M[oó]vil|Mobile|Celular|Cell)\s*[:：]?\s*([\d\s\+\-\(\)]{8,20})", re.I)

# Extracción de código de reserva
_CODE_PATTERNS = [
    re.compile(r"(?:C[oó]digo|Code|N[uú]mero|Number|Referencia|Reference)\s+(?:de\s+)?(?:reserva|booking|reservation)\s*[:：]?\s*([A-Z0-9][\w\-]{3,25})", re.I),
    re.compile(r"(?:Reserva|Booking|Confirmation)\s+(?:number|n[uú]mero|code|c[oó]digo)\s*[:：]?\s*([A-Z0-9][\w\-]{3,25})", re.I),
    re.compile(r"\b([A-Z]{2,4}-\d{4,6}-\d{2,4})\b"),  # Formato tipo CI-261103-021 o PAT-2611-001
    re.compile(r"\b(\d{8,12})\b"),  # Número largo
]


def _fold(s: str) -> str:
    """Normaliza texto para comparación insensible a acentos."""
    n = unicodedata.normalize("NFD", str(s or "").lower())
    return "".join(c for c in n if unicodedata.category(c) != "Mn")


def _clean_name(name: str) -> str:
    """Limpia nombre de huésped."""
    n = str(name or "").strip()
    n = re.sub(r"\s+", " ", n)
    n = re.sub(r"^[:\s,.-]+|[:\s,.-]+$", "", n)
    return n[:100]


def _parse_money(raw: str) -> float:
    """Parsea monto monetario flexible."""
    s = (raw or "").strip()
    if "," in s and "." in s:
        s = s.replace(".", "").replace(",", ".")
    elif "," in s:
        s = s.replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return 0.0


def _extract_guest_name(text: str, subject: str) -> Optional[str]:
    """Extrae nombre del huésped del cuerpo o asunto."""
    for rx in _GUEST_PATTERNS:
        m = rx.search(text)
        if m:
            name = _clean_name(m.group(1))
            if len(name) >= 3 and not re.search(r"^\d+$|^[:\s]+$", name):
                return name
    return None


def _extract_dates(text: str, ref_date=None) -> tuple[Optional[str], Optional[str]]:
    """Extrae check-in y check-out en múltiples formatos."""
    check_in = None
    check_out = None
    
    # Formato compacto "In 26/11/2026 Out 28/11/2026"
    m = _IN_OUT_COMPACT.search(text)
    if m:
        check_in = parse_huilo_date(m.group(1), ref_date)
        check_out = parse_huilo_date(m.group(2), ref_date)
        if check_in and check_out:
            return check_in, check_out
    
    # Formato "5/11 por 2 noches"
    m = _DATE_RANGE_NIGHTS.search(text)
    if m:
        check_in = parse_huilo_date(m.group(1), ref_date)
        if check_in:
            try:
                nights = int(m.group(2))
                from datetime import date, timedelta
                ci = date.fromisoformat(check_in)
                co = ci + timedelta(days=nights)
                check_out = co.isoformat()
                return check_in, check_out
            except (ValueError, TypeError):
                pass
    
    # Formato "del 5/11 al 7/11"
    m = _DATE_RANGE_TO.search(text)
    if m:
        check_in = parse_huilo_date(m.group(1), ref_date)
        check_out = parse_huilo_date(m.group(2), ref_date)
        if check_in and check_out:
            return check_in, check_out
    
    # Patrones separados de check-in y check-out
    for rx in _DATE_IN_PATTERNS:
        m = rx.search(text)
        if m:
            check_in = parse_huilo_date(m.group(1), ref_date)
            if check_in:
                break
    
    for rx in _DATE_OUT_PATTERNS:
        m = rx.search(text)
        if m:
            check_out = parse_huilo_date(m.group(1), ref_date)
            if check_out:
                break
    
    return check_in, check_out


def _extract_amount(text: str) -> tuple[float, str]:
    """Extrae monto total y moneda (prioriza USD, luego CLP)."""
    for rx in _AMOUNT_PATTERNS:
        m = rx.search(text)
        if m:
            amount = _parse_money(m.group(1))
            if amount > 0:
                currency = "USD" if "USD" in m.group(0) or "US$" in m.group(0) else "CLP"
                return amount, currency
    return 0.0, "USD"


def _extract_email(text: str) -> Optional[str]:
    """Extrae email del huésped (no el del remitente)."""
    emails = _EMAIL_PATTERN.findall(text)
    for email in emails:
        lower = email.lower()
        if "checkin24hs" not in lower and "ratehawk" not in lower:
            return email
    return None


def _extract_phone(text: str) -> Optional[str]:
    """Extrae teléfono del huésped."""
    m = _PHONE_PATTERN.search(text)
    return m.group(1).strip() if m else None


def _extract_code(text: str, subject: str) -> Optional[str]:
    """Extrae código de reserva (prioriza patrones con letras y guiones)."""
    # Primero buscar en texto, luego en subject
    for source in (text, subject):
        # Prioridad 1: Códigos con patrón específico (letras + guiones + números)
        for rx in _CODE_PATTERNS[:3]:  # Los primeros 3 son más específicos
            m = rx.search(source)
            if m:
                code = m.group(1).strip().upper()
                if len(code) >= 4:
                    return code
    
    # Prioridad 2: Números largos (solo si no hay código más específico)
    for source in (text, subject):
        m = _CODE_PATTERNS[3].search(source)  # Patrón de números
        if m:
            code = m.group(1).strip()
            # Excluir si parece teléfono (justo después de Teléfono:)
            if not re.search(rf"(?:Tel[eé]fono|Phone|M[oó]vil|Celular)\s*[:：]?\s*\+?\s*{code}", text, re.I):
                if len(code) >= 8:
                    return code
    
    return None


def _extract_hotel_name_from_sender(from_addr: str) -> Optional[str]:
    """Extrae nombre de hotel del remitente (ej: info@termashuife.cl → Termas Huife)."""
    addr = str(from_addr or "").lower().strip()
    if "@" not in addr:
        return None
    domain = addr.split("@")[-1].strip(">")
    # Extraer parte antes de .com/.cl/etc
    name_part = domain.split(".")[0]
    # Limpiar prefijos comunes
    name_part = re.sub(r"^(info|reservas|admin|administracion|administracion|contact|contacto|mail|email)", "", name_part)
    name_part = name_part.strip("-_")
    if len(name_part) >= 4:
        # Convertir "termashuife" → "Termas Huife"
        # Separar por patrones comunes (camelCase, palabras conocidas)
        name_pretty = name_part
        # Insertar espacios antes de mayúsculas en medio
        name_pretty = re.sub(r"([a-z])([A-Z])", r"\1 \2", name_pretty)
        # Reconocer palabras comunes (termas, hotel, resort, etc)
        name_pretty = re.sub(r"\b(termas|hotel|resort|cabanas|spa)", r"\1 ", name_pretty, flags=re.I)
        name_pretty = re.sub(r"\s+", " ", name_pretty).strip()
        # Capitalizar palabras
        name_pretty = " ".join(w.capitalize() for w in name_pretty.split())
        return name_pretty
    return None


def _extract_hotel_name_from_text(text: str, subject: str) -> Optional[str]:
    """Extrae nombre del hotel del texto/asunto."""
    # Patrones comunes - capturar frase completa incluyendo tipo
    patterns = [
        # "Nueva Reserva Termas de Huife - Checkin24hs"
        re.compile(r"(?:Nueva Reserva|Confirmación|Confirmation)\s+([A-ZÁÉÍÓÚa-záéíóú\s]{3,60}?)\s*(?:-|–|\||Checkin24hs)", re.I),
        # "Hotel Termas de Puyehue" o "Cabañas del Lago"
        re.compile(r"\b((?:Hotel|Termas|Resort|Cabañas|Caba[ñn]as)\s+[A-ZÁÉÍÓÚa-záéíóú\s]{3,50}?)(?:\s*\n|\s*$|\s*-|\s*\|)", re.I),
    ]
    
    for rx in patterns:
        m = rx.search(subject)
        if m:
            name = m.group(1).strip()
            if len(name) >= 4 and not re.search(r"^\d+$", name):
                return name
        m = rx.search(text[:500])
        if m:
            name = m.group(1).strip()
            if len(name) >= 4 and not re.search(r"^\d+$", name):
                return name
    
    return None


def looks_generic_confirmation(from_addr: str, subject: str, text: str) -> bool:
    """Detecta si parece una confirmación de hotel (no marketing/spam)."""
    # Descartar si es remitente interno
    if is_internal_sender(from_addr):
        return False
    
    # Descartar señales de skip (marketing, bounce, etc)
    blob = f"{subject} {text[:1000]}"
    if _SKIP_SIGNALS.search(blob):
        return False
    
    # Debe tener señales de confirmación Y ser remitente de hotel
    has_confirmation = bool(_CONFIRMATION_SIGNALS.search(blob))
    has_hotel_sender = is_hotel_sender(from_addr) or "@" in from_addr
    
    if not (has_confirmation and has_hotel_sender):
        return False
    
    # Debe tener al menos fechas o código de reserva para ser considerado válido
    has_dates = bool(re.search(r"(?:check[- ]?in|entrada|llegada|in|arrival)", blob, re.I))
    has_code = bool(re.search(r"(?:c[oó]digo|code|n[uú]mero|number|referencia)", blob, re.I))
    
    return has_dates or has_code


def parse_generic_confirmation(mail: dict) -> Optional[dict]:
    """
    Parsea confirmación genérica de hotel del catálogo.
    
    Retorna dict con:
    - kind: 'client' (siempre, para confirmaciones)
    - hotel_key: nombre clave del hotel (para lookup en catálogo)
    - hotel_name: nombre legible del hotel detectado
    - reservation_code: código de reserva (o generado si no hay)
    - client_name: nombre del huésped
    - check_in/check_out: fechas ISO
    - total_amount: monto total (no seña)
    - currency: USD/CLP
    - client_email/client_phone: contacto del huésped
    - notes: información adicional
    - source: 'generic' (para distinguir en logs)
    - is_hotel_confirmation: True si viene del hotel, False si es pedido interno
    """
    from_addr = str(mail.get("from") or "")
    subject = str(mail.get("subject") or "")
    text_raw = str(mail.get("text") or "")
    html_raw = str(mail.get("html") or "")
    ref_date = mail.get("date")
    
    # Preparar texto limpio
    text = strip_quoted_reply(text_raw)
    if html_raw:
        html_clean = strip_quoted_reply(html_to_text(html_raw))
        text = f"{text}\n{html_clean}"
    
    if not looks_generic_confirmation(from_addr, subject, text):
        return None
    
    # Detectar si es confirmación del hotel o pedido interno
    is_hotel_confirmation = not is_internal_sender(from_addr)
    
    # Extraer datos básicos
    guest_name = _extract_guest_name(text, subject)
    if not guest_name:
        return None
    
    check_in, check_out = _extract_dates(text, ref_date)
    if not check_in or not check_out:
        return None
    
    # Código de reserva (opcional para pedidos internos)
    code = _extract_code(text, subject)
    if not code:
        # Generar código temporal si no hay (formato: GUEST-YYMMDD)
        import datetime as dt
        today = dt.date.today()
        guest_prefix = "".join(c for c in guest_name[:4].upper() if c.isalnum())
        code = f"{guest_prefix}-{today.strftime('%y%m%d')}"
    
    # Monto y moneda
    total_amount, currency = _extract_amount(text)
    
    # Contacto del huésped
    client_email = _extract_email(text)
    client_phone = _extract_phone(text)
    
    # Identificar hotel
    hotel_name_detected = _extract_hotel_name_from_text(text, subject)
    if not hotel_name_detected:
        hotel_name_detected = _extract_hotel_name_from_sender(from_addr)
    
    if not hotel_name_detected:
        hotel_name_detected = "Hotel (revisar)"
    
    # Crear clave de hotel para lookup en catálogo
    hotel_key = re.sub(r"[^a-z0-9]+", "_", _fold(hotel_name_detected)).strip("_")
    
    # Notas
    notes_parts = [
        f"Hotel detectado: {hotel_name_detected}",
        f"Moneda: {currency}",
        f"Fuente: {'Confirmación del hotel' if is_hotel_confirmation else 'Pedido interno'}",
        f"Origen: email genérico (IMAP)",
    ]
    notes = " | ".join(notes_parts)
    
    return {
        "kind": "client",
        "hotel_key": hotel_key,
        "hotel_name": hotel_name_detected,
        "reservation_code": code,
        "client_name": guest_name,
        "client_email": client_email or "",
        "client_phone": client_phone or "",
        "check_in": check_in,
        "check_out": check_out,
        "total_amount": total_amount,
        "currency": currency,
        "notes": notes,
        "source": "generic",
        "is_hotel_confirmation": is_hotel_confirmation,
    }
