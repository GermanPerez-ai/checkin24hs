# Instrucciones para Aplicar Correcciones del Dashboard

## Correcciones Aplicadas

1. ✅ **loadWhatsAppCards**: Comentada la asignación global (función deshabilitada)
2. ✅ **Mixed Content**: Cambiados iframes de HTTP a HTTPS
   - `http://72.61.58.240:3001/` → `https://whatsapp1.checkin24hs.com/`
   - `http://72.61.58.240:3002/` → `https://whatsapp2.checkin24hs.com/`
   - `http://72.61.58.240:3003/` → `https://whatsapp3.checkin24hs.com/`
   - `http://72.61.58.240:3004/` → `https://whatsapp4.checkin24hs.com/`

## Pasos para Aplicar

### Opción 1: Desde Windows (PowerShell)

1. **Subir archivo al servidor:**
```powershell
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/
```

2. **Conectarse al servidor:**
```bash
ssh root@72.61.58.240
```

3. **Ejecutar script de aplicación:**
```bash
cd /root/checkin24hs
chmod +x APLICAR_CORRECCIONES_SERVIDOR.sh
./APLICAR_CORRECCIONES_SERVIDOR.sh
```

### Opción 2: Manualmente en el Servidor

```bash
# 1. Verificar que el archivo existe
ls -lh /root/checkin24hs/deploy/dashboard.html

# 2. Obtener contenedor
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
echo "Contenedor: $CONTAINER_ID"

# 3. Copiar archivo
docker cp /root/checkin24hs/deploy/dashboard.html $CONTAINER_ID:/app/dashboard.html

# 4. Verificar correcciones
docker exec $CONTAINER_ID grep -n "// window.loadWhatsAppCards" /app/dashboard.html | head -1
docker exec $CONTAINER_ID grep -n "whatsapp1.checkin24hs.com" /app/dashboard.html | head -1
```

## Verificación

Después de aplicar:

1. **Recargar Dashboard** con `Ctrl+F5` (forzar recarga sin caché)
2. **Abrir consola** (F12)
3. **Verificar que NO aparezcan:**
   - ❌ `ReferenceError: loadWhatsAppCards is not defined`
   - ❌ `Mixed Content` warnings para los iframes de WhatsApp

## ⚠️ Importante: Configurar Dominios HTTPS

Para que los iframes de WhatsApp funcionen, necesitas configurar en Traefik:

1. **Registros DNS** (A o CNAME):
   - `whatsapp1.checkin24hs.com` → `72.61.58.240`
   - `whatsapp2.checkin24hs.com` → `72.61.58.240`
   - `whatsapp3.checkin24hs.com` → `72.61.58.240`
   - `whatsapp4.checkin24hs.com` → `72.61.58.240`

2. **Configurar Traefik** para cada servicio WhatsApp (ejemplo para whatsapp1):
```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp1.rule=Host(\`whatsapp1.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp1.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp1.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp1.loadbalancer.server.port=3001" \
  checkin24hs_whatsapp1
```

Si no configuras los dominios HTTPS, los iframes mostrarán errores pero **no afectarán el resto del Dashboard**.






