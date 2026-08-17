# Sync de reservas por email (Huilo Huilo)

Lee la casilla **`reservas@checkin24hs.com`** por IMAP y carga **confirmaciones** de Huilo Huilo en Supabase → Dashboard → Reservas.

- **Confirmaciones:** email (este script)
- **Modificaciones / cancelaciones:** WhatsApp (manual / otro flujo)

## 1. Supabase

Ejecutá en SQL Editor:

- `supabase-migrations/073_email_reservation_imports.sql`

## 2. Config en el VPS

```bash
cd /root/checkin24hs/scripts/email-reservations
cp .env.example .env
nano .env   # completar IMAP_PASS y SUPABASE_SERVICE_ROLE_KEY
npm install
```

Variables mínimas:

| Variable | Ejemplo |
|----------|---------|
| `IMAP_HOST` | `mail.checkin24hs.com` |
| `IMAP_PORT` | `993` |
| `IMAP_USER` | `reservas@checkin24hs.com` |
| `IMAP_PASS` | *(contraseña de la casilla)* |
| `IMAP_TLS_REJECT_UNAUTHORIZED` | `0` (cert autofirmado) |
| `SUPABASE_URL` | tu proyecto |
| `SUPABASE_SERVICE_ROLE_KEY` | Settings → API |

**No subas `.env` a git.**

## 3. Probar

```bash
# Solo parsea / lista, no escribe
node sync.js --dry-run --since-days=90

# Importa de verdad
node sync.js --since-days=90
```

## 4. Cron (cada 6 horas)

```bash
crontab -e
```

```
0 */6 * * * cd /root/checkin24hs/scripts/email-reservations && /usr/bin/node sync.js --since-days=14 >> /var/log/email-reservas-huilo.log 2>&1
```

## Notas

- Deduplica por `Message-ID` en `email_reservation_imports` y por `reservation_code` en `reservations`.
- El hotel se busca en `hotels` por nombre que contenga “huilo”.
- Si el mail no trae teléfono/email del huésped, quedan vacíos (se puede completar a mano en el dashboard).
