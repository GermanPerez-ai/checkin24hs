# Configuración Paso a Paso: WhatsApp 1-4

## Estado Actual ✅
- ✅ Archivos de WhatsApp existen en el servidor
- ✅ Scripts de verificación creados
- ✅ Script de Traefik listo
- ❌ Servicios de WhatsApp NO creados aún
- ❌ DNS NO configurado

## Paso 1: Crear Servicios en EasyPanel

### Servicio 1: whatsapp1

1. **Ve a EasyPanel** → **Projects** → **checkin24hs** → **New Service**
2. **Nombre**: `whatsapp1`
3. **Tipo**: `App`
4. **Source**:
   ```
   Tipo: GitHub
   Propietario: GermanPerez-ai
   Repositorio: checkin24hs
   Rama: main
   Ruta de compilación: /whatsapp-server
   ```
5. **Environment Variables**:
   ```
   INSTANCE_NUMBER=1
   PORT=3001
   SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
   PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
   ```
6. **Ports**:
   ```
   Protocolo: TCP
   Publicado: 3001
   Destino: 3001
   ```
7. **Build**:
   ```
   Comando de inicio: node whatsapp-server.js
   ```
8. **Guardar y Deploy**

### Servicio 2: whatsapp2

Repite los mismos pasos pero con:
- **Nombre**: `whatsapp2`
- **INSTANCE_NUMBER=2**
- **PORT=3002**
- **Puerto**: 3002

### Servicio 3: whatsapp3

Repite los mismos pasos pero con:
- **Nombre**: `whatsapp3`
- **INSTANCE_NUMBER=3**
- **PORT=3003**
- **Puerto**: 3003

### Servicio 4: whatsapp4

Repite los mismos pasos pero con:
- **Nombre**: `whatsapp4`
- **INSTANCE_NUMBER=4**
- **PORT=3004**
- **Puerto**: 3004

## Paso 2: Verificar que los Servicios Están Corriendo

En EasyPanel, verifica que los 4 servicios estén en estado **"Running"** (verde).

O ejecuta en el servidor:
```bash
docker service ls | grep whatsapp
```

Deberías ver los 4 servicios corriendo.

## Paso 3: Configurar Traefik

Una vez que los 4 servicios estén corriendo, ejecuta en el servidor:

```bash
cd /root/checkin24hs
chmod +x CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
```

Este script:
- Detecta los 4 servicios automáticamente
- Los agrega a la red `easypanel`
- Configura las etiquetas Traefik para cada uno
- Verifica la configuración

## Paso 4: Configurar DNS

En tu proveedor de DNS (donde está configurado `checkin24hs.com`), agrega estos 4 registros **A**:

| Nombre | Tipo | Valor | TTL |
|--------|------|-------|-----|
| whatsapp1 | A | 72.61.58.240 | 3600 |
| whatsapp2 | A | 72.61.58.240 | 3600 |
| whatsapp3 | A | 72.61.58.240 | 3600 |
| whatsapp4 | A | 72.61.58.240 | 3600 |

**Nota**: El DNS puede tardar hasta 24 horas en propagarse (normalmente es más rápido, 1-2 horas).

## Paso 5: Verificación Final

Después de configurar todo, ejecuta:

```bash
# Ver servicios corriendo
docker service ls | grep whatsapp

# Ver logs de cada servicio
docker service logs whatsapp1 --tail 10
docker service logs whatsapp2 --tail 10
docker service logs whatsapp3 --tail 10
docker service logs whatsapp4 --tail 10

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

## Troubleshooting

### Si los servicios no inician:
```bash
# Ver logs de error
docker service logs whatsapp1 --tail 50

# Verificar que el archivo existe
docker exec $(docker ps | grep whatsapp1 | awk '{print $1}') ls -lh /app/whatsapp-server.js
```

### Si Traefik no detecta los servicios:
```bash
# Verificar etiquetas
docker service inspect whatsapp1 --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep traefik

# Verificar red
docker service inspect whatsapp1 --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'
```

### Si el DNS no funciona:
```bash
# Verificar DNS desde el servidor
nslookup whatsapp1.checkin24hs.com

# Debe mostrar: 72.61.58.240
```

## Próximos Pasos Después de Configurar

Una vez que todo esté funcionando:

1. **Conectar WhatsApp desde el Dashboard**
   - Ve a Dashboard → Flor IA → WhatsApp
   - Configura la URL del servidor
   - Conecta cada instancia (generar QR)

2. **Verificar que los mensajes se guardan**
   - Envía un mensaje de prueba
   - Verifica en Dashboard/CRM que aparece

3. **Configurar Flor IA para cada instancia**
   - Cada WhatsApp puede tener su propia configuración

## Notas Importantes

- ⏱️ **DNS**: Puede tardar hasta 24 horas en propagarse
- 🔒 **SSL**: Los certificados se generarán automáticamente con Let's Encrypt
- 🌐 **Red**: Los servicios deben estar en la red `easypanel` para que Traefik los detecte
- 📝 **Logs**: Revisa los logs si algo no funciona
- 🔄 **Reinicio**: Si cambias configuración, reinicia el servicio en EasyPanel


