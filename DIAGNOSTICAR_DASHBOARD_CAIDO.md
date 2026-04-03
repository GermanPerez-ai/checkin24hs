# 🔍 Diagnosticar Dashboard que No Carga

## 📋 Comandos para Ejecutar en el Servidor

### 1. Verificar estado de contenedores

```bash
docker ps -a | grep dashboard
```

Esto muestra todos los contenedores (activos y detenidos) del dashboard.

### 2. Ver logs del contenedor más reciente

```bash
docker ps | grep dashboard
# Usa el ID del contenedor más reciente para ver logs:
docker logs <ID_CONTENEDOR> --tail 100
```

### 3. Verificar si hay errores de inicio

```bash
# Ver los últimos logs con errores
docker logs <ID_CONTENEDOR> 2>&1 | tail -50

# O buscar errores específicos
docker logs <ID_CONTENEDOR> 2>&1 | grep -i "error\|fatal\|cannot\|failed"
```

### 4. Verificar puerto 3000

```bash
# Ver si el puerto está en uso
netstat -tuln | grep 3000
# O
ss -tuln | grep 3000
```

### 5. Verificar servicios de EasyPanel

```bash
# Ver servicios de Docker Swarm (si EasyPanel usa Swarm)
docker service ls | grep dashboard

# Ver detalles del servicio
docker service ps checkin24hs_dashboard
```

### 6. Verificar si el archivo .env causa problemas

```bash
cd /etc/easypanel/projects/checkin24hs/dashboard/code
cat .env
# Verificar que no tenga caracteres raros
file .env
```

### 7. Ver logs de EasyPanel (si están disponibles)

```bash
# Ver logs del servicio dashboard
docker service logs checkin24hs_dashboard --tail 50
```

---

## 🔧 Posibles Problemas y Soluciones

### Problema 1: Contenedor detenido o reiniciando

**Solución:**
```bash
# Ver estado
docker ps -a | grep dashboard

# Si está detenido, ver logs para ver por qué
docker logs <ID_CONTENEDOR>
```

### Problema 2: Error al cargar dotenv o .env

**Solución:**
- Verificar que `.env` existe y tiene formato correcto
- Verificar que `dotenv` está instalado
- Ver logs del contenedor para ver si hay errores de sintaxis

### Problema 3: Error en server.js

**Solución:**
- Verificar que el código no tenga errores de sintaxis
- Ver logs para encontrar la línea del error

### Problema 4: Puerto no disponible o conflicto

**Solución:**
- Verificar que el puerto 3000 no esté en uso por otro proceso
- Reiniciar el servicio desde EasyPanel

---

## ✅ Comandos Rápidos (Copia y Pega)

```bash
# Ver estado completo
echo "=== CONTENEDORES DASHBOARD ==="
docker ps -a | grep dashboard

echo -e "\n=== LOGS ÚLTIMO CONTENEDOR ==="
CONTAINER_ID=$(docker ps -a | grep dashboard | head -1 | awk '{print $1}')
docker logs $CONTAINER_ID --tail 50

echo -e "\n=== ERRORES EN LOGS ==="
docker logs $CONTAINER_ID 2>&1 | grep -i "error\|fatal\|cannot\|failed" | tail -20

echo -e "\n=== VERIFICAR .ENV ==="
cd /etc/easypanel/projects/checkin24hs/dashboard/code
ls -la .env
cat .env
```

---

**Ejecuta estos comandos y comparte la salida para diagnosticar el problema.**
