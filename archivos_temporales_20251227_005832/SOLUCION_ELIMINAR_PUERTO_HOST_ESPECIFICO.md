# 🔧 Solución: Eliminar Puerto 3000 en Modo Host

## 🚨 Problema

Aún hay dos puertos:
- ✅ Puerto 30000 en modo ingress (correcto)
- ❌ Puerto 3000 en modo host (bloquea el inicio)

El puerto 3000 en modo host no se eliminó correctamente.

## ✅ Solución: Eliminar el Puerto 3000 Especificando el Modo Host

```bash
# 1. Escalar a 0
docker service scale checkin24hs_dashboard=0
sleep 10

# 2. Eliminar el puerto 3000 en modo host (especificando el modo)
docker service update \
  --publish-rm published=3000,target=3000,protocol=tcp,mode=host \
  checkin24hs_dashboard

# 3. Esperar
sleep 5

# 4. Verificar que solo queda el puerto 30000 en modo ingress
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq
# Debería mostrar solo: [{"Protocol":"tcp","TargetPort":3000,"PublishedPort":30000,"PublishMode":"ingress"}]

# 5. Escalar de nuevo
docker service scale checkin24hs_dashboard=1
sleep 15

# 6. Verificar estado
docker service ps checkin24hs_dashboard

# 7. Ver logs
docker service logs checkin24hs_dashboard --tail 10

# 8. Probar conexión (usando el puerto 30000)
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:30000 2>&1 | head -20
```

## 🔍 Si Aún No Funciona

Si el comando anterior no elimina el puerto, podemos intentar recrear el servicio desde EasyPanel o usar una solución alternativa.

