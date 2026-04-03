# 🔧 Solución: Probar con IPs del Contenedor

## ✅ Diagnóstico

- ✅ El servidor está escuchando en `0.0.0.0:3000` dentro del contenedor
- ✅ El contenedor tiene IPs en dos redes
- ❌ El puerto 3000 no está expuesto en `NetworkSettings.Ports` (solo está el 30000)

## 🔍 Verificar IPs y Probar

```bash
# 1. Obtener el ID del contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}')
echo "Container ID: $CONTAINER_ID"

# 2. Ver todas las IPs del contenedor
docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{$value.IPAddress}}{{"\n"}}{{end}}'

# 3. Obtener la IP de la red easypanel (donde está Traefik)
EASYPANEL_IP=$(docker inspect $CONTAINER_ID --format '{{index .NetworkSettings.Networks "easypanel" | .IPAddress}}')
echo "IP en red easypanel: $EASYPANEL_IP"

# 4. Probar con la IP de la red easypanel
curl http://$EASYPANEL_IP:3000 | head -20

# 5. Probar desde Traefik usando la IP directa
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://$EASYPANEL_IP:3000 2>&1 | head -20

# 6. Verificar la configuración de puertos del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq
```

## 🎯 Solución Alternativa: Exponer el Puerto 3000 Internamente

Si el modo ingress no expone el puerto internamente, podemos agregar el puerto 3000 en modo host (pero en un puerto diferente para evitar conflicto):

```bash
# Agregar puerto 30001 en modo host -> 3000 interno
docker service update \
  --publish-add published=30001,target=3000,protocol=tcp,mode=host \
  checkin24hs_dashboard

# Esperar
sleep 5

# Probar
curl http://localhost:30001 | head -20
```

## 📋 Nota sobre Modo Ingress

En modo ingress, el puerto publicado (30000) es para acceso externo. Para acceso interno desde la red Docker Swarm, necesitamos usar la IP del contenedor directamente o configurar el servicio para que exponga el puerto internamente.

