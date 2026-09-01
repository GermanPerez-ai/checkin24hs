# Fix Baileys — “Esperando mensaje” / sockets duplicados (sep 2026)

## Hallazgos

1. **Baileys desactualizado**: `package.json` tenía `^6.7.9`. Última estable 6.x: **6.7.24**. (v7 es RC + ESM, migración grande; no ahora.)
2. **Bug de concurrencia en reconnect**: cada `connection.close` llamaba `connectToWhatsApp()` **sin cerrar el socket anterior** y podía apilar varios `setTimeout` → **2 WebSockets con la misma auth** → Bad MAC / “Esperando mensaje”.
3. **uncaughtException 428**: `Connection Closed` mataba Node → Swarm recreaba el task mientras otro aún vivía → otra vez doble sesión.
4. **Event loop**: bajo picos, `messages.upsert` no cedía el loop; ahora hace `setImmediate` al entrar.

## Fix en código

- Mutex `waIsConnecting` + generación `waConnectGeneration`
- `safeEndWhatsAppSocket()` antes de cada connect
- Un solo `scheduleWaReconnect()` (cancela timers previos)
- Ignorar eventos de sockets obsoletos
- No exit en uncaught 428
- Pin `@whiskeysockets/baileys@6.7.24`

## Deploy (servidor)

```bash
cd /root/checkin24hs
git pull origin main

# Build imagen nueva (sin caché para forzar npm install 6.7.24)
docker build --no-cache -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/

# Actualizar L3 y L4 (stop-first = un solo contenedor)
docker service update --image easypanel/checkin24hs/whatsapp:latest --update-order stop-first --force checkin24hs_whatsapp3
docker service update --image easypanel/checkin24hs/whatsapp:latest --update-order stop-first --force checkin24hs_whatsapp4

# Verificar versión en logs
docker service logs checkin24hs_whatsapp3 --tail 30 2>&1 | grep -E 'Baileys|gen='

# Si hace falta QR de nuevo:
bash scripts/reparar_whatsapp_linea_servidor.sh 3 --hard
bash scripts/reparar_whatsapp_linea_servidor.sh 4 --hard
```

En logs al arrancar debe verse: `📦 @whiskeysockets/baileys instalado: v6.7.24`

## Prueba

1. Solo 1 task Running por línea (`docker service ps …`)
2. En el celular: un solo dispositivo vinculado (Baileys)
3. Chat **nuevo** (borrado o número de prueba) → `hola`
4. Si falla:  
   `docker service logs checkin24hs_whatsapp3 --tail 80 | grep -E 'JID final|@lid|message not available|Reconexión|gen='`
