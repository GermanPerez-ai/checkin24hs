# Sync de reservas por email (Huilo Huilo + Corralco + Puyehue + Aguas Calientes)

Lee la casilla **`reservas@checkin24hs.com`** por IMAP y carga **confirmaciones** en Supabase → Dashboard → Reservas.

- **Confirmaciones Huilo:** email (este script)
- **Modificaciones / cancelaciones Huilo:** WhatsApp (grupo Confirmaciones Huilo)
- **Confirmaciones Corralco:** email (este script)
- **Modificaciones / cancelaciones Corralco:** WhatsApp (grupo **Reservas Corralco Paz**)
- **Confirmaciones Puyehue / Termas Aguas Calientes:** email (este script)
  - Mail **cliente** → sube la reserva (nombre, email, teléfono, fechas, monto)
  - Mail **agencia** → actualiza columna Agente (`Mariano Olivar (Canopy Promociones)`)
  - Asunto con **Reserva Web** → canal **Ventas Web Puyehue** / **Ventas Web Aguas Calientes**

## 1. Supabase

Ejecutá en SQL Editor (si aún no está):

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
python3 test_parse_corralco.py
python3 test_parse_puyehue.py
python3 sync.py --dry-run --since-days=90
python3 sync.py --dry-run --subject-contains="Puyehue" --since-days=90
python3 sync.py --dry-run --subject-contains="Aguas Calientes" --since-days=90

# Relee mails que quedaron en skipped (tablas HTML)
python3 sync.py --retry-skipped --since-days=90
```

Si un asunto no parsea:

```bash
python3 dump_unparsed.py --subject-contains="Puyehue" --since-days=90
python3 dump_unparsed.py --subject-contains="Corralco" --since-days=90
```

## 4. Cron (cada 6 horas)

```
0 */6 * * * cd /root/checkin24hs/scripts/email-reservations && /usr/bin/python3 sync.py --since-days=14 >> /var/log/email-reservas-huilo.log 2>&1
```

El mismo cron cubre Huilo, Corralco, Puyehue y Aguas Calientes.

## WhatsApp (Línea 2)

El chip de Línea 2 tiene que estar en el grupo **Reservas Corralco Paz**.

Opcional en el `.env` de WhatsApp 2:

```
CORRALCO_WA_GROUP_NAME=Reservas Corralco Paz
# CORRALCO_WA_GROUP_JID=1203...@g.us
```

## Notas

- Deduplica por `Message-ID` en `email_reservation_imports` y por `reservation_code` en `reservations`.
- Los skipped no se reintentan solos: hace falta `--retry-skipped`.
- Huilo → “huilo”; Corralco → “corralco”; Puyehue → “puyehue”; Aguas Calientes → “aguas calientes”.
- Agentes:
  - `Email Huilo` / `Email Corralco` / `Email Puyehue` / `Email Aguas Calientes`
  - `Ventas Web Puyehue` / `Ventas Web Aguas Calientes` (asunto con **Reserva Web**)
  - Agencia Puyehue: `Mariano Olivar (Canopy Promociones)` (desde el mail de agencia)
  - `WhatsApp Huilo` / `WhatsApp Corralco Paz`
- Si el mail no trae teléfono/email del huésped, quedan vacíos (se puede completar a mano en el dashboard).
