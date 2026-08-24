#!/usr/bin/env python3
"""Dump texto/HTML de mails Huilo (para ver por qué no parsean)."""
from __future__ import annotations

import argparse
import datetime as dt
import email as email_mod
from email.utils import parseaddr

from parse_corralco import parse_corralco_confirmations
from parse_huilo import html_to_text, parse_huilo_confirmations
from parse_puyehue import parse_puyehue_mail
from sync import MAILBOX, body_text, connect_imap, decode_mime, msg_date


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--since-days", type=int, default=90)
    ap.add_argument("--subject-contains", required=True)
    ap.add_argument("--limit", type=int, default=5)
    args = ap.parse_args()

    needle = args.subject_contains.lower()
    since = dt.date.today() - dt.timedelta(days=max(1, args.since_days))
    since_imap = since.strftime("%d-%b-%Y")
    shown = 0
    client = connect_imap()
    try:
        client.select(MAILBOX, readonly=True)
        typ, data = client.search(None, "SINCE", since_imap)
        ids = (data[0] or b"").split()
        for uid in ids:
            typ, fetched = client.fetch(uid, "(RFC822)")
            if typ != "OK" or not fetched or not fetched[0]:
                continue
            msg = email_mod.message_from_bytes(fetched[0][1])
            subject = decode_mime(msg.get("Subject"))
            if needle not in subject.lower():
                continue
            from_addr = parseaddr(msg.get("From") or "")[1]
            text, html = body_text(msg)
            mail = {
                "from": from_addr,
                "subject": subject,
                "text": text,
                "html": html,
                "date": msg_date(msg),
            }
            rows = parse_huilo_confirmations(mail)
            if not rows:
                rows = parse_corralco_confirmations(mail)
            if not rows:
                puy = parse_puyehue_mail(mail)
                rows = [puy] if puy else []
            print("=" * 72)
            print(f"Subject: {subject}")
            print(f"From: {from_addr}")
            if rows:
                for parsed in rows:
                    kind = parsed.get("kind", "client")
                    if kind == "agency":
                        print(
                            f"Parsed agency: {parsed.get('reservation_code')} | "
                            f"{parsed.get('agent_name')}"
                        )
                    else:
                        print(
                            f"Parsed: {parsed.get('reservation_code')} | "
                            f"{parsed.get('client_name')} | "
                            f"{parsed.get('check_in')}→{parsed.get('check_out')} | "
                            f"{parsed.get('hotel_key')}"
                        )
            else:
                print("Parsed: NO")
            print("--- text ---")
            print((text or "")[:2500])
            print("--- html→text ---")
            print(html_to_text(html)[:2500] if html else "(sin html)")
            shown += 1
            if shown >= args.limit:
                break
    finally:
        try:
            client.logout()
        except Exception:
            pass
    if shown == 0:
        print(f"Sin mails con asunto que contenga: {args.subject_contains}")


if __name__ == "__main__":
    main()
