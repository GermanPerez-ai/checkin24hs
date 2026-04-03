# 📤 Subir Archivo Correcto al Servidor

## ⚠️ El archivo en el servidor está desactualizado

El archivo local tiene los cambios, pero el servidor tiene una versión antigua.

---

## Paso 1: Desde PowerShell en Windows

**Abre PowerShell y navega al proyecto:**

```powershell
cd c:\Users\German\Downloads\Checkin24hs
```

**Sube el archivo actualizado:**

```powershell
scp whatsapp-server\whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js
```

Ingresa la contraseña cuando se solicite.

---

## Paso 2: En el servidor, verifica que se subió correctamente

**Conecta al servidor:**

```powershell
ssh root@72.61.58.240
```

**Verifica que el archivo tiene los cambios:**

```bash
# Verificar que tiene el código nuevo
grep -A 5 "Error creando chat en whatsapp_chats" /tmp/whatsapp-server-baileys.js | head -10
```

**Deberías ver:**
- `console.error('❌ Error creando chat en whatsapp_chats:'`
- `console.error('   ⚠️ PROBLEMA: Supabase está bloqueando la creación por cuota excedida'`

---

## Paso 3: Aplica el archivo al contenedor

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

# Crear backup
docker cp $CONTAINER_ID:/app/whatsapp-server-baileys.js /tmp/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)

# Copiar archivo actualizado
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js

# Verificar que se aplicó
docker exec $CONTAINER_ID grep -A 5 "Error creando chat en whatsapp_chats" /app/whatsapp-server-baileys.js | head -10

# Reiniciar contenedor
docker restart $CONTAINER_ID
```

---

## Verificar después de aplicar

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
docker exec $CONTAINER_ID grep -A 2 "PROBLEMA.*cuota" /app/whatsapp-server-baileys.js
```

**Deberías ver:**
```
console.error('   ⚠️ PROBLEMA: Supabase está bloqueando la creación por cuota excedida');
```
