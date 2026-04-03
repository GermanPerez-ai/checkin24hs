# 🔍 Encontrar el Contenedor del Dashboard (Servicio en Verde)

## 🚨 Problema

El comando `docker ps | grep dashboard` no encuentra nada, pero el servicio está en verde en EasyPanel.

**Esto significa que el contenedor tiene otro nombre.**

---

## 🔍 Solución: Encontrar el Contenedor Correcto

### Paso 1: Ver TODOS los Contenedores

```bash
# Ver todos los contenedores corriendo
docker ps
```

**Copia y pega la salida completa aquí.** Necesito ver todos los contenedores para identificar cuál es el del dashboard.

---

### Paso 2: Buscar por Diferentes Nombres

El contenedor puede llamarse de diferentes formas. Ejecuta estos comandos:

```bash
# Ver todos los contenedores
docker ps

# Buscar por diferentes patrones
docker ps | grep -i checkin
docker ps | grep -i admin
docker ps | grep -i panel
docker ps | grep -i web
```

---

### Paso 3: Ver por Puerto

El dashboard suele usar el puerto 3000:

```bash
# Ver qué contenedor usa el puerto 3000
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 3000

# O ver todos los puertos
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

---

### Paso 4: Ver Servicios de Docker Swarm

Si el servicio está en Docker Swarm, puede que no aparezca como contenedor directo:

```bash
# Ver todos los servicios
docker service ls

# Ver tareas de los servicios
docker service ps $(docker service ls -q) | grep dashboard
```

---

## 🎯 Comandos Completos para Ejecutar

Ejecuta estos comandos **uno por uno** y comparte la salida:

```bash
# 1. Ver TODOS los contenedores
echo "=== TODOS LOS CONTENEDORES ==="
docker ps

# 2. Ver servicios
echo ""
echo "=== SERVICIOS ==="
docker service ls

# 3. Ver contenedores por puerto 3000
echo ""
echo "=== PUERTO 3000 ==="
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 3000

# 4. Ver todos los puertos
echo ""
echo "=== TODOS LOS PUERTOS ==="
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

---

## 💡 Alternativa: Desde EasyPanel

Si no puedes encontrar el contenedor desde SSH:

1. **Ve a EasyPanel**
2. **Haz clic en el servicio "dashboard"**
3. **Ve a la pestaña "Logs" o "Terminal"**
4. **Desde ahí puedes ver los logs directamente**

---

## 🔧 Una Vez que Encuentres el Contenedor

Cuando encuentres el nombre correcto del contenedor, usa estos comandos:

```bash
# Reemplaza CONTAINER_NAME con el nombre real
CONTAINER_NAME="NOMBRE_REAL_DEL_CONTENEDOR"

# Ver logs
docker logs $CONTAINER_NAME --tail 30

# Reiniciar
docker restart $CONTAINER_NAME

# Ver estado
docker ps | grep $CONTAINER_NAME
```

---

## 📋 Ejemplo de Salida Esperada

Cuando ejecutes `docker ps`, deberías ver algo como:

```
CONTAINER ID   IMAGE                    STATUS         PORTS                    NAMES
abc123def456   dashboard:latest         Up 2 hours     0.0.0.0:3000->3000/tcp   dashboard-1
def456ghi789   traefik:latest          Up 2 hours     0.0.0.0:80->80/tcp       traefik-1
```

**El contenedor del dashboard puede tener nombres como:**
- `dashboard-1`
- `srv-dashboard-1`
- `checkin24hs-dashboard-1`
- `dashboard_dashboard-1`
- O cualquier variación

---

## 🆘 Si No Aparece Ningún Contenedor

Si `docker ps` no muestra nada:

1. **Verifica que Docker está corriendo:**
   ```bash
   systemctl status docker
   ```

2. **El servicio puede estar en otro servidor:**
   - Verifica en EasyPanel en qué servidor está configurado

3. **El servicio puede estar usando otra tecnología:**
   - Puede estar corriendo directamente con Node.js (sin Docker)
   - O puede estar en otro sistema

---

## 📞 Dime Qué Ves

**Ejecuta `docker ps` y comparte la salida completa.** Con esa información te ayudo a identificar el contenedor correcto y solucionar el Bad Gateway.

