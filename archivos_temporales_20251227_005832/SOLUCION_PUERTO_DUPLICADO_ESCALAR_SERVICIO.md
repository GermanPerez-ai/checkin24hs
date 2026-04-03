# 🔧 Solución: Puerto Duplicado - Escalar Servicio

## 🚨 Problema

- ❌ Error: "duplicate published ports provided"
- ❌ El puerto 3000 está en uso por procesos docker-pr
- ❌ Hay una instancia antigua corriendo que bloquea el puerto

## ✅ Solución: Escalar a 0, Actualizar, y Escalar de Nuevo

```bash
# 1. Escalar el servicio a 0 réplicas (detener todas las instancias)
docker service scale checkin24hs_dashboard=0

# 2. Esperar a que se detengan completamente
sleep 10

# 3. Verificar que no hay procesos usando el puerto 3000
sudo lsof -i :3000

# 4. Actualizar el servicio a modo ingress
docker service update \
  --publish-rm 3000:3000 \
  --publish-add published=3000,target=3000,protocol=tcp,mode=ingress \
  checkin24hs_dashboard

# 5. Escalar el servicio de nuevo a 1 réplica
docker service scale checkin24hs_dashboard=1

# 6. Esperar a que inicie
sleep 10

# 7. Verificar el estado
docker service ps checkin24hs_dashboard

# 8. Verificar la configuración de puertos
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 9. Probar la conexión
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -20
```

## 🔍 Alternativa: Si el Modo Ingress No Funciona

Si el modo ingress no está disponible o no funciona, podemos usar un puerto diferente:

```bash
# 1. Escalar a 0
docker service scale checkin24hs_dashboard=0
sleep 10

# 2. Cambiar a puerto 30000 (externo) -> 3000 (interno) en modo host
docker service update \
  --publish-rm 3000:3000 \
  --publish-add published=30000,target=3000,protocol=tcp,mode=host \
  checkin24hs_dashboard

# 3. Escalar de nuevo
docker service scale checkin24hs_dashboard=1
sleep 10

# 4. Verificar
docker service ps checkin24hs_dashboard
```

**Nota**: Si usas esta alternativa, necesitarás actualizar la configuración del dominio en EasyPanel para usar el puerto 30000.

