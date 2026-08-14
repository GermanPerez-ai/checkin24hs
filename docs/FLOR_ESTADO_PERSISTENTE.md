# Flor IA — Estado de sesión persistente (Supabase)

Migración de estado crítico desde RAM (`florLastHotelByPhone`, inferencia del LLM) a **`whatsapp_chats`**.

## Migraciones requeridas (en orden)

1. `006_flor_paused_until.sql` — `flor_paused_until`
2. `050_flor_protocolo_silencio_humano.sql` — `last_human_outbound_at`, `is_from_flor`
3. **`051_flor_chat_session_state.sql`** — `current_hotel_id`, `cotizador_sent_at`

Ejecutar en Supabase SQL Editor:

```sql
-- Contenido de supabase-migrations/051_flor_chat_session_state.sql
```

## Columnas en `whatsapp_chats`

| Columna | Tipo | Uso |
|---------|------|-----|
| `current_hotel_id` | UUID → `hotels(id)` | Hotel activo de la conversación |
| `cotizador_sent_at` | timestamptz | Cuándo Flor envió el link del cotizador |
| `flor_paused_until` | timestamptz | Fin del silencio tras intervención humana |
| `last_human_outbound_at` | timestamptz | Último mensaje saliente humano (cualquier canal) |

## Flujo en el servidor

### 1. Prompt dinámico

Antes de llamar a Gemini, se inyecta:

```
Contexto de sesión (persistente en base de datos):
- Hotel en consulta: [nombre]
- ¿Cotizador ya enviado?: SÍ/NO
[+ reglas si cotizador ya enviado]
```

### 2. Middleware pre-Gemini (`procesarConFlor`)

- **Silencio:** `flor_paused_until > now()` o `last_human_outbound_at` reciente → no llama a Gemini
- **Hotel:** al detectar otro hotel en catálogo → `UPDATE current_hotel_id`
- **Cotizador:** si `cotizador_sent_at` no es null → instrucción explícita de no reenviar link

### 3. Al enviar respuesta con link cotizador

Tras enviar mensaje con `cotizar.checkin24hs.com` → `UPDATE cotizador_sent_at = now()`

### 4. Intervención humana (multicanal)

WhatsApp móvil, `/api/send`, dashboard → `setFlorPausedUntil` actualiza `flor_paused_until` + `last_human_outbound_at`

## Deploy

```bash
cd /root/checkin24hs
git pull origin main
# 1) Ejecutar migración 051 en Supabase
docker build -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/
docker service update --image easypanel/checkin24hs/whatsapp:latest --force checkin24hs_whatsapp
# L2-L4 si aplica
bash scripts/deploy_dashboard_servidor.sh
```

## Verificar estado de un chat

```sql
SELECT
  id,
  phone,
  current_hotel_id,
  cotizador_sent_at,
  flor_paused_until,
  last_human_outbound_at,
  updated_at
FROM whatsapp_chats
WHERE phone LIKE '%2944%'
ORDER BY updated_at DESC
LIMIT 5;
```

## RAM que sigue existiendo (cache, no fuente de verdad)

| Mapa | Rol ahora |
|------|-----------|
| `florSessionByPhone` | Cache de turnos recientes (fallback si falla BD) |
| `florLastHotelByPhone` | Cache sincronizada desde `current_hotel_id` |
| `florPauseMemoryUntil` | Cache rápida de silencio (DB es autoritativa) |

Tras reinicio del servidor, Flor recupera hotel, cotizador y silencio desde Supabase.
