# 📋 Aplicar Corrección de Chats - Paso a Paso (PowerShell)

## 🎯 Objetivo

Aplicar la corrección del archivo `whatsapp-server-baileys.js` al servidor usando PowerShell desde tu máquina local.

---

## ✅ Paso 1: Verificar Archivo Local

**Abre PowerShell y ejecuta:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs
Test-Path "whatsapp-server\whatsapp-server-baileys.js"
```

**Debe mostrar:** `True`

---

## ✅ Paso 2: Subir Archivo al Servidor

**Ejecuta:**

```powershell
scp whatsapp-server\whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js
```

**Se te pedirá la contraseña SSH.** Ingresa tu contraseña.

**Resultado esperado:** `whatsapp-server-baileys.js 100% XXXX KB ...`

---

## ✅ Paso 3: Aplicar en el Contenedor

**Ejecuta este comando (se te pedirá la contraseña SSH nuevamente):**

```powershell
ssh root@72.61.58.240 "CONTAINER_ID=`$(docker ps | grep whatsapp | grep -v nginx | awk '{print `$1}' | head -1); if [ -z `$CONTAINER_ID ]; then echo 'ERROR: No se encontro contenedor'; exit 1; fi; echo 'Contenedor: '`$CONTAINER_ID; docker exec `$CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.`$(date +%Y%m%d_%H%M%S); docker cp /tmp/whatsapp-server-baileys.js `$CONTAINER_ID:/app/whatsapp-server-baileys.js; docker restart `$CONTAINER_ID; echo 'OK: Archivo aplicado y contenedor reiniciado'"
```

**O usa el script automático:**

```powershell
.\APLICAR_CORRECCION_CHATS.ps1
```

---

## ✅ Paso 4: Verificar Logs

**Espera 10-15 segundos y luego ejecuta:**

```powershell
ssh root@72.61.58.240 "CONTAINER_ID=`$(docker ps | grep whatsapp | grep -v nginx | awk '{print `$1}' | head -1); docker logs `$CONTAINER_ID --tail 30 | grep -E '(Iniciando|chat|conversation|error|✅|❌)'"
```

**Busca mensajes como:**
- `✅ Nuevo chat creado en whatsapp_chats`
- `✅ Chat existente encontrado en whatsapp_chats`
- `✅ Mensaje guardado en whatsapp_messages`

---

## ✅ Paso 5: Probar

1. **Envía un mensaje de prueba a Flor por WhatsApp**
2. **Espera 5-10 segundos**
3. **Abre el dashboard:** `https://dashboard.checkin24hs.com/`
4. **Ve a la sección "Chats"**
5. **Haz clic en "Actualizar"**
6. **Debe aparecer el contacto y la conversación**

---

## 🔍 Verificar en Supabase (Opcional)

**En Supabase SQL Editor, ejecuta:**

```sql
-- Ver últimos chats creados
SELECT id, phone, name, last_message, last_message_time, created_at
FROM whatsapp_chats
ORDER BY created_at DESC
LIMIT 5;

-- Ver últimos mensajes
SELECT id, chat_id, phone, LEFT(message, 50) as mensaje, is_from_me, created_at
FROM whatsapp_messages
ORDER BY created_at DESC
LIMIT 5;
```

---

## ❌ Si Hay Problemas

### Error: "No se encontro contenedor"

**Verifica que el contenedor esté corriendo:**

```powershell
ssh root@72.61.58.240 "docker ps | grep whatsapp"
```

### Error: "Permission denied"

**Verifica que tengas acceso SSH al servidor.**

### Error: "No such file or directory"

**Verifica que el archivo se haya subido correctamente:**

```powershell
ssh root@72.61.58.240 "ls -lh /tmp/whatsapp-server-baileys.js"
```

---

## 📝 Comandos Completos (Copia y Pega)

### Opción A: Manual

```powershell
# 1. Ir al directorio
cd C:\Users\German\Downloads\Checkin24hs

# 2. Subir archivo
scp whatsapp-server\whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js

# 3. Aplicar en contenedor
ssh root@72.61.58.240 "CONTAINER_ID=`$(docker ps | grep whatsapp | grep -v nginx | awk '{print `$1}' | head -1); docker exec `$CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.`$(date +%Y%m%d_%H%M%S); docker cp /tmp/whatsapp-server-baileys.js `$CONTAINER_ID:/app/whatsapp-server-baileys.js; docker restart `$CONTAINER_ID; echo 'OK'"

# 4. Verificar (espera 10 segundos primero)
Start-Sleep -Seconds 10
ssh root@72.61.58.240 "CONTAINER_ID=`$(docker ps | grep whatsapp | grep -v nginx | awk '{print `$1}' | head -1); docker logs `$CONTAINER_ID --tail 20"
```

### Opción B: Script Automático

```powershell
cd C:\Users\German\Downloads\Checkin24hs
.\APLICAR_CORRECCION_CHATS.ps1
```
