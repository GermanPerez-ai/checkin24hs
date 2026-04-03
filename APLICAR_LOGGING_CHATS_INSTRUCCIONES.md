# 📋 Instrucciones: Aplicar Logging Mejorado de Chats

## ⚠️ IMPORTANTE: Ejecutar desde tu máquina Windows

Los comandos `scp` deben ejecutarse desde tu máquina local (PowerShell), NO desde el servidor.

---

## Paso 1: Desde PowerShell en Windows

**Abre PowerShell en tu máquina Windows y navega al proyecto:**

```powershell
cd c:\Users\German\Downloads\Checkin24hs
```

**Sube el archivo al servidor:**

```powershell
scp whatsapp-server\whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js
```

Ingresa la contraseña cuando se solicite.

---

## Paso 2: Conecta al servidor

**Ahora sí, conecta al servidor:**

```powershell
ssh root@72.61.58.240
```

---

## Paso 3: En el servidor, aplica los cambios

**Una vez conectado al servidor, ejecuta:**

```bash
# Buscar contenedor
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

# Verificar que el archivo existe
ls -lh /tmp/whatsapp-server-baileys.js

# Crear backup
docker cp $CONTAINER_ID:/app/whatsapp-server-baileys.js /tmp/whatsapp-server-baileys.js.backup.$(date +%Y%m%d_%H%M%S)

# Copiar archivo al contenedor
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js

# Verificar cambio
docker exec $CONTAINER_ID grep -A 2 "Error creando chat en whatsapp_chats" /app/whatsapp-server-baileys.js | head -5

# Reiniciar contenedor
docker restart $CONTAINER_ID
```

---

## Resumen de comandos

### En Windows PowerShell:
```powershell
cd c:\Users\German\Downloads\Checkin24hs
scp whatsapp-server\whatsapp-server-baileys.js root@72.61.58.240:/tmp/whatsapp-server-baileys.js
ssh root@72.61.58.240
```

### En el servidor (después de conectar):
```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js
docker restart $CONTAINER_ID
```

---

## Verificar después de aplicar

**En el servidor, después de enviar un mensaje de prueba:**

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
docker logs $CONTAINER_ID --tail 100 | grep -E "Error creando chat|Nuevo chat creado|PROBLEMA.*cuota"
```
