# Guía Completa: Configurar WhatsApp 1-4

## Objetivo
Configurar 4 servicios de WhatsApp con dominios:
- `whatsapp1.checkin24hs.com` (puerto 3001)
- `whatsapp2.checkin24hs.com` (puerto 3002)
- `whatsapp3.checkin24hs.com` (puerto 3003)
- `whatsapp4.checkin24hs.com` (puerto 3004)

## Paso 1: Subir Scripts al Servidor

Desde tu máquina Windows, ejecuta:

```powershell
# Subir scripts individualmente
scp VERIFICAR_SERVICIOS_Y_CREAR_WHATSAPP1.sh root@72.61.58.240:/root/checkin24hs/
scp CREAR_SERVICIOS_WHATSAPP_COMPLETO.sh root@72.61.58.240:/root/checkin24hs/
scp CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh root@72.61.58.240:/root/checkin24hs/
```

O ejecuta el script PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File .\SUBIR_SCRIPTS_WHATSAPP.ps1
```

## Paso 2: Verificar Estado Actual

En el servidor, ejecuta:

```bash
cd /root/checkin24hs
chmod +x *.sh
bash CREAR_SERVICIOS_WHATSAPP_COMPLETO.sh
```

Este script mostrará:
- Qué servicios existen
- Qué puertos están en uso
- Qué falta configurar

## Paso 3: Crear Servicios en EasyPanel

Para cada servicio (whatsapp1, whatsapp2, whatsapp3, whatsapp4):

### Configuración Común:

1. **Ve a EasyPanel** → **Projects** → **checkin24hs** → **New Service**
2. **Nombre del servicio**: `whatsapp1` (o whatsapp2, whatsapp3, whatsapp4)
3. **Tipo**: `App`

### Source (Fuente):
```
Tipo: GitHub
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main
Ruta de compilación: /whatsapp-server
```

### Variables de Entorno:

**Para whatsapp1 (puerto 3001):**
```
INSTANCE_NUMBER=1
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

**Para whatsapp2 (puerto 3002):**
```
INSTANCE_NUMBER=2
PORT=3002
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

**Para whatsapp3 (puerto 3003):**
```
INSTANCE_NUMBER=3
PORT=3003
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

**Para whatsapp4 (puerto 3004):**
```
INSTANCE_NUMBER=4
PORT=3004
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

### Puerto:
```
Protocolo: TCP
Publicado: [3001, 3002, 3003, 3004 según el servicio]
Destino: [3001, 3002, 3003, 3004 según el servicio]
```

### Build:
```
Comando de inicio: node whatsapp-server.js
```

### Guardar y Deploy
- Guarda la configuración
- Haz Deploy del servicio
- Verifica que esté en estado "Running" (verde)

## Paso 4: Configurar Traefik

Una vez que los 4 servicios estén corriendo, ejecuta en el servidor:

```bash
bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
```

Este script:
- Detecta los 4 servicios
- Los agrega a la red `easypanel`
- Configura las etiquetas Traefik para cada uno
- Verifica la configuración

## Paso 5: Configurar DNS

En tu proveedor de DNS, agrega 4 registros **A**:

| Nombre | Tipo | Valor | TTL |
|--------|------|-------|-----|
| whatsapp1 | A | 72.61.58.240 | 3600 |
| whatsapp2 | A | 72.61.58.240 | 3600 |
| whatsapp3 | A | 72.61.58.240 | 3600 |
| whatsapp4 | A | 72.61.58.240 | 3600 |

## Paso 6: Verificación

Después de configurar todo, verifica:

```bash
# Ver servicios corriendo
docker service ls | grep whatsapp

# Ver logs de cada servicio
docker service logs whatsapp1 --tail 20
docker service logs whatsapp2 --tail 20
docker service logs whatsapp3 --tail 20
docker service logs whatsapp4 --tail 20

# Probar conexión directa
curl -I http://localhost:3001
curl -I http://localhost:3002
curl -I http://localhost:3003
curl -I http://localhost:3004

# Verificar Traefik
docker service logs traefik --tail 50 | grep whatsapp

# Probar dominios (después de propagación DNS)
curl -I https://whatsapp1.checkin24hs.com
curl -I https://whatsapp2.checkin24hs.com
curl -I https://whatsapp3.checkin24hs.com
curl -I https://whatsapp4.checkin24hs.com
```

## Notas Importantes

- ⏱️ **DNS**: Puede tardar hasta 24 horas en propagarse (normalmente es más rápido)
- 🔒 **SSL**: Los certificados se generarán automáticamente con Let's Encrypt (puede tardar unos minutos)
- 🌐 **Red**: Los servicios deben estar en la red `easypanel` para que Traefik los detecte
- 📝 **Logs**: Revisa los logs si algo no funciona: `docker service logs <nombre_servicio>`

## Resumen de Archivos Creados

1. `CREAR_SERVICIOS_WHATSAPP_COMPLETO.sh` - Verifica estado actual
2. `CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh` - Configura Traefik para los 4 servicios
3. `SUBIR_SCRIPTS_WHATSAPP.ps1` - Script PowerShell para subir archivos






