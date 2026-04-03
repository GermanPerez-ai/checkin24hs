# Verificar whatsapp1.checkin24hs.com

## Problema
El dominio `http://whatsapp1.checkin24hs.com/` no funciona.

## Pasos de Diagnóstico

### 1. Verificar DNS
```bash
nslookup whatsapp1.checkin24hs.com
# Debe apuntar a 72.61.58.240
```

### 2. Verificar Servicio Docker
```bash
# Ver servicios de WhatsApp
docker service ls | grep -i whatsapp
docker ps | grep -i whatsapp

# Ver si hay algo en puerto 3001
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 3001
```

### 3. Verificar Traefik
```bash
# Ver si Traefik tiene configuración para whatsapp1
docker service inspect <servicio_whatsapp> --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik
```

### 4. Probar Conexión Directa
```bash
# Desde el servidor
curl -I http://localhost:3001
curl -I http://72.61.58.240:3001

# Desde fuera
curl -I http://whatsapp1.checkin24hs.com
```

## Posibles Soluciones

### Opción 1: Configurar Traefik para whatsapp1
Si el servicio de WhatsApp está corriendo pero Traefik no lo detecta:

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp1.rule=Host(\`whatsapp1.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp1.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp1.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp1.loadbalancer.server.port=3001" \
  <nombre_servicio_whatsapp>
```

### Opción 2: Crear Servicio de WhatsApp si no existe
Si no hay servicio de WhatsApp corriendo, necesitamos crearlo.

### Opción 3: Verificar DNS
Si el DNS no está configurado, agregar registro A:
- `whatsapp1.checkin24hs.com` → `72.61.58.240`






