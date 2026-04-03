# 📋 Aplicar Corrección de Chats - Desde Terminal SSH

## 🎯 Objetivo

Aplicar la corrección del archivo `whatsapp-server-baileys.js` directamente desde la terminal SSH del servidor.

---

## ✅ Paso 1: Subir Archivo al Servidor (desde PowerShell local)

**Abre PowerShell en tu máquina local y ejecuta:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp whatsapp-server\whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js
```

**Se te pedirá la contraseña SSH.** Ingresa tu contraseña.

**Resultado esperado:** `whatsapp-server-baileys.js 100% XXXX KB ...`

---

## ✅ Paso 2: Conectar al Servidor por SSH

**Abre la terminal SSH de Hostinger o ejecuta:**

```powershell
ssh root@72.61.58.240
```

---

## ✅ Paso 3: Aplicar Corrección en el Servidor

**Una vez conectado al servidor, ejecuta estos comandos:**

```bash
# 1. Buscar el contenedor de WhatsApp
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

# 2. Verificar que se encontró
if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor encontrado: $CONTAINER_ID"

# 3. Hacer backup del archivo actual
echo "Haciendo backup..."
docker exec $CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)

# 4. Copiar archivo corregido al contenedor
echo "Copiando archivo corregido..."
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js

# 5. Reiniciar contenedor
echo "Reiniciando contenedor..."
docker restart $CONTAINER_ID

echo "OK: Archivo aplicado y contenedor reiniciado"
```

---

## ✅ Paso 4: Verificar Logs

**Espera 10-15 segundos y luego ejecuta:**

```bash
# Ver logs del contenedor
docker logs $CONTAINER_ID --tail 30 | grep -E "(Iniciando|chat|conversation|error|✅|❌)"
```

**O ver todos los logs recientes:**

```bash
docker logs $CONTAINER_ID --tail 50
```

**Busca mensajes como:**
- `✅ Nuevo chat creado en whatsapp_chats`
- `✅ Chat existente encontrado en whatsapp_chats`
- `✅ Mensaje guardado en whatsapp_messages`
- `✅ Chat actualizado en whatsapp_chats`

---

## ✅ Paso 5: Probar

1. **Envía un mensaje de prueba a Flor por WhatsApp**
2. **Espera 5-10 segundos**
3. **Abre el dashboard:** `https://dashboard.checkin24hs.com/`
4. **Ve a la sección "Chats"**
5. **Haz clic en "Actualizar"**
6. **Debe aparecer el contacto y la conversación**

---

## 📝 Comandos Completos (Copia y Pega)

### Desde PowerShell (local):

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp whatsapp-server\whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js
```

### Desde Terminal SSH (servidor):

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
echo "Contenedor: $CONTAINER_ID"
docker exec $CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js
docker restart $CONTAINER_ID
echo "OK: Corrección aplicada"
```

---

## ❌ Si Hay Problemas

### Error: "No se encontro contenedor"

**Verifica que el contenedor esté corriendo:**

```bash
docker ps | grep whatsapp
```

### Error: "No such file or directory"

**Verifica que el archivo se haya subido correctamente:**

```bash
ls -lh /tmp/whatsapp-server-baileys.js
```

### Error: "Permission denied"

**Verifica que tengas permisos de root o usa `sudo`:**

```bash
sudo docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js
```

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
