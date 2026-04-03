# 🔧 Solución: Eliminar Todos los Puertos Primero

## 🚨 Problema

Hay **dos puertos configurados**:
1. Puerto 30000 en modo ingress
2. Puerto 3000 en modo host

Necesitamos eliminar **AMBOS** y luego agregar solo el puerto 3000 en modo ingress.

## ✅ Solución Paso a Paso

```bash
# 1. Ver la configuración actual
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 2. Eliminar el puerto 30000 (ingress)
docker service update --publish-rm 30000 checkin24hs_dashboard

# 3. Esperar
sleep 3

# 4. Eliminar el puerto 3000 (host)
docker service update --publish-rm 3000 checkin24hs_dashboard

# 5. Esperar
sleep 3

# 6. Verificar que se eliminaron todos
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq
# Debería mostrar: []

# 7. Agregar SOLO el puerto 3000 en modo ingress
docker service update \
  --publish-add published=3000,target=3000,protocol=tcp,mode=ingress \
  checkin24hs_dashboard

# 8. Esperar
sleep 5

# 9. Verificar la nueva configuración
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq
# Debería mostrar solo el puerto 3000 en modo ingress

# 10. Escalar el servicio
docker service scale checkin24hs_dashboard=1

# 11. Esperar a que inicie
sleep 15

# 12. Verificar el estado
docker service ps checkin24hs_dashboard

# 13. Ver los logs para confirmar que está escuchando
docker service logs checkin24hs_dashboard --tail 10

# 14. Probar la conexión desde Traefik
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -20
```

## 🔍 Si Aún No Funciona

Si después de esto el servicio sigue sin iniciar, verifica:

```bash
# Ver si hay algún problema con la configuración
docker service inspect checkin24hs_dashboard --pretty | grep -A 20 "Ports\|Endpoint"

# Ver todos los servicios y sus puertos
docker service ls --format "table {{.Name}}\t{{.Ports}}"
```

