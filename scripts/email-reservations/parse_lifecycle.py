"""Mails de anular / modificar reserva — cualquier hotel del catálogo."""
from __future__ import annotations

import html as html_lib
import re
import unicodedata
from typing import Optional

_CANCEL = re.compile(
    r"\b(anular|anulaci[oó]n|anulad[aos]?|cancelaci[oó]n|cancelar|cancelad[aos]?)\b",
    re.I,
)
_MODIFY = re.compile(
    r"\b(modificar|modificaci[oó]n|modificad[aos]?|ajuste de precio)\b",
    re.I,
)
_SKIP = re.compile(
    r"undeliverable|delivery status|propuesta comercial|mayr prevent|travel sale",
    re.I,
)
_CODE_LABELED = re.compile(
    r"(?:c[oó]digo|codigo|code)\s*[:\s]+\s*([A-Z][A-Z0-9]{4,9}|\d{6,10})\b",
    re.I,
)
_CODE_HOTEL = re.compile(
    r"(?:Hotel Puyehue|Aguas Calientes|Puyehue)\s+([A-Z][A-Z0-9]{4,7})\b",
    re.I,
)
_CODE_HASH = re.compile(r"#\s*(\d{5,10})\b")
_CODE_CORRALCO = re.compile(r"Corralco\s*#?\s*(\d{6,8})", re.I)
_CODE_HUILO = re.compile(r"\b(\d{9,10})\b")
_CODE_PAREN = re.compile(r"\((\d{5,8})\)")
_CODE_ALNUM = re.compile(r"\b([A-Z][A-Z0-9]{4,9})\b")
_CODE_DIGITS = re.compile(r"\b(\d{6,10})\b")
_FORMULA = re.compile(
    r"^(?:re:\s*|fwd:\s*|fw:\s*|rv:\s*|res:\s*)*"
    r"(?:anular|anulaci[oó]n|cancelaci[oó]n|cancelar|modificar|modificaci[oó]n|ajuste de precio)"
    r".{0,20}?"
    r"reserva(?:s)?"
    r"(?:\s+web)?"
    r"\s+(.+?)\s+"
    r"([A-Z][A-Z0-9]{4,9}|#\s*\d{5,10}|\d{6,10})"
    r"(?:\s+y\s+[A-Z0-9#]+)*"
    r"\s*$",
    re.I,
)

_ALIASES = (
    ("puyehue", "puyehue"),
    ("aguas calientes", "aguas_calientes"),
    ("aguas", "aguas_calientes"),
    ("corralco", "corralco"),
    ("huilo", "huilo"),
)

_NOISE = {
    "re",
    "fwd",
    "fw",
    "anular",
    "anulacion",
    "anulada",
    "anulado",
    "anulados",
    "cancelacion",
    "cancelar",
    "cancelada",
    "cancelado",
    "modificar",
    "modificacion",
    "modificada",
    "modificado",
    "ajuste",
    "precio",
    "confirmacion",
    "confirm",
    "reserva",
    "reservas",
    "codigo",
    "code",
    "web",
    "hotel",
    "hotels",
    "termas",
    "cabana",
    "cabanas",
    "nombre",
    "temporal",
    "corte",
    "ruta",
    "cambio",
    "fecha",
    "fechas",
    "noches",
    "pax",
}


def lifecycle_intent(subject: str) -> Optional[str]:
    subj = str(subject or "")
    if _SKIP.search(subj):
        return None
    if _CANCEL.search(subj):
        return "cancel"
    if _MODIFY.search(subj):
        return "modify"
    return None


_BLOCK_CODES = {
    "RESERVA",
    "RESERVAS",
    "HOTEL",
    "HOTELS",
    "TERMAS",
    "CONFIRM",
    "CONFIRMACION",
    "ANULAR",
    "ANULACION",
    "CANCELAR",
    "CANCELACION",
    "MODIFICAR",
    "MODIFICACION",
    "PUYEHUE",
    "CORRALCO",
    "HUILO",
    "CALIENTES",
    "AGUAS",
    "FWD",
    "AJUSTE",
    "PRECIO",
    "NOMBRE",
    "ABRIL",
}


def _fold(s: str) -> str:
    n = unicodedata.normalize("NFD", str(s or "").lower())
    return "".join(c for c in n if unicodedata.category(c) != "Mn")


def _clean_code(raw: str) -> Optional[str]:
    code = re.sub(r"^#\s*", "", str(raw or "").strip()).upper()
    if not code or code in _BLOCK_CODES:
        return None
    if re.fullmatch(r"20\d{2}", code):
        return None
    return code


def _alias_in(text: str) -> Optional[str]:
    blob = _fold(text)
    for needle, key in _ALIASES:
        if needle in blob:
            return key
    return None


def _formula_parts(subject: str) -> Optional[tuple[str, str]]:
    m = _FORMULA.search(str(subject or "").strip())
    if not m:
        return None
    hotel_part, raw_code = m.group(1), m.group(2)
    if re.search(r"\bnombre\b|\(\d", hotel_part, re.I):
        return None
    code = _clean_code(raw_code)
    if not code:
        return None
    return hotel_part, code


def slug_hotel_name(phrase: str) -> str:
    words = []
    for w in re.split(r"[^a-z0-9]+", _fold(phrase)):
        if len(w) >= 3 and w not in _NOISE:
            words.append(w)
    return "_".join(words[:6])


def hotel_key_from_lifecycle(subject: str, text: str = "") -> str:
    subj = str(subject or "")
    known = _alias_in(subj)
    if known:
        return known
    formula = _formula_parts(subj)
    if formula:
        slug = slug_hotel_name(formula[0])
        if slug:
            return slug
        known_body = _alias_in(f"{subj} {str(text or '')[:400]}")
        return known_body or "unknown"
    slug = slug_hotel_name(subj)
    if slug:
        return slug
    known_body = _alias_in(f"{subj} {str(text or '')[:400]}")
    if known_body:
        return known_body
    return "unknown"


def extract_lifecycle_code(subject: str, text: str = "") -> Optional[str]:
    subj = str(subject or "")
    body = str(text or "")
    blob_subj = _fold(subj)

    formula = _formula_parts(subj)
    if formula:
        return formula[1]

    if "huilo" in blob_subj:
        m = _CODE_HUILO.search(subj) or _CODE_HUILO.search(body)
        if m:
            return m.group(1)
    if "corralco" in blob_subj:
        m = _CODE_CORRALCO.search(subj) or _CODE_CORRALCO.search(body)
        if m:
            return m.group(1)

    for blob in (subj, f"{subj}\n{body}"):
        for rx in (_CODE_LABELED, _CODE_HOTEL, _CODE_HASH, _CODE_CORRALCO):
            m = rx.search(blob)
            if m:
                code = _clean_code(m.group(1))
                if code:
                    return code
        m = _CODE_PAREN.search(blob)
        if m:
            return m.group(1)

    alnum = [_clean_code(m.group(1)) for m in _CODE_ALNUM.finditer(subj)]
    alnum = [c for c in alnum if c]
    with_digit = [c for c in alnum if re.search(r"\d", c)]
    if with_digit:
        return with_digit[-1]
    if alnum:
        return alnum[-1]

    m = _CODE_HASH.search(subj) or _CODE_DIGITS.search(subj)
    if m:
        return _clean_code(m.group(1))
    return None


def extract_lifecycle_codes(subject: str, text: str = "") -> list[str]:
    seen = []
    one = extract_lifecycle_code(subject, text)
    if one:
        seen.append(one)
    blob = f"{subject}\n{text or ''}"
    for rx in (_CODE_HUILO, _CODE_HASH, _CODE_DIGITS, _CODE_ALNUM):
        for m in rx.finditer(blob):
            code = _clean_code(m.group(1))
            if code and code not in seen and code not in _BLOCK_CODES:
                seen.append(code)
            if len(seen) >= 6:
                return seen
    return seen


_INTERNAL_DOMAINS = ("checkin24hs.com",)

_HOTEL_DOMAINS = (
    "puyehue.cl",
    "huilohuilo.com",
    "corralco.com",
    "corralco.cl",
)

_CUT_QUOTE = re.compile(
    r"(?im)^(?:"
    r"on .+ wrote:\s*$"
    r"|el .+ escribi[oó]:\s*$"
    r"|from:\s*checkin24hs"
    r"|de:\s*checkin24hs"
    r"|solicitamos anular la siguiente reserva"
    r"|solicitamos modificar la siguiente reserva"
    r"|consulta sobre la siguiente reserva"
    r"|-{5,}.*original"
    r"|_{5,}"
    r")",
)

_CONFIRM_CANCEL = re.compile(
    r"(?:"
    r"confirmamos (?:que )?(?:la )?(?:anulaci[oó]n|cancelaci[oó]n)"
    r"|confirmamos que (?:la )?reserva (?:fue |queda |qued[oó] |est[aá] )?(?:anulad[ao]|cancelad[ao])"
    r"|(?:la )?reserva (?:fue |ha sido |queda |qued[oó] |est[aá] )?(?:correctamente )?(?:anulad[ao]|cancelad[ao])"
    r"|(?:fue |ha sido |queda |qued[oó] |est[aá] )(?:correctamente )?(?:anulad[ao]|cancelad[ao])"
    r"|hemos (?:procedido a )?(?:anular|cancelar|anulado|cancelado)"
    r"|se (?:procedi[oó] a )?(?:anular|cancelar|anul[oó]|cancel[oó])"
    r"|(?:anulaci[oó]n|cancelaci[oó]n) (?:confirmada|realizada|efectuada|ok)"
    r"|damos (?:de )?baja"
    r"|aceptamos (?:la )?(?:anulaci[oó]n|cancelaci[oó]n)"
    r"|\banulamos\b"
    r"|\bcancelamos\b"
    r"|de acuerdo con la (?:anulaci[oó]n|cancelaci[oó]n)"
    r"|ok,? se (?:anula|cancela)"
    r"|proced\w* (?:con |a )?(?:la )?(?:anulaci[oó]n|cancelaci[oó]n)"
    r"|proced\w* a (?:anular|cancelar)"
    r"|n[°ºo.]?\s*cancelaci[oó]n"
    r"|acusamos recibo.{0,80}(?:anular|cancelar|anulaci|cancelaci)"
    r"|qued[oó] sin efecto"
    r"|sin efecto la reserva"
    r")",
    re.I,
)

_CONFIRM_MODIFY = re.compile(
    r"(?:"
    r"confirmamos (?:que )?(?:la )?(?:modificaci[oó]n|el cambio)"
    r"|(?:la )?reserva (?:fue |ha sido |queda |qued[oó] |est[aá] )?modificad[ao]"
    r"|hemos modificado"
    r"|se (?:modific[oó]|actualiz[oó])"
    r"|modificaci[oó]n (?:confirmada|realizada|efectuada|aceptada)"
    r"|cambios? (?:aceptados?|confirmados?|realizados?|aplicados?)"
    r"|fechas? (?:actualizadas?|modificadas?|cambiadas?|ok|correctas?)"
    r"|aceptamos (?:el cambio|la modificaci[oó]n)"
    r")",
    re.I,
)

_REPLY_BLOCK = re.compile(
    r"(?:"
    r"no (?:es |nos es )?posible"
    r"|no (?:podemos|se puede)(?:\s+(?:anular|cancelar|modificar|aceptar|proceder))?"
    r"|lamentamos (?:informar )?(?:que )?no"
    r"|fuera de (?:plazo|tiempo|t[eé]rmino)"
    r"|recargo"
    r"|penalidad"
    r"|cargo por (?:cancel|anul)"
    r"|\bno[\s\-]?show\b"
    r"|no corresponde"
    r"|sujeto a (?:confirmaci[oó]n|disponibilidad|pol[ií]tica)"
    r"|lo (?:vamos a )?(?:revisar|revisamos|evaluar|evaluamos|analizar|analizamos)"
    r"|en (?:revisi[oó]n|evaluaci[oó]n)"
    r"|no (?:hay|tenemos|contamos con|disponemos de|queda) (?:\w+ )?disponibilidad"
    r"|sin disponibilidad"
    r"|no (?:hay|tenemos|quedan?) (?:lugar|cupo|habitaciones|caba[nñ]as)"
    r"|no (?:fue|ha sido|es) (?:posible|factible)"
    r"|(?:rechazad[ao]|denegad[ao])"
    r")",
    re.I,
)

# Respuestas "en trámite" o que no afirman nada todavía: nunca son confirmación.
_REPLY_PENDING = re.compile(
    r"(?:"
    r"\b(?:aun|todavia) no\b"
    r"|\bno (?:hemos|se ha|se han|fue|ha sido) (?:\w+ )?(?:modificad|anulad|cancelad|procesad|realizad|confirmad|actualizad)"
    r"|a la espera"
    r"|en (?:proceso|tramite|gestion)"
    r"|estamos (?:gestionando|revisando|verificando|consultando|chequeando)"
    r"|(?:lo|la) (?:consultamos|consulto|verifico|verificamos|chequeamos)"
    r"|te (?:confirmo|confirmamos|aviso|avisamos) (?:a la brevedad|en breve|luego|mas tarde|despues)"
    r"|les (?:confirmo|confirmamos|aviso|avisamos) (?:a la brevedad|en breve|luego|mas tarde|despues)"
    r"|pendiente"
    r")",
    re.I,
)


def _sender_domain(from_addr: str) -> str:
    addr = str(from_addr or "").lower().strip()
    if "@" not in addr:
        return ""
    return addr.rsplit("@", 1)[-1].strip(">")


def is_internal_sender(from_addr: str) -> bool:
    domain = _sender_domain(from_addr)
    return any(domain == d or domain.endswith("." + d) for d in _INTERNAL_DOMAINS)


def is_hotel_sender(from_addr: str) -> bool:
    if is_internal_sender(from_addr):
        return False
    domain = _sender_domain(from_addr)
    if not domain:
        return False
    if any(domain == d or domain.endswith("." + d) for d in _HOTEL_DOMAINS):
        return True
    return "@" in str(from_addr or "")


def _plain_from_html(html: str) -> str:
    s = html_lib.unescape(str(html or ""))
    s = re.sub(r"(?i)<br\s*/?>", "\n", s)
    s = re.sub(r"(?i)</(p|div|tr|h[1-6]|li)>", "\n", s)
    s = re.sub(r"<[^>]+>", " ", s)
    return re.sub(r"[ \t]+\n", "\n", s)


def own_reply_text(text: str, html: str = "") -> str:
    """Solo el mensaje nuevo del hotel, sin el pedido citado de Checkin24hs."""
    html_plain = ""
    if html:
        h = str(html)
        h = re.sub(r"(?is)<blockquote[\s\S]*?</blockquote>", "\n", h)
        h = re.sub(r'(?is)<div[^>]*gmail_quote[\s\S]*', "\n", h)
        html_plain = _plain_from_html(h)
    raw = str(text or "").strip()
    if len(raw) < 20 and html_plain:
        raw = html_plain
    s = str(raw or "").replace("\r", "")
    s = re.split(r"(?im)^De:\s+.+\nEnviado el:", s)[0]
    s = re.split(r"(?im)^From:\s+.+\nSent:", s)[0]
    s = re.split(r"(?im)^-{5,}Original Message-{5,}", s)[0]
    out = []
    for line in s.split("\n"):
        if line.strip().startswith(">"):
            break
        if _CUT_QUOTE.search(line.strip()):
            break
        out.append(line)
    return "\n".join(out).strip()


def classify_hotel_reply(kind: str, own_text: str) -> str:
    """confirm_cancel | confirm_modify | reject | unclear"""
    t = _fold(own_text)
    t = re.sub(r"\s+", " ", t).strip()
    if len(t) < 8:
        return "unclear"
    blocked = bool(_REPLY_BLOCK.search(t))
    cc = bool(_CONFIRM_CANCEL.search(t))
    cm = bool(_CONFIRM_MODIFY.search(t))
    if blocked:
        return "reject"
    if not (cc or cm):
        return "unclear"
    # Conservador: si todavía está en trámite o nos devuelve una pregunta, no es confirmación.
    if _REPLY_PENDING.search(t):
        return "unclear"
    if "?" in t or "\u00bf" in t:
        return "unclear"
    if cc and cm:
        return "confirm_cancel" if kind == "cancel" else "confirm_modify"
    # Confirmación del tipo contrario al pedido (p.ej. "anulada" en un pedido de modificación):
    # no se aplica sola, se avisa como respuesta confusa.
    if cc:
        return "confirm_cancel" if kind == "cancel" else "unclear"
    if cm:
        return "confirm_modify" if kind == "modify" else "unclear"
    return "unclear"


# ===== Cambios concretos de una modificación (fechas / pasajeros / tarifa) =====

_MONTHS = {
    "enero": 1, "ene": 1, "febrero": 2, "feb": 2, "marzo": 3, "mar": 3, "abril": 4, "abr": 4,
    "mayo": 5, "may": 5, "junio": 6, "jun": 6, "julio": 7, "jul": 7, "agosto": 8, "ago": 8,
    "septiembre": 9, "setiembre": 9, "sep": 9, "sept": 9, "set": 9, "octubre": 10, "oct": 10,
    "noviembre": 11, "nov": 11, "diciembre": 12, "dic": 12,
}
_NUM_WORDS = {
    "un": 1, "uno": 1, "una": 1, "dos": 2, "tres": 3, "cuatro": 4, "cinco": 5, "seis": 6,
    "siete": 7, "ocho": 8, "nueve": 9, "diez": 10,
}
_NUM = r"\b(\d{1,2}|un|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez)"
_MONTH_RX = "|".join(sorted(_MONTHS, key=len, reverse=True))

_DATE_NUM = re.compile(r"\b(\d{1,2})[/\-.](\d{1,2})(?:[/\-.](\d{2,4}))?\b")
_DATE_ISO = re.compile(r"\b(20\d{2})-(\d{1,2})-(\d{1,2})\b")
_DATE_TXT = re.compile(
    r"\b(\d{1,2})\s*(?:de\s+)?(" + _MONTH_RX + r")\.?(?:\s*(?:de|del)?\s*(20\d{2}))?\b",
    re.I,
)
_RANGE_TXT = re.compile(
    r"\b(?:del|desde el|desde)\s+(\d{1,2})\s*(?:de\s+(" + _MONTH_RX + r"))?\s*"
    r"(?:al|hasta el|hasta|-)\s*(\d{1,2})\s*(?:de\s+)?(" + _MONTH_RX + r")\.?"
    r"(?:\s*(?:de|del)?\s*(20\d{2}))?",
    re.I,
)
_IN_LABEL = re.compile(r"(?:check[\s\-]?in|ingreso|llegada|entrada|arribo)", re.I)
_OUT_LABEL = re.compile(r"(?:check[\s\-]?out|egreso|salida|partida)", re.I)
_NIGHTS = re.compile(_NUM + r"\s+noches?\b", re.I)

_USD_AMOUNT = re.compile(
    r"(?:\b(?:usd|us\$|u\$s|u\$d|dolares|dólares)\s*:?\s*([\d][\d.,]*))"
    r"|(?:([\d][\d.,]*)\s*(?:usd|us\$|u\$s|dolares|dólares)\b)",
    re.I,
)
_OTHER_AMOUNT = re.compile(
    r"(?:\b(?:clp|ars|pesos?)\b\s*\$?\s*[\d][\d.,]*)"
    r"|(?:[\d][\d.,]*\s*\b(?:clp|ars|pesos?)\b)"
    r"|(?:(?<![a-z])\$\s*[\d][\d.,]*)",
    re.I,
)
_AMOUNT_TOTAL_HINT = re.compile(r"total|tarifa|nuevo valor|nuevo monto|valor final|monto final|importe|precio|queda en", re.I)
_AMOUNT_PARTIAL_HINT = re.compile(
    r"diferencia|adicional|saldo|se[nñ]a|dep[oó]sito|anticipo|abon|pag(?:o|ar|ado)|por noche|p/noche|por persona|suplemento",
    re.I,
)

_ADULTS = [
    re.compile(_NUM + r"\s*(?:adultos?|adt|pax adultos?)\b", re.I),
    re.compile(r"\badultos?\s*[:=]?\s*(\d{1,2})\b", re.I),
]
_CHILDREN = [
    re.compile(_NUM + r"\s*(?:ni[nñ][oa]s?|menores?|chicos?|chd)\b", re.I),
    re.compile(r"\b(?:ni[nñ][oa]s?|menores?)\s*[:=]\s*(\d{1,2})\b", re.I),
]
_INFANTS = re.compile(_NUM + r"\s*(?:infantes?|beb[eé]s?)\b", re.I)
_TOTAL_PAX = re.compile(_NUM + r"\s*(?:pax|personas|hu[eé]spedes|pasajeros)\b", re.I)
_CAPACITY_BEFORE = re.compile(r"(?:cap\.?|capacidad|hasta|m[aá]x(?:imo)?\.?)\s*$", re.I)


def _num(raw: str) -> Optional[int]:
    raw = str(raw or "").strip().lower()
    if raw.isdigit():
        return int(raw)
    return _NUM_WORDS.get(raw)


def _money(raw: str) -> Optional[float]:
    s = str(raw or "").strip().rstrip(".,")
    if not s:
        return None
    if "," in s and "." in s:
        if s.rfind(",") > s.rfind("."):
            s = s.replace(".", "").replace(",", ".")
        else:
            s = s.replace(",", "")
    elif "," in s:
        parts = s.split(",")
        s = s.replace(",", "") if len(parts[-1]) == 3 else s.replace(",", ".")
    elif "." in s:
        parts = s.split(".")
        if len(parts) > 2 or len(parts[-1]) == 3:
            s = s.replace(".", "")
    try:
        v = float(s)
    except ValueError:
        return None
    return v if 10 <= v <= 200000 else None


def _mkdate(y, m, d):
    import datetime as _dt

    try:
        return _dt.date(int(y), int(m), int(d))
    except (TypeError, ValueError):
        return None


def _year_for(month: int, day: int, ref_date):
    """Año de una fecha sin año: la próxima ocurrencia desde ref_date (con 30 días de gracia)."""
    import datetime as _dt

    ref = ref_date or _dt.date.today()
    for y in (ref.year, ref.year + 1):
        cand = _mkdate(y, month, day)
        if cand and cand >= ref - _dt.timedelta(days=30):
            return cand
    return None


def _dates_in(text: str, ref_date) -> list[tuple[int, object]]:
    """[(posición, date)] de todas las fechas reconocibles del texto."""
    out = []
    for m in _DATE_ISO.finditer(text):
        d = _mkdate(m.group(1), m.group(2), m.group(3))
        if d:
            out.append((m.start(), d))
    iso_spans = [(m.start(), m.end()) for m in _DATE_ISO.finditer(text)]
    for m in _DATE_NUM.finditer(text):
        if any(a <= m.start() < b for a, b in iso_spans):
            continue
        day, month, year = int(m.group(1)), int(m.group(2)), m.group(3)
        if not (1 <= month <= 12 and 1 <= day <= 31):
            continue
        if year:
            y = int(year)
            y = y + 2000 if y < 100 else y
            d = _mkdate(y, month, day)
        else:
            d = _year_for(month, day, ref_date)
        if d:
            out.append((m.start(), d))
    for m in _DATE_TXT.finditer(text):
        month = _MONTHS.get(m.group(2).lower())
        day = int(m.group(1))
        d = _mkdate(m.group(3), month, day) if m.group(3) else _year_for(month, day, ref_date)
        if d:
            out.append((m.start(), d))
    out.sort(key=lambda x: x[0])
    return out


def _unique(values):
    seen = []
    for v in values:
        if v not in seen:
            seen.append(v)
    return seen


def extract_modification_changes(own_text: str, ref_date=None) -> dict:
    """Lee SOLO lo que el hotel escribió (sin el pedido citado) y devuelve los campos
    que afirma con claridad: check_in, check_out, adults, children, total_amount (USD).
    Si algo es contradictorio va a "ambiguous" y no se aplica nada de ese campo.
    """
    import datetime as _dt

    text = re.sub(r"[ \t]+", " ", str(own_text or "").replace("\r", ""))
    ref = ref_date or _dt.date.today()
    res = {"ambiguous": [], "ignored": []}

    # --- Fechas ---
    check_in = check_out = None
    rng = _RANGE_TXT.search(text)
    if rng:
        m_out = _MONTHS.get(rng.group(4).lower())
        m_in = _MONTHS.get((rng.group(2) or rng.group(4)).lower())
        year = rng.group(5)
        if year:
            check_out = _mkdate(year, m_out, rng.group(3))
            check_in = _mkdate(int(year) - (1 if m_in > m_out else 0), m_in, rng.group(1))
        else:
            check_in = _year_for(m_in, int(rng.group(1)), ref)
            check_out = _year_for(m_out, int(rng.group(3)), check_in or ref)
    dates = _dates_in(text, ref)
    labeled_in, labeled_out = [], []
    for pos, d in dates:
        before = text[max(0, pos - 40):pos]
        line_before = before.split("\n")[-1]
        has_in = _IN_LABEL.search(line_before)
        has_out = _OUT_LABEL.search(line_before)
        if has_in and has_out:
            # "check-in 20/11 y check-out 22/11" → la etiqueta más cercana manda
            last_in = max(m.end() for m in _IN_LABEL.finditer(line_before))
            last_out = max(m.end() for m in _OUT_LABEL.finditer(line_before))
            (labeled_in if last_in > last_out else labeled_out).append(d)
        elif has_in:
            labeled_in.append(d)
        elif has_out:
            labeled_out.append(d)
    if labeled_in or labeled_out:
        li, lo = _unique(labeled_in), _unique(labeled_out)
        if len(li) > 1:
            res["ambiguous"].append("check_in")
        elif li:
            if check_in and check_in != li[0]:
                res["ambiguous"].append("check_in")
            check_in = li[0]
        if len(lo) > 1:
            res["ambiguous"].append("check_out")
        elif lo:
            if check_out and check_out != lo[0]:
                res["ambiguous"].append("check_out")
            check_out = lo[0]
    elif not rng and dates:
        uniq = _unique([d for _, d in dates])
        if len(uniq) == 2 and uniq[0] < uniq[1]:
            check_in, check_out = uniq
        else:
            res["ambiguous"].append("fechas")

    nights_vals = _unique([_num(m.group(1)) for m in _NIGHTS.finditer(text)])
    nights_vals = [n for n in nights_vals if n]
    if len(nights_vals) > 1:
        res["ambiguous"].append("noches")
    elif nights_vals:
        n = nights_vals[0]
        if check_in and not check_out:
            check_out = check_in + _dt.timedelta(days=n)
        elif check_in and check_out and (check_out - check_in).days != n:
            res["ambiguous"].append("noches")
        elif not check_in and not check_out:
            res["nights"] = n  # se resuelve contra la reserva (mismo check-in)

    if check_in and check_out:
        span = (check_out - check_in).days
        if span <= 0 or span > 45:
            res["ambiguous"].append("fechas")
            check_in = check_out = None
    for key, d in (("check_in", check_in), ("check_out", check_out)):
        if d and key not in res["ambiguous"]:
            if d < ref - _dt.timedelta(days=2) or d > ref + _dt.timedelta(days=800):
                res["ambiguous"].append(key)
            else:
                res[key] = d.isoformat()

    # --- Pasajeros ---
    def _counts(patterns):
        vals = []
        for rx in patterns:
            for m in rx.finditer(text):
                if _CAPACITY_BEFORE.search(text[max(0, m.start() - 15):m.start()]):
                    continue
                v = _num(m.group(1))
                if v is not None and 0 <= v <= 30:
                    vals.append(v)
        return _unique(vals)

    adults = _counts(_ADULTS)
    children = _counts(_CHILDREN)
    infants = _counts([_INFANTS])
    if len(adults) > 1:
        res["ambiguous"].append("adults")
    elif adults:
        res["adults"] = adults[0]
    if len(children) > 1:
        res["ambiguous"].append("children")
    elif children:
        res["children"] = children[0]
    if infants:
        res["ignored"].append(f"infantes {', '.join(str(i) for i in infants)} (sin columna en reservas)")
    if not adults and not children:
        total = _counts([_TOTAL_PAX])
        if len(total) > 1:
            res["ambiguous"].append("pasajeros")
        elif total:
            res["total_pax"] = total[0]

    # --- Tarifa (solo USD explícito) ---
    usd = []
    for m in _USD_AMOUNT.finditer(text):
        v = _money(m.group(1) or m.group(2))
        if v is None:
            continue
        line_start = text.rfind("\n", 0, m.start()) + 1
        line_end = text.find("\n", m.end())
        line = text[line_start: line_end if line_end >= 0 else len(text)]
        usd.append((v, bool(_AMOUNT_TOTAL_HINT.search(line)), bool(_AMOUNT_PARTIAL_HINT.search(line))))
    candidates = [u for u in usd if not u[2]]
    if usd and not candidates:
        res["ambiguous"].append("total_amount")  # solo montos parciales (diferencia, seña…)
    elif candidates:
        vals = _unique([v for v, _, _ in candidates])
        if len(vals) > 1:
            hinted = _unique([v for v, h, _ in candidates if h])
            vals = hinted if len(hinted) == 1 else vals
        if len(vals) == 1:
            res["total_amount"] = round(vals[0], 2)
        else:
            res["ambiguous"].append("total_amount")
    if _OTHER_AMOUNT.search(text) and "total_amount" not in res:
        res["ignored"].append("monto en moneda no USD (se mantiene la tarifa actual)")

    res["ambiguous"] = _unique(res["ambiguous"])
    return res


def parse_lifecycle_mail(mail: dict) -> Optional[dict]:
    subject = str(mail.get("subject") or "")
    text = str(mail.get("text") or "")
    html = str(mail.get("html") or "")
    intent = lifecycle_intent(subject)
    if not intent:
        return None
    body = f"{text}\n{html}"
    codes = extract_lifecycle_codes(subject, body)
    code = codes[0] if codes else extract_lifecycle_code(subject, body)
    if not code:
        return None
    hotel_key = hotel_key_from_lifecycle(subject, body)
    own = own_reply_text(text, html)
    extra = {}
    changes = None
    if intent == "modify":
        changes = extract_modification_changes(own)
    if intent == "modify" and changes is not None and not any(
        k in changes for k in ("check_in", "check_out", "adults", "children", "total_amount")
    ):
        # Fallback: el hotel respondió con una confirmación nueva del portal (solo su texto, sin citas)
        try:
            from parse_puyehue import parse_puyehue_mail

            fake_subj = (
                f"Confirmación de Reserva Termas Aguas Calientes {code}"
                if hotel_key == "aguas_calientes"
                else f"Confirmación de Reserva Hotel Puyehue {code}"
            )
            row = parse_puyehue_mail(
                {
                    "from": mail.get("from") or "reservas@puyehue.cl",
                    "subject": fake_subj,
                    "text": own,
                    "html": "",
                    "date": mail.get("date"),
                }
            )
            if row and row.get("kind") == "client":
                for key in ("check_in", "check_out", "adults"):
                    if row.get(key) not in (None, "", 0):
                        changes[key] = row.get(key)
                if row.get("adults") and row.get("children") is not None:
                    changes["children"] = row.get("children")
                amt = row.get("total_amount")
                if amt and (row.get("currency") or "USD") == "USD" and re.search(r"US\$|USD|U\$S", own, re.I):
                    changes["total_amount"] = amt
                extra = {
                    "client_name": row.get("client_name") or "",
                    "check_in": row.get("check_in"),
                    "check_out": row.get("check_out"),
                    "total_amount": row.get("total_amount"),
                    "currency": row.get("currency") or "USD",
                    "notes": row.get("notes"),
                }
        except Exception:
            extra = {}
    return {
        "kind": intent,
        "hotel_key": hotel_key,
        "reservation_code": code,
        "reservation_codes": codes or [code],
        "client_name": extra.get("client_name") or "",
        "check_in": extra.get("check_in"),
        "check_out": extra.get("check_out"),
        "total_amount": extra.get("total_amount"),
        "currency": extra.get("currency") or "USD",
        "notes": extra.get("notes"),
        "own_text": own,
        "hotel_verdict": classify_hotel_reply(intent, own),
        "changes": changes,
    }
