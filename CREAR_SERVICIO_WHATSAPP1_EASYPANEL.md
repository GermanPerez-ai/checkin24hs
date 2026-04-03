# Crear Servicio WhatsApp1 en EasyPanel

## Problema Actual
- No hay servicio de WhatsApp corriendo
- El dominio `whatsapp1.checkin24hs.com` no funciona
- No hay contenedores en puerto 3001

## Solución: Crear Servicio en EasyPanel

### Paso 1: Crear Nuevo Servicio en EasyPanel

1. **Ve a EasyPanel** → **Projects** → **checkin24hs** → **New Service**
2. **Nombre del servicio**: `whatsapp1` o `checkin24hs_whatsapp1`
3. **Tipo**: `App` (aplicación Node.js)

### Paso 2: Configurar Source (Fuente)

```
Tipo: GitHub
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main
Ruta de compilación: /whatsapp-server
```

⚠️ **IMPORTANTE**: La ruta debe ser `/whatsapp-server` (con barra inicial, sin barra final)

### Paso 3: Configurar Variables de Entorno

```
INSTANCE_NUMBER=1
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

### Paso 4: Configurar Puerto

```
Protocolo: TCP
Publicado: 3001
Destino: 3001
```

### Paso 5: Configurar Build

```
Comando de inicio: node whatsapp-server.js
```

### Paso 6: Configurar Dominio (Opcional - se puede hacer después)

```
Dominio: whatsapp1.checkin24hs.com
Puerto: 3001
```

### Paso 7: Guardar y Deploy

1. **Guardar** la configuración
2. **Deploy** el servicio
3. **Verificar** que esté en estado "Running" (verde)

## Paso 8: Configurar Traefik (Después de crear el servicio)

Una vez que el servicio esté corriendo, ejecuta en el servidor:

```bash
# Reemplazar <nombre_servicio> con el nombre real del servicio creado
SERVICE_NAME="whatsapp1"  # o el nombre que hayas usado

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp1.rule=Host(\`whatsapp1.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp1.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp1.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp1.loadbalancer.server.port=3001" \
  --network-add easypanel \
  $SERVICE_NAME
```

## Paso 9: Configurar DNS

1. Ve a tu proveedor de DNS (donde está configurado `checkin24hs.com`)
2. Agrega registro **A**:
   - **Nombre**: `whatsapp1`
   - **Valor**: `72.61.58.240`
   - **TTL**: `3600` (o el que uses por defecto)

## Verificación

Después de crear el servicio y configurar DNS:

```bash
# 1. Verificar que el servicio está corriendo
docker service ps whatsapp1

# 2. Verificar logs
docker service logs whatsapp1 --tail 20

# 3. Probar conexión directa
curl -I http://localhost:3001

# 4. Verificar Traefik
docker service logs traefik --tail 50 | grep whatsapp1

# 5. Probar dominio (después de que DNS se propague)
curl -I https://whatsapp1.checkin24hs.com
```

## Notas Importantes

- El DNS puede tardar hasta 24 horas en propagarse (normalmente es más rápido)
- El certificado SSL se generará automáticamente con Let's Encrypt (puede tardar unos minutos)
- Asegúrate de que el servicio esté en la red `easypanel` para que Traefik lo detecte


















