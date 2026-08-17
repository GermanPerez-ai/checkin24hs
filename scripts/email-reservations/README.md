# Sync de reservas por email (Huilo Huilo)

Lee la casilla **`reservas@checkin24hs.com`** por IMAP y carga **confirmaciones** de Huilo Huilo en Supabase → Dashboard → Reservas.

- **Confirmaciones:** email (este script)
- **Modificaciones / cancelaciones:** WhatsApp (grupo Confirmaciones Huilo)

## 1. Supabase

Ejecutá en SQL Editor:

- `supabase-migrations/073_email_reservation_imports.sql`

## 2. Config en el VPS

```bash
cd /root/checkin24hs/scripts/email-reservations
cp .env.example .env
nano .env   # IMAP_PASS y SUPABASE_SERVICE_ROLE_KEY
```

IMAP en el VPS: `IMAP_HOST=127.0.0.1`, `IMAP_PORT=143`, `IMAP_USER=reservas` (usuario de sistema, no el mail completo). **No pongas `IMAP_PASS` en el `.env` de la web.**

**No subas `.env` a git.**

## 3. Probar

```bash
python3 test_parse_huilo.py
python3 sync.py --dry-run --since-days=90

# Relee mails que quedaron en skipped (tablas HTML)
python3 sync.py --retry-skipped --since-days=90
```

Si un asunto no parsea:

```bash
python3 dump_unparsed.py --subject-contains="Caupolican" --since-days=90
```

## 4. Cron (cada 6 horas)

```
0 */6 * * * cd /root/checkin24hs/scripts/email-reservations && /usr/bin/python3 sync.py --since-days=14 >> /var/log/email-reservas-huilo.log 2>&1
```

## Notas

- Deduplica por `Message-ID` en `email_reservation_imports` y por `reservation_code` en `reservations`.
- Los skipped no se reintentan solos: hace falta `--retry-skipped`.
- El hotel se busca en `hotels` por nombre que contenga “huilo”.
- Si el mail no trae teléfono/email del huésped, quedan vacíos (se puede completar a mano en el dashboard).
