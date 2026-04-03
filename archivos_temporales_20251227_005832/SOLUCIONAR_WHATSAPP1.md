# Solucionar whatsapp1.checkin24hs.com

## Problema
El dominio `http://whatsapp1.checkin24hs.com/` no funciona.

## Diagnóstico Paso a Paso

### 1. Verificar DNS
```bash
nslookup whatsapp1.checkin24hs.com
# Debe apuntar a 72.61.58.240
```

Si no está configurado:
- Ve a tu proveedor de DNS
- Agrega registro A: `whatsapp1.checkin24hs.com` → `72.61.58.240`

### 2. Verificar Servicio de WhatsApp
```bash
# Ver todos los servicios
docker service ls

# Ver contenedores de WhatsApp
docker ps | grep -i whatsapp

# Ver si hay algo en puerto 3001
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 3001
```

### 3. Verificar si el Servicio Existe
```bash
# Buscar servicios relacionados con WhatsApp
docker service ls | grep -i whatsapp
docker service ls | grep 3001
```

### 4. Probar Conexión Directa
```bash
# Desde el servidor
curl -I http://localhost:3001
curl -I http://72.61.58.240:3001

# Ver logs si hay servicio
docker service logs <nombre_servicio_whatsapp> --tail 20
```

## Soluciones Posibles

### Opción A: El Servicio No Existe
Si no hay servicio de WhatsApp corriendo:

1. **Crear servicio en EasyPanel:**
   - Nombre: `whatsapp1` o `checkin24hs_whatsapp1`
   - Puerto interno: `3001`
   - Imagen: La misma que usa WhatsApp actualmente
   - Variables de entorno: `PORT=3001`

2. **Configurar Traefik:**
```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp1.rule=Host(\`whatsapp1.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp1.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp1.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp1.loadbalancer.server.port=3001" \
  <nombre_servicio_whatsapp1>
```

### Opción B: El Servicio Existe pero Traefik No lo Detecta
Si el servicio existe pero Traefik no lo enruta:

```bash
# Ver configuración actual
docker service inspect <nombre_servicio_whatsapp1> --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# Agregar etiquetas Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp1.rule=Host(\`whatsapp1.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp1.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp1.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp1.loadbalancer.server.port=3001" \
  <nombre_servicio_whatsapp1>
```

### Opción C: El Servicio Está en Puerto Incorrecto
Si el servicio está corriendo pero en otro puerto:

```bash
# Ver en qué puerto está corriendo
docker service inspect <nombre_servicio> --format '{{json .Endpoint.Ports}}'

# Actualizar puerto en Traefik
docker service update \
  --label-add "traefik.http.services.whatsapp1.loadbalancer.server.port=<puerto_correcto>" \
  <nombre_servicio_whatsapp1>
```

## Verificación Final

Después de aplicar la solución:

```bash
# 1. Verificar que Traefik detecta el servicio
docker service logs traefik --tail 50 | grep -i whatsapp1

# 2. Probar desde el servidor
curl -I https://whatsapp1.checkin24hs.com

# 3. Verificar certificado SSL
curl -v https://whatsapp1.checkin24hs.com 2>&1 | grep -i "certificate\|ssl"
```

## Notas Importantes

- El dominio debe usar **HTTPS** (no HTTP) porque Traefik está configurado con SSL
- El certificado SSL se generará automáticamente con Let's Encrypt
- Puede tardar unos minutos en propagarse el DNS y generar el certificado






