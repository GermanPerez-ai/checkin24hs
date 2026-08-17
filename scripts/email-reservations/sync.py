#!/usr/bin/env python3
"""Sync IMAP (Dovecot LOGIN) → Supabase. Confirmaciones Huilo Huilo."""
from __future__ import annotations

import argparse
import datetime as dt
import email
import imaplib
import json
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
from email.header import decode_header
from email.utils import parseaddr
from pathlib import Path

from parse_huilo import parse_huilo_confirmation, strip_html

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


def find_hotel():
    q = "hotels?select=id,name&or=(name.ilike.*huilo*,name.ilike.*Huilo*)&limit=5"
    data = sb("GET", q)
    if not isinstance(data, list) or not data:
        return {"id": None, "name": "Huilo Huilo"}
    preferred = next((h for h in data if "huilo" in (h.get("name") or "").lower() and "pack" not in (h.get("name") or "").lower()), data[0])
    return {"id": preferred.get("id"), "name": preferred.get("name") or "Huilo Huilo"}


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


def upsert_reservation(parsed, hotel):
    row = {
        "reservation_code": parsed["reservation_code"],
        "client_name": parsed["client_name"],
        "client_email": "",
        "client_phone": "",
        "hotel_id": hotel.get("id"),
        "hotel_name": hotel.get("name"),
        "check_in": parsed["check_in"],
        "check_out": parsed["check_out"],
        "reservation_date": dt.date.today().isoformat(),
        "agent_name": "Email Huilo",
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

    hotel = {"id": None, "name": "Huilo Huilo"} if args.dry_run else find_hotel()
    print(f"🏨 Hotel destino: {hotel['name']}")

    stats = {"scanned": 0, "parsed": 0, "imported": 0, "skipped": 0, "errors": 0}
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

            if "huilohuilo.com" not in from_addr.lower() and "huilo" not in subject.lower():
                continue

            if not args.dry_run and already_imported(message_id, args.retry_skipped):
                stats["skipped"] += 1
                continue

            parsed = parse_huilo_confirmation(
                {"from": from_addr, "subject": subject, "text": text, "html": html}
            )
            if not parsed:
                print(f"⏭️  No parseable: {subject}")
                if not args.dry_run:
                    try:
                        mark_imported(
                            {
                                "message_id": message_id,
                                "reservation_code": None,
                                "hotel_key": "huilo",
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

            stats["parsed"] += 1
            print(
                f"✅ {parsed['reservation_code']} | {parsed['client_name']} | "
                f"{parsed['check_in']}→{parsed['check_out']} | {parsed['currency']} {parsed['total_amount']}"
            )
            if args.dry_run:
                continue
            try:
                upsert_reservation(parsed, hotel)
                mark_imported(
                    {
                        "message_id": message_id,
                        "reservation_code": parsed["reservation_code"],
                        "hotel_key": "huilo",
                        "subject": subject,
                        "from_addr": from_addr,
                        "status": "imported",
                    }
                )
                stats["imported"] += 1
            except Exception as e:
                stats["errors"] += 1
                print(f"❌ Error importando {parsed['reservation_code']}: {e}")
    finally:
        try:
            client.logout()
        except Exception:
            pass

    print("———")
    print(
        f"Listo. scanned={stats['scanned']} parsed={stats['parsed']} "
        f"imported={stats['imported']} skipped={stats['skipped']} errors={stats['errors']}"
    )


if __name__ == "__main__":
    main()
