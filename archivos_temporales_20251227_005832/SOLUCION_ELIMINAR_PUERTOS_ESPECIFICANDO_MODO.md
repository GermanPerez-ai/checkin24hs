# 🔧 Solución: Eliminar Puertos Especificando el Modo

## 🚨 Problema

Los puertos no se eliminan correctamente con `--publish-rm`. Necesitamos especificar el modo también.

## ✅ Solución: Eliminar Puertos Especificando Modo Host

```bash
# 1. Escalar a 0
docker service scale checkin24hs_dashboard=0
sleep 10

# 2. Eliminar puertos especificando el modo host
docker service update --publish-rm published=30000,target=30000,protocol=tcp,mode=host checkin24hs_dashboard
sleep 3
docker service update --publish-rm published=30001,target=3000,protocol=tcp,mode=host checkin24hs_dashboard
sleep 3
docker service update --publish-rm published=30002,target=3000,protocol=tcp,mode=host checkin24hs_dashboard
sleep 3

# 3. Verificar que se eliminaron todos
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq
# Debería mostrar: []

# 4. Agregar SOLO el puerto 30002
docker service update \
  --publish-add published=30002,target=3000,protocol=tcp,mode=host \
  checkin24hs_dashboard

# 5. Esperar
sleep 5

# 6. Verificar
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 7. Escalar
docker service scale checkin24hs_dashboard=1
sleep 15

# 8. Verificar estado
docker service ps checkin24hs_dashboard

# 9. Probar desde localhost
curl http://localhost:30002 | head -5

# 10. Obtener la IP del contenedor y probar desde Traefik
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}')
EASYPANEL_IP=$(docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Networks.easypanel.IPAddress')
echo "IP del contenedor: $EASYPANEL_IP"

# 11. Probar desde Traefik usando la IP directa
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://$EASYPANEL_IP:3000 2>&1 | head -20
```

## 🎯 Si el Alias No Funciona

Si después de esto el alias `checkin24hs-dashboard:30002` aún no funciona, podemos:

1. **Usar la IP directamente** en la configuración de Traefik (no ideal porque la IP puede cambiar)
2. **Configurar el dominio en EasyPanel** para usar la IP directamente
3. **Verificar la configuración de red** del servicio

Pero primero, probemos eliminar los puertos especificando el modo.

