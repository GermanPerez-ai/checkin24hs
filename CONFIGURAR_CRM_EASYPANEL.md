# Configurar CRM en EasyPanel (crm.checkin24hs.com)

## Archivos Necesarios

El CRM necesita estos archivos en el mismo directorio:
- `crm.html` (ya existe en `deploy/crm.html`)
- `crm.js` (ya existe en `deploy/crm.js`)
- `serve-crm.js` (ya creado)
- `supabase-client.js` (copiar desde `deploy/` o raíz)
- `supabase-config.js` (copiar desde `deploy/` o raíz)
- `flor-knowledge-base.js` (ya existe en `deploy/`)
- `flor-ai-service.js` (ya existe en `deploy/`)
- `flor-learning-system.js` (ya existe en `deploy/`)
- `flor-agent.js` (ya existe en `deploy/`)
- `logo.png` o logos SVG

## Pasos para Configurar

### 1. Subir archivos al servidor

```bash
# Desde tu máquina local, subir archivos al servidor
scp deploy/crm.html root@72.61.58.240:/root/checkin24hs/crm/
scp deploy/crm.js root@72.61.58.240:/root/checkin24hs/crm/
scp serve-crm.js root@72.61.58.240:/root/checkin24hs/crm/
scp deploy/supabase-client.js root@72.61.58.240:/root/checkin24hs/crm/
scp deploy/supabase-config.js root@72.61.58.240:/root/checkin24hs/crm/
scp deploy/flor-*.js root@72.61.58.240:/root/checkin24hs/crm/
scp deploy/logo.png root@72.61.58.240:/root/checkin24hs/crm/
```

### 2. Crear servicio en EasyPanel

1. **Ir a EasyPanel** → Proyecto `checkin24hs`
2. **Crear nuevo servicio:**
   - Nombre: `crm`
   - Tipo: **Static Site** o **Node.js**
   - Si es Node.js:
     - Comando: `node serve-crm.js`
     - Puerto: `3005` (3000=dashboard, 3001-3004=WhatsApp)
   - Source: GitHub
     - Repositorio: `GermanPerez-ai/checkin24hs`
     - Rama: `main`
     - Build Path: `deploy` (o crear carpeta `crm`)

### 3. Configurar dominio

1. En EasyPanel, agregar dominio: `crm.checkin24hs.com`
2. EasyPanel debería configurar Traefik automáticamente

### 4. Si Traefik no se configura automáticamente

Ejecutar en el servidor:

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.crm.entrypoints=web" \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  crm
```

### 5. Verificar que Traefik esté en la misma red

```bash
# Verificar red de Traefik
docker service inspect traefik | grep -A 10 Networks

# Verificar red del servicio CRM
docker service inspect crm | grep -A 10 Networks

# Si no están en la misma red, agregar CRM a la red de Traefik
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
docker service update --network-add $EASYPANEL_NET crm
```

## Verificación

Después de configurar:

1. Acceder a `http://crm.checkin24hs.com`
2. Verificar que cargue correctamente
3. Probar las pestañas:
   - Interacciones
   - Chats
   - Flor IA

## Ventajas

✅ Dashboard principal (`dashboard.checkin24hs.com`) funcionará sin errores  
✅ CRM (`crm.checkin24hs.com`) será independiente  
✅ Errores en CRM no afectarán el dashboard principal  
✅ Más fácil de mantener y depurar  

