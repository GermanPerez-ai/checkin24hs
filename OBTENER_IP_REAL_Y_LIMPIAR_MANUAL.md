# 🔧 Obtener IP Real y Limpiar Manualmente

## 📊 Estado Actual

- ❌ 4 contenedores activos (debería haber 1)
- ❌ DNS apunta a IP antigua (`10.0.2.104`)

## 🔧 Solución

### Paso 1: Obtener IP del contenedor más reciente

```bash
# Obtener ID del contenedor más reciente
CONTAINER_ID=$(docker ps | grep dashboard | head -1 | awk '{print $1}')

# Obtener IP en la red easypanel-checkin24hs
docker inspect $CONTAINER_ID | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address"
```

### Paso 2: Probar conexión a esa IP

```bash
# Usar la IP obtenida (reemplaza X.X.X.X con la IP real)
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://X.X.X.X:3000/
```

### Paso 3: Limpiar contenedores antiguos manualmente

```bash
# Ver todos los contenedores
docker ps | grep dashboard

# Detener y eliminar contenedores antiguos (excepto el más reciente)
# El más reciente es: 3e1710a6fd8a
# Elimina los otros 3:
docker stop 826235e1fd2f 9eb33d90bab1 d6b730db671e
docker rm 826235e1fd2f 9eb33d90bab1 d6b730db671e
```

### Paso 4: Esperar y probar DNS de nuevo

```bash
# Esperar 30 segundos
sleep 30

# Probar DNS
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard:3000/
```

### Paso 5: Si el DNS sigue desactualizado, usar IP directa en EasyPanel

Si el DNS sigue sin funcionar, configura el dominio en EasyPanel para usar la IP directa:
- Destino: `http://X.X.X.X:3000/` (reemplaza con la IP real obtenida)

---

**Ejecuta primero el Paso 1 para obtener la IP real.**
