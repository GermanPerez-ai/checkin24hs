# 🔧 Limpiar Contenedores y Escalar Servicio

## 📊 Problema

- ❌ Múltiples contenedores activos (debería haber 1)
- ❌ DNS desactualizado (apunta a IP antigua `10.0.2.104`)

## 🔧 Solución

### Paso 1: Escalar servicio a 1 réplica explícitamente

```bash
# Escalar servicio a 1 réplica
docker service scale checkin24hs_dashboard=1
```

### Paso 2: Esperar y verificar

```bash
# Esperar 30 segundos
sleep 30

# Verificar contenedores
docker ps | grep dashboard
```

### Paso 3: Limpiar contenedores detenidos

```bash
# Eliminar contenedores detenidos
docker container prune -f --filter "name=checkin24hs_dashboard"
```

### Paso 4: Probar DNS de nuevo

```bash
# Probar resolución DNS
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard

# Probar conexión
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard:3000/
```

### Paso 5: Si el DNS sigue desactualizado, usar IP directa temporalmente

Si el DNS sigue apuntando a `10.0.2.104`, podemos usar una IP directa que sabemos que funciona. Primero, obtén la IP del contenedor activo:

```bash
# Obtener IP del contenedor activo
docker inspect $(docker ps | grep dashboard | head -1 | awk '{print $1}') | grep -A 5 "easypanel-checkin24hs" | grep "IPv4Address"
```

Luego, en EasyPanel, configura el dominio para usar esa IP directamente (temporalmente).

---

**Ejecuta primero el Paso 1 y espera 30 segundos.**
