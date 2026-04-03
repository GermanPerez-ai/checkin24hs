# 🔧 Solución: Probar con IP Corregida

## ✅ IPs Encontradas

- **easypanel**: `10.11.124.79` (red donde está Traefik)
- **easypanel-checkin24hs**: `10.0.1.141`

## 🔍 Comandos Corregidos

```bash
# 1. Obtener el ID del contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}')
echo "Container ID: $CONTAINER_ID"

# 2. Obtener la IP de la red easypanel (método corregido)
EASYPANEL_IP=$(docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Networks.easypanel.IPAddress')
echo "IP en red easypanel: $EASYPANEL_IP"

# 3. Probar con la IP de la red easypanel
curl http://$EASYPANEL_IP:3000 | head -20

# 4. Probar desde Traefik usando la IP directa
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://$EASYPANEL_IP:3000 2>&1 | head -20

# 5. Si funciona, agregar puerto 30001 en modo host para acceso interno estable
docker service update \
  --publish-add published=30001,target=3000,protocol=tcp,mode=host \
  checkin24hs_dashboard

# 6. Esperar
sleep 5

# 7. Probar con el nuevo puerto
curl http://localhost:30001 | head -20

# 8. Probar desde Traefik usando el alias con puerto 30001
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:30001 2>&1 | head -20
```

## 🎯 Explicación

Si funciona con la IP directa (`10.11.124.79:3000`), significa que:
- ✅ El servidor está funcionando correctamente
- ✅ El puerto 3000 está escuchando
- ❌ El alias `checkin24hs-dashboard` no está enrutando correctamente el puerto 3000

**Solución**: Agregar el puerto 30001 en modo host para tener acceso interno estable. Luego, en EasyPanel, configurar el dominio para usar el puerto 30001.

