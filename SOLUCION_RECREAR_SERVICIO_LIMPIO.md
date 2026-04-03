# 🔧 Solución: Recrear Servicio Limpio

## 📊 Problema

- ❌ 4 contenedores activos (debería haber 1)
- ❌ DNS cacheado con IP antigua (`10.0.2.104`) que no existe
- ❌ Docker Swarm no limpia contenedores antiguos correctamente

## 🔧 Solución: Escalar a 0 y luego a 1

### Paso 1: Escalar servicio a 0 (detener todos los contenedores)

```bash
# Escalar a 0 para detener todos los contenedores
docker service scale checkin24hs_dashboard=0
```

### Paso 2: Esperar y verificar

```bash
# Esperar 10 segundos
sleep 10

# Verificar que no hay contenedores
docker ps | grep dashboard
```

### Paso 3: Limpiar contenedores detenidos

```bash
# Limpiar todos los contenedores detenidos del servicio
docker container prune -f
```

### Paso 4: Escalar servicio a 1 (recrear limpiamente)

```bash
# Escalar a 1 para crear un nuevo contenedor limpio
docker service scale checkin24hs_dashboard=1
```

### Paso 5: Esperar y verificar

```bash
# Esperar 30 segundos
sleep 30

# Verificar que solo hay 1 contenedor
docker ps | grep dashboard

# Obtener IP del nuevo contenedor
CONTAINER_ID=$(docker ps | grep dashboard | head -1 | awk '{print $1}')
docker inspect $CONTAINER_ID | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address"
```

### Paso 6: Probar DNS

```bash
# Esperar 1 minuto para que el DNS se actualice
sleep 60

# Probar resolución DNS
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard

# Probar conexión
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard:3000/
```

### Paso 7: Si el DNS sigue sin funcionar - Recrear desde EasyPanel

Si después de todo esto el DNS sigue apuntando a `10.0.2.104`, la única solución definitiva es **recrear el servicio desde EasyPanel**:

1. Ve a EasyPanel → Servicios
2. **ELIMINA** el servicio `dashboard` (o `checkin24hs_dashboard`)
3. Crea un **nuevo servicio** con:
   - Nombre: `dashboard`
   - Fuente: GitHub
   - Repositorio: `GermanPerez-ai/checkin24hs`
   - Rama: `main`
   - Build Path: `/`
   - Dockerfile: `Dockerfile` (o `deploy/Dockerfile` según tu estructura)
   - Puerto interno: `3000`
   - Comando: `node server.js`
   - Variable de entorno: `PORT=3000`
4. Configura el dominio `dashboard.checkin24hs.com` para apuntar a `http://dashboard:3000/`

---

**Ejecuta los Pasos 1-6. Si el DNS sigue sin funcionar después de esperar 1 minuto, usa el Paso 7 (recrear servicio desde EasyPanel).**
