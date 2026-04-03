# 🔍 Encontrar el Contenedor del Dashboard

## 📋 Pasos para Encontrar el Contenedor Correcto

### Paso 1: Ver Todos los Contenedores

```bash
# Ver todos los contenedores corriendo
docker ps

# Ver todos los contenedores (incluso detenidos)
docker ps -a
```

### Paso 2: Buscar Contenedores Relacionados con Dashboard

```bash
# Buscar por "dashboard"
docker ps | grep dashboard

# Buscar por "checkin24hs"
docker ps | grep checkin24hs

# Buscar por "nginx" (puede ser un contenedor nginx)
docker ps | grep nginx
```

### Paso 3: Ver Servicios de Docker Swarm

Si usas Docker Swarm (EasyPanel lo usa):

```bash
# Ver todos los servicios
docker service ls

# Buscar servicios relacionados con dashboard
docker service ls | grep dashboard
docker service ls | grep checkin24hs
```

### Paso 4: Ver Contenedores por Puerto

El dashboard suele usar el puerto 3000:

```bash
# Ver qué contenedor usa el puerto 3000
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 3000
```

---

## 🎯 Comandos Rápidos (Copia y Pega)

Ejecuta estos comandos en orden y dime qué ves:

```bash
# 1. Ver todos los contenedores corriendo
echo "=== CONTENEDORES CORRIENDO ==="
docker ps

# 2. Buscar dashboard
echo ""
echo "=== BUSCANDO DASHBOARD ==="
docker ps | grep -i dashboard

# 3. Buscar checkin24hs
echo ""
echo "=== BUSCANDO CHECKIN24HS ==="
docker ps | grep -i checkin24hs

# 4. Ver servicios
echo ""
echo "=== SERVICIOS DOCKER SWARM ==="
docker service ls

# 5. Buscar servicios dashboard
echo ""
echo "=== SERVICIOS DASHBOARD ==="
docker service ls | grep -i dashboard
```

---

## 💡 Nombres Comunes de Contenedores

El contenedor puede llamarse:
- `dashboard-1`
- `checkin24hs-dashboard-1`
- `dashboard_dashboard-1`
- `srv-dashboard-1`
- `dashboard-dashboard-1`
- O cualquier variación

---

## 🔧 Una Vez que Encuentres el Contenedor

Cuando encuentres el nombre correcto, usa estos comandos:

```bash
# Reemplaza CONTAINER_NAME con el nombre real
CONTAINER_NAME="NOMBRE_REAL_DEL_CONTENEDOR"

# Ver logs
docker logs $CONTAINER_NAME --tail 50

# Reiniciar
docker restart $CONTAINER_NAME

# Ver estado
docker ps | grep $CONTAINER_NAME
```

---

## 🆘 Si No Encuentras Ningún Contenedor

Si no encuentras ningún contenedor relacionado con dashboard:

1. **Verifica en EasyPanel:**
   - Ve a tu panel de EasyPanel
   - Busca el servicio "dashboard"
   - Verifica que esté activo y corriendo

2. **Puede estar en otro servidor:**
   - Verifica que estás en el servidor correcto
   - El dashboard puede estar en otro VPS

3. **Puede estar detenido:**
   ```bash
   # Ver todos los contenedores (incluso detenidos)
   docker ps -a | grep dashboard
   docker ps -a | grep checkin24hs
   ```

---

## 📞 Dime Qué Ves

Ejecuta los comandos de arriba y dime:
1. ¿Qué contenedores ves en `docker ps`?
2. ¿Hay algún contenedor con "dashboard" o "checkin24hs" en el nombre?
3. ¿Qué servicios ves en `docker service ls`?

Con esa información te ayudo a encontrar el contenedor correcto.

