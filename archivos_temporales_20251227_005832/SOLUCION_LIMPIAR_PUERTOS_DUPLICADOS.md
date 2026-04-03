# 🔧 Solución: Limpiar Puertos Duplicados

## 🚨 Problema

Hay múltiples puertos configurados:
- Puerto 30000 en modo host (debería ser ingress)
- Puerto 30001 en modo host
- Puerto 30002 en modo host

El servicio no puede iniciar porque hay conflictos.

## ✅ Solución: Limpiar y Dejar Solo Puerto 30002

```bash
# 1. Escalar a 0
docker service scale checkin24hs_dashboard=0
sleep 10

# 2. Eliminar todos los puertos
docker service update --publish-rm 30000 checkin24hs_dashboard
sleep 3
docker service update --publish-rm 30001 checkin24hs_dashboard
sleep 3
docker service update --publish-rm 30002 checkin24hs_dashboard
sleep 3

# 3. Verificar que se eliminaron todos
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq
# Debería mostrar: []

# 4. Agregar SOLO el puerto 30002 en modo host
docker service update \
  --publish-add published=30002,target=3000,protocol=tcp,mode=host \
  checkin24hs_dashboard

# 5. Esperar
sleep 5

# 6. Verificar que solo está el puerto 30002
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 7. Escalar de nuevo
docker service scale checkin24hs_dashboard=1
sleep 15

# 8. Verificar estado
docker service ps checkin24hs_dashboard

# 9. Ver logs
docker service logs checkin24hs_dashboard --tail 10

# 10. Probar con el puerto 30002
curl http://localhost:30002 | head -20

# 11. Probar desde Traefik
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:30002 2>&1 | head -20
```

