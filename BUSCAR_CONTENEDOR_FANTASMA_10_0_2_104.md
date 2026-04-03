# 🔍 Buscar Contenedor Fantasma con IP 10.0.2.104

## 📊 Problema

- ❌ DNS resuelve a `10.0.2.104` (IP antigua)
- ❌ Ningún contenedor activo tiene esa IP
- ❌ DNS está cacheado

## 🔍 Diagnóstico

### Paso 1: Buscar IP 10.0.2.104 en la red

```bash
# Buscar IP 10.0.2.104 en la red easypanel-checkin24hs
docker network inspect easypanel-checkin24hs | grep -B 10 -A 10 "10.0.2.104"
```

### Paso 2: Ver todos los contenedores del servicio (incluyendo detenidos)

```bash
# Ver todos los contenedores
docker ps -a | grep dashboard

# Ver detalles de cada contenedor
docker inspect $(docker ps -a | grep dashboard | awk '{print $1}') | grep -A 5 "easypanel-checkin24hs" | grep -E "Id|IPv4Address"
```

### Paso 3: Obtener IP del contenedor más reciente

```bash
# Obtener IP del contenedor más reciente
CONTAINER_ID=$(docker ps | grep dashboard | head -1 | awk '{print $1}')
echo "Contenedor más reciente: $CONTAINER_ID"
docker inspect $CONTAINER_ID | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address"
```

### Paso 4: Limpiar contenedores antiguos

```bash
# Limpiar el contenedor antiguo (7e68b3659ad6)
docker stop 7e68b3659ad6
docker rm 7e68b3659ad6
```

### Paso 5: Forzar actualización del servicio

```bash
# Forzar actualización
docker service update --force checkin24hs_dashboard

# Esperar 30 segundos
sleep 30

# Verificar que solo hay 1 contenedor
docker ps | grep dashboard
```

### Paso 6: Si el DNS sigue sin funcionar - SOLUCIÓN FINAL

Si después de todo esto el DNS sigue apuntando a `10.0.2.104`, la única solución es **recrear el servicio desde EasyPanel**:

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

Esto recreará el servicio desde cero y el DNS debería funcionar correctamente.

---

**Ejecuta primero los Pasos 1-5. Si el DNS sigue sin funcionar, usa el Paso 6 (recrear servicio desde EasyPanel).**
