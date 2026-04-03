# 📋 Aplicar Logging Mejorado de Chats - Paso a Paso

## Paso 1: Subir archivo al servidor

**En PowerShell (desde el directorio del proyecto):**

```powershell
scp whatsapp-server\whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js
```

Ingresa la contraseña cuando se solicite.

---

## Paso 2: Subir script bash al servidor

```powershell
scp APLICAR_LOGGING_MEJORADO_CHATS.sh root@72.61.58.240:/tmp/
```

---

## Paso 3: Ejecutar script en el servidor

**Conecta al servidor:**

```powershell
ssh root@72.61.58.240
```

**Ejecuta el script:**

```bash
chmod +x /tmp/APLICAR_LOGGING_MEJORADO_CHATS.sh
bash /tmp/APLICAR_LOGGING_MEJORADO_CHATS.sh
```

---

## Paso 4: Verificar que se aplicó

**En el servidor, verifica el código:**

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
docker exec $CONTAINER_ID grep -A 5 "Error creando chat en whatsapp_chats" /app/whatsapp-server-baileys.js
```

Deberías ver líneas como:
- `console.error('❌ Error creando chat en whatsapp_chats:'`
- `console.error('   ⚠️ PROBLEMA: Supabase está bloqueando la creación por cuota excedida'`

---

## Paso 5: Probar con un mensaje nuevo

1. **Envía un mensaje de WhatsApp al bot**
2. **Verifica los logs en el servidor:**

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
docker logs $CONTAINER_ID --tail 100 | grep -E "Error creando chat|Nuevo chat creado|PROBLEMA.*cuota|Creación de chat no devolvió"
```

---

## Qué buscar en los logs

### ✅ Si funciona:
```
✅ Nuevo chat creado en whatsapp_chats para +549...
```

### ❌ Si hay error de cuota:
```
❌ Error creando chat en whatsapp_chats: ...
   ⚠️ PROBLEMA: Supabase está bloqueando la creación por cuota excedida
```

### ⚠️ Si hay bloqueo silencioso:
```
⚠️ Creación de chat no devolvió datos (puede estar bloqueada por cuota de Supabase)
```

---

## Alternativa: Aplicar manualmente

Si prefieres hacerlo manualmente:

```bash
# 1. Buscar contenedor
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

# 2. Crear backup
docker cp $CONTAINER_ID:/app/whatsapp-server-baileys.js /tmp/whatsapp-server-baileys.js.backup

# 3. Copiar archivo
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js

# 4. Reiniciar
docker restart $CONTAINER_ID
```
