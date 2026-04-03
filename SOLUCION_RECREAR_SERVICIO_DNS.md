# 🔧 Solución: Recrear Servicio para Actualizar DNS

## 📊 Problema

- ✅ IP `10.0.2.84` funciona (200 OK)
- ❌ EasyPanel no permite usar IPs directas (solo nombres de servicios)
- ❌ DNS resuelve a IP antigua (`10.0.2.104`)
- ❌ 2 contenedores activos (debería haber 1)

## 🔧 Solución: Recrear Servicio

### Paso 1: Detener todos los contenedores del servicio

```bash
# Detener todos los contenedores
docker stop 7e68b3659ad6 c2233af894bf
docker rm 7e68b3659ad6 c2233af894bf
```

### Paso 2: Remover el servicio

```bash
# Remover el servicio (esto NO elimina la configuración en EasyPanel)
docker service rm checkin24hs_dashboard
```

### Paso 3: Verificar que el servicio se haya eliminado

```bash
docker service ls | grep dashboard
docker ps | grep dashboard
```

### Paso 4: Recrear el servicio desde EasyPanel

1. Ve a EasyPanel → Servicios
2. Edita el servicio `dashboard` (o `checkin24hs_dashboard`)
3. Haz clic en "Redeploy" o "Implementar" de nuevo
4. Esto recreará el servicio y debería actualizar el DNS

### Paso 5: Esperar y verificar

```bash
# Esperar 30 segundos
sleep 30

# Verificar contenedores (debería haber solo 1)
docker ps | grep dashboard

# Obtener IP del nuevo contenedor
CONTAINER_ID=$(docker ps | grep dashboard | head -1 | awk '{print $1}')
docker inspect $CONTAINER_ID | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address"
```

### Paso 6: Probar DNS

```bash
# Probar resolución DNS
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard

# Probar conexión
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard:3000/
```

### Paso 7: Si el DNS aún no funciona, reiniciar Traefik

```bash
# Reiniciar Traefik para que recargue la configuración
docker service update --force traefik
```

---

**IMPORTANTE**: Antes de remover el servicio, asegúrate de tener guardada la configuración en EasyPanel. Si no puedes recrearlo desde EasyPanel fácilmente, **NO ejecutes el Paso 2**. En su lugar, continúa con una solución alternativa.
