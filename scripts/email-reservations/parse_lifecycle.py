"""Mails de anular / modificar reserva — cualquier hotel del catálogo."""
from __future__ import annotations

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
    r"^(?:re:\s*|fwd:\s*)*"
    r"(?:anular|anulaci[oó]n|cancelaci[oó]n|cancelar|modificar|modificaci[oó]n|ajuste de precio)"
    r".{0,20}?"
    r"reserva(?:s)?"
    r"(?:\s+web)?"
    r"\s+(.+?)\s+"
    r"([A-Z][A-Z0-9]{4,9}|#\s*\d{5,10}|\d{6,10})\s*$",
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


def parse_lifecycle_mail(mail: dict) -> Optional[dict]:
    subject = str(mail.get("subject") or "")
    text = str(mail.get("text") or "")
    html = str(mail.get("html") or "")
    intent = lifecycle_intent(subject)
    if not intent:
        return None
    body = f"{text}\n{html}"
    code = extract_lifecycle_code(subject, body)
    if not code:
        return None
    hotel_key = hotel_key_from_lifecycle(subject, body)
    extra = {}
    if intent == "modify":
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
                    "text": text,
                    "html": html,
                    "date": mail.get("date"),
                }
            )
            if row and row.get("kind") == "client":
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
        "client_name": extra.get("client_name") or "",
        "check_in": extra.get("check_in"),
        "check_out": extra.get("check_out"),
        "total_amount": extra.get("total_amount"),
        "currency": extra.get("currency") or "USD",
        "notes": extra.get("notes"),
    }
