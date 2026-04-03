# 🔍 Verificar Alias y Obtener IP desde SSH

## ✅ Comandos para Ejecutar

Ejecuta estos comandos en orden en tu terminal SSH:

```bash
# 1. Probar si el alias funciona desde Traefik
echo "=== Probando alias checkin24hs-dashboard:3000 ==="
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -10

# 2. Obtener la IP del contenedor
echo ""
echo "=== Obteniendo IP del contenedor ==="
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}')
echo "Container ID: $CONTAINER_ID"
EASYPANEL_IP=$(docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Networks.easypanel.IPAddress')
echo "IP en red easypanel: $EASYPANEL_IP"

# 3. Probar con la IP directa desde Traefik
echo ""
echo "=== Probando con IP directa: $EASYPANEL_IP:3000 ==="
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://$EASYPANEL_IP:3000 2>&1 | head -10
```

## 📋 Interpretación de Resultados

### Si el comando 1 funciona:
- El alias funciona ✅
- El problema está en otra parte (configuración de Traefik, cache, etc.)

### Si el comando 1 NO funciona pero el comando 3 SÍ:
- El alias NO funciona ❌
- Necesitamos usar la IP directa en el dominio

### Si ninguno funciona:
- Hay un problema de red o el servicio no está accesible
- Necesitamos verificar la configuración del servicio

---

**Ejecuta estos comandos y comparte el resultado completo. Con eso sabré exactamente qué hacer.**

