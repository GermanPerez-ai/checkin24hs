# 🔧 Solución Alternativa Sin Eliminar Servicio

## 📊 Problema

- ✅ IP `10.0.2.84` funciona (200 OK)
- ❌ EasyPanel no permite usar IPs directas
- ❌ DNS resuelve a IP antigua (`10.0.2.104`)
- ❌ 2 contenedores activos (debería haber 1)

## 🔧 Solución Segura: Forzar Actualización Completa

### Paso 1: Obtener IP del contenedor más reciente

```bash
# Obtener IP del contenedor más reciente (7e68b3659ad6)
docker inspect 7e68b3659ad6 | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address"
```

### Paso 2: Limpiar contenedor antiguo (dejar solo el más reciente)

```bash
# Detener y eliminar el contenedor antiguo
docker stop c2233af894bf
docker rm c2233af894bf
```

### Paso 3: Forzar actualización completa del servicio

```bash
# Forzar actualización completa (esto debería actualizar el DNS)
docker service update --force --update-delay 0s checkin24hs_dashboard
```

### Paso 4: Esperar y verificar

```bash
# Esperar 30 segundos
sleep 30

# Verificar contenedores (debería haber solo 1)
docker ps | grep dashboard
```

### Paso 5: Reiniciar el servicio DNS de Docker (si es posible)

```bash
# Reiniciar el contenedor DNS de Docker Swarm
docker ps | grep dns
# Si hay un contenedor DNS, reinícialo:
# docker restart <container_id>
```

### Paso 6: Probar DNS

```bash
# Esperar 30 segundos más
sleep 30

# Probar resolución DNS
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard

# Probar conexión
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard:3000/
```

### Paso 7: Si aún no funciona, reiniciar Traefik

```bash
# Reiniciar Traefik
docker service update --force traefik
```

### Paso 8: Solución Final - Agregar Alias Manualmente (si nada más funciona)

Si el DNS sigue sin funcionar, podemos intentar agregar un alias manualmente a la red:

```bash
# Obtener ID del contenedor activo
CONTAINER_ID=$(docker ps | grep dashboard | head -1 | awk '{print $1}')

# Ver redes del contenedor
docker inspect $CONTAINER_ID | grep -A 5 "Networks"
```

Luego intentar desconectar y reconectar el contenedor a la red con el alias correcto. Pero esto es complejo y puede no funcionar.

---

**Ejecuta primero los Pasos 1-4. Si el DNS no se actualiza, prueba el Paso 7 (reiniciar Traefik).**
