# 🔍 Diagnóstico: Puerto No Accesible desde la Red

## 🚨 Problema

- ✅ El alias `checkin24hs-dashboard` se resuelve a `10.11.52.98`
- ❌ El puerto 3000 no es accesible desde la red Docker Swarm
- ❌ Incluso desde dentro del contenedor, `localhost:3000` no responde

## 🔍 Verificaciones Necesarias

```bash
# 1. Verificar que el contenedor está corriendo
docker ps | grep checkin24hs_dashboard

# 2. Ver los logs del servicio para confirmar que está escuchando
docker service logs checkin24hs_dashboard --tail 20

# 3. Verificar qué puertos están escuchando dentro del contenedor
docker exec $(docker ps | grep checkin24hs_dashboard | awk '{print $1}') netstat -tuln | grep 3000
# O
docker exec $(docker ps | grep checkin24hs_dashboard | awk '{print $1}') ss -tuln | grep 3000

# 4. Verificar la IP del contenedor
docker inspect $(docker ps | grep checkin24hs_dashboard | awk '{print $1}') | grep -A 10 Networks

# 5. Probar desde el host usando la IP del contenedor directamente
# (Primero obtener la IP del contenedor)
CONTAINER_IP=$(docker inspect $(docker ps | grep checkin24hs_dashboard | awk '{print $1}') --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "IP del contenedor: $CONTAINER_IP"
curl http://$CONTAINER_IP:3000 | head -20

# 6. Verificar la configuración de red del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq

# 7. Verificar si el puerto está expuesto en el contenedor
docker inspect $(docker ps | grep checkin24hs_dashboard | awk '{print $1}') --format '{{json .NetworkSettings.Ports}}' | jq
```

## 🎯 Posibles Causas

1. **El servidor no está escuchando en 0.0.0.0**: Aunque los logs dicen que sí, podría haber un problema
2. **El puerto no está expuesto en la red**: El contenedor podría no tener el puerto expuesto en la red interna
3. **Problema con el modo ingress**: El modo ingress podría estar bloqueando el acceso interno
4. **Firewall o reglas de red**: Alguna regla podría estar bloqueando el puerto

## ✅ Solución Alternativa: Cambiar a Modo Host con Puerto Diferente

Si el modo ingress no funciona para acceso interno, podemos:

1. **Usar un puerto diferente** (ej: 30001) en modo host
2. **O configurar el servicio para que use el puerto interno directamente**

```bash
# Cambiar a puerto 30001 en modo host (si no está ocupado)
docker service scale checkin24hs_dashboard=0
sleep 5

docker service update \
  --publish-rm published=30000,target=3000,protocol=tcp,mode=ingress \
  --publish-add published=30001,target=3000,protocol=tcp,mode=host \
  checkin24hs_dashboard

docker service scale checkin24hs_dashboard=1
sleep 10

# Probar
curl http://localhost:30001 | head -20
```

