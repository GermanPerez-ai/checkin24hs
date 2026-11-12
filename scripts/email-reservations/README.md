# Sync de reservas por email (Huilo Huilo + Corralco + Puyehue + Aguas Calientes)

Lee la casilla **`reservas@checkin24hs.com`** por IMAP y carga **confirmaciones** en Supabase → Dashboard → Reservas.

## Anular / modificar (cualquier hotel)

Asunto: **`ANULAR RESERVA {Hotel} {código}`** o **`MODIFICAR RESERVA {Hotel} {código}`**.

Vale Puyehue, Huilo, Corralco, Aguas Calientes y **cualquier otro hotel del catálogo**. El sync busca el hotel por nombre y actualiza la reserva por código (no crea una fila nueva).

```
ANULAR RESERVA Hotel Puyehue VK5LDY
ANULAR RESERVA Huilo 600363973
MODIFICAR RESERVA Corralco #2602640
ANULAR RESERVA Llao Llao ABC12X
```

Consulta / info: **no** usar ANULAR ni MODIFICAR.

La respuesta del **hotel** (mismo hilo) se lee el cuerpo, sin el texto citado:

- “Confirmamos la anulación / queda anulada” → **Cancelada** (auto)
- “Confirmamos la modificación / fechas actualizadas” → **Modificada** (auto)
- “No se puede”, recargo, no show, “lo revisamos” → **En gestión** (no cierra)
- “Recibido” u otra frase ambigua → no toca el estado (sigue pedida; ventas confirma a mano)

El mail de ventas (`@checkin24hs.com`) nunca cierra: deja **Anulación pedida** / **Modificación pedida**.
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

## 4. Cron (cada 15 minutos)

```
*/15 * * * * cd /root/checkin24hs/scripts/email-reservations && /usr/bin/python3 sync.py --since-days=14 >> /var/log/email-reservas-huilo.log 2>&1
```

El mismo cron cubre Huilo, Corralco, Puyehue y Aguas Calientes.

## Anular / modificar: cierre automático y avisos

- Respuesta del hotel que **confirma** → la reserva se cierra sola: anulación → `Cancelada`; modificación → `Modificada`
  aplicando solo lo que el hotel escribe con claridad (check-in/check-out o noches, adultos/niños, tarifa en USD).
  Queda nota `[HOTEL confirmó … — auto] campo viejo→nuevo` y sale un WhatsApp "Hotel confirmó … — aplicado".
- Respuesta **confusa** (no se entiende, pregunta algo, "aún no", montos en CLP/ARS, valores contradictorios)
  sobre una reserva en `Modificación pedida` / `Anulación pedida` / `En gestión` → no se toca la reserva y sale
  "⚠️ El hotel respondió pero la respuesta es confusa". Negativas ("no hay disponibilidad", "no es posible") → `En gestión`.
- Un aviso por mail (message-id), registrado en `ana_alerts_log` (`lifecycle_confusa` / `lifecycle_aplicada`).
  Si WhatsApp falla, el sync sigue.
- La respuesta cuenta si llegó después del último `[PEDIDO …]` (fecha+hora, margen 10 min).
- Respuestas "suaves" ("acuso recibo…", "se asignó…", "monto a pagar … corresponde a U$D X") cuentan como confirmación
  solo si traen un valor concreto (monto USD, pasajeros, fechas). Saludos tipo "¿cómo estás?" no cuentan como pregunta.
- Pasajeros: se toma la cantidad actual de las notas (`Pasajeros: N adultos`); si no se puede mapear, va a la nota.
- Varias respuestas del mismo pedido se procesan en orden cronológico; una respuesta vaga posterior no deshace nada.
- `--dry-run` muestra `simulación:` (lee la reserva, no escribe ni manda WhatsApp).
- Config WhatsApp: `WHATSAPP_API_URL`, `WHATSAPP_API_KEY`, `WHATSAPP_GROUP_ID` del `.env` de este script o, si no
  están, del `email-monitor/.env` (mismo grupo de hoteles). Opcional: `LIFECYCLE_WHATSAPP_TO` (otro destino),
  `LIFECYCLE_WHATSAPP_ALERTS=0` (apagar avisos).

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
