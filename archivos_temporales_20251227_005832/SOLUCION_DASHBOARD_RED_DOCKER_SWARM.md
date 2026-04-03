# 🔧 Solución: Dashboard no accesible desde Docker Swarm

## 🚨 Problema Identificado

El servicio dashboard funciona en `localhost:3000` pero **NO es accesible desde la red de Docker Swarm** donde está Traefik.

**Síntomas:**
- ✅ `curl http://localhost:3000` funciona (desde el host)
- ❌ `wget http://checkin24hs_dashboard:3000` falla (desde Traefik)
- ❌ Error: "Host is unreachable"

## 🎯 Causa

El servicio está escuchando en el puerto 3000 del **host**, pero **NO está en la red de Docker Swarm** donde Traefik puede alcanzarlo.

## ✅ Solución: Agregar el Servicio a la Red de Docker Swarm

### Paso 1: Verificar la Red de Traefik

Desde SSH, ejecuta:

```bash
# Ver las redes de Docker Swarm
docker network ls

# Ver la red de Traefik (generalmente se llama "traefik" o "traefik_web")
docker network inspect traefik | grep -A 5 "Name\|Containers"
```

### Paso 2: Verificar el Servicio Dashboard

```bash
# Ver el servicio dashboard
docker service ls | grep dashboard

# Ver detalles del servicio
docker service inspect checkin24hs_dashboard --pretty
```

### Paso 3: Agregar el Servicio a la Red de Traefik

**Opción A: Desde EasyPanel (Recomendado)**

1. Ve a **EasyPanel** → **Servicios** → **dashboard**
2. Busca la sección **"Network"** o **"Red"** o **"Networks"**
3. Agrega la red de Traefik:
   - Si la red se llama `traefik`: agrega `traefik`
   - Si la red se llama `traefik_web`: agrega `traefik_web`
   - O busca en la lista de redes disponibles
4. **Guarda** los cambios
5. **Reinicia** el servicio (o haz clic en "Deploy")

**Opción B: Desde SSH (Si EasyPanel no tiene la opción)**

```bash
# Conectar el servicio a la red de Traefik
docker service update --network-add traefik checkin24hs_dashboard

# O si la red tiene otro nombre:
docker service update --network-add traefik_web checkin24hs_dashboard
```

### Paso 4: Verificar que el Puerto 3000 Esté Expuesto

En EasyPanel:

1. Ve a **"Ports"** o **"Puertos"** en la configuración del servicio dashboard
2. Verifica que el puerto **3000** esté configurado:
   - **Puerto interno**: `3000`
   - **Puerto externo**: `3000` (o el que prefieras)
3. **Guarda** los cambios

### Paso 5: Verificar la Configuración del Dominio en EasyPanel

1. Ve a **"Dominios"** en EasyPanel
2. Haz clic en el dominio del dashboard
3. Verifica:
   - **Protocolo**: `HTTP`
   - **Puerto**: `3000` (puerto interno del contenedor)
   - **Target Service**: `checkin24hs_dashboard` o `checkin24hs-dashboard`
4. **Guarda** los cambios

### Paso 6: Probar de Nuevo

Desde SSH:

```bash
# Probar desde Traefik
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs_dashboard:3000 2>&1 | head -20

# O probar desde otro contenedor en la misma red
docker run --rm --network traefik alpine wget -O- http://checkin24hs_dashboard:3000
```

## 🔍 Diagnóstico Adicional

Si aún no funciona, verifica:

### 1. Verificar que el Servicio Esté en la Red Correcta

```bash
# Ver las redes del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq

# Ver los contenedores del servicio
docker service ps checkin24hs_dashboard

# Ver la red de un contenedor específico
docker inspect <CONTAINER_ID> | grep -A 10 Networks
```

### 2. Verificar el Alias del Servicio

El alias del servicio en la red debe coincidir con el nombre usado en Traefik:

```bash
# Ver el alias del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq '.[] | .aliases'
```

**IMPORTANTE**: El alias debe ser:
- `checkin24hs_dashboard` (con guión bajo) O
- `checkin24hs-dashboard` (con guión)

Debe coincidir con el nombre usado en la configuración del dominio en EasyPanel.

### 3. Verificar que el Servidor Escuche en 0.0.0.0

El servidor dentro del contenedor debe escuchar en `0.0.0.0:3000`, no en `localhost:3000`:

```bash
# Ver los logs del servicio
docker service logs checkin24hs_dashboard --tail 50

# Buscar el mensaje de inicio del servidor
# Debe decir algo como: "Server running at http://0.0.0.0:3000/"
```

Si el servidor escucha en `localhost`, necesitas cambiar el código para que escuche en `0.0.0.0`.

## ✅ Configuración Final Esperada

**En EasyPanel:**

1. **Network/Red**: `traefik` (o `traefik_web`)
2. **Ports/Puertos**: `3000:3000` (externo:interno)
3. **Dominios**:
   - **Target Service**: `checkin24hs_dashboard` o `checkin24hs-dashboard`
   - **Puerto**: `3000`

**En el código (server.js):**

```javascript
server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running at http://0.0.0.0:${PORT}/`);
});
```

## 🎯 Resumen de Pasos

1. ✅ Agregar el servicio a la red de Traefik en EasyPanel
2. ✅ Verificar que el puerto 3000 esté expuesto
3. ✅ Verificar la configuración del dominio (puerto 3000)
4. ✅ Verificar que el servidor escuche en `0.0.0.0:3000`
5. ✅ Probar desde Traefik

---

**Si después de estos pasos aún no funciona, comparte:**
- El resultado de `docker service inspect checkin24hs_dashboard --pretty`
- El resultado de `docker network inspect traefik`
- Los logs del servicio dashboard

