# Resumen: Crear Servicios WhatsApp 1-4

## Estado Actual ✅
- ✅ Archivos de WhatsApp existen en el servidor (`whatsapp-server.js`)
- ✅ Scripts de verificación funcionando
- ❌ No hay servicios de WhatsApp corriendo
- ❌ DNS no configurado

## Pasos Siguientes

### 1. Crear los 4 Servicios en EasyPanel

Ve a **EasyPanel** → **Projects** → **checkin24hs** → **New Service** (4 veces)

#### Servicio 1: whatsapp1
```
Nombre: whatsapp1
Source: GitHub → GermanPerez-ai → checkin24hs → /whatsapp-server
Variables:
  INSTANCE_NUMBER=1
  PORT=3001
  SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
  SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
Puerto: 3001 (interno y externo)
Comando: node whatsapp-server.js
```

#### Servicio 2: whatsapp2
```
Nombre: whatsapp2
Source: GitHub → GermanPerez-ai → checkin24hs → /whatsapp-server
Variables:
  INSTANCE_NUMBER=2
  PORT=3002
  SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
  SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
Puerto: 3002 (interno y externo)
Comando: node whatsapp-server.js
```

#### Servicio 3: whatsapp3
```
Nombre: whatsapp3
Source: GitHub → GermanPerez-ai → checkin24hs → /whatsapp-server
Variables:
  INSTANCE_NUMBER=3
  PORT=3003
  SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
  SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
Puerto: 3003 (interno y externo)
Comando: node whatsapp-server.js
```

#### Servicio 4: whatsapp4
```
Nombre: whatsapp4
Source: GitHub → GermanPerez-ai → checkin24hs → /whatsapp-server
Variables:
  INSTANCE_NUMBER=4
  PORT=3004
  SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
  SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
Puerto: 3004 (interno y externo)
Comando: node whatsapp-server.js
```

### 2. Verificar que los Servicios Están Corriendo

En EasyPanel, verifica que los 4 servicios estén en estado **"Running"** (verde).

### 3. Configurar Traefik

Una vez que los 4 servicios estén corriendo, ejecuta en el servidor:

```bash
cd /root/checkin24hs
chmod +x CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
```

### 4. Configurar DNS

En tu proveedor de DNS, agrega estos 4 registros **A**:

| Nombre | Tipo | Valor | TTL |
|--------|------|-------|-----|
| whatsapp1 | A | 72.61.58.240 | 3600 |
| whatsapp2 | A | 72.61.58.240 | 3600 |
| whatsapp3 | A | 72.61.58.240 | 3600 |
| whatsapp4 | A | 72.61.58.240 | 3600 |

### 5. Verificación Final

Después de configurar todo, ejecuta:

```bash
# Ver servicios
docker service ls | grep whatsapp

# Ver logs
docker service logs whatsapp1 --tail 10
docker service logs whatsapp2 --tail 10
docker service logs whatsapp3 --tail 10
docker service logs whatsapp4 --tail 10

# Probar conexión
curl -I http://localhost:3001
curl -I http://localhost:3002
curl -I http://localhost:3003
curl -I http://localhost:3004
```

## Notas Importantes

- ⏱️ **DNS**: Puede tardar hasta 24 horas en propagarse
- 🔒 **SSL**: Los certificados se generarán automáticamente
- 🌐 **Red**: Los servicios deben estar en la red `easypanel`
- 📝 **Logs**: Revisa los logs si algo no funciona






