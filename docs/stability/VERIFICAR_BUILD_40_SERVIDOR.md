# ✅ Verificar Build #40 en el Servidor

## 🔍 Comandos de Verificación

### 1. Verificar Build Number en el Archivo Montado

```bash
# Verificar en el archivo del host (bind mount)
grep "DASHBOARD_BUILD_NUMBER" /root/checkin24hs/dashboard.html | head -1
# Debe mostrar: window.DASHBOARD_BUILD_NUMBER = 40;
```

### 2. Verificar Build Number en el Contenedor

```bash
# Verificar en el contenedor activo
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
docker exec ${CONTAINER_ID} grep "DASHBOARD_BUILD_NUMBER" /app/dashboard.html | head -1
# Debe mostrar: window.DASHBOARD_BUILD_NUMBER = 40;
```

### 3. Limpiar Contenedores Duplicados (Si hay varios corriendo)

```bash
# Ver todos los contenedores del servicio
docker ps | grep dashboard

# Si hay múltiples, detener los antiguos (opcional)
# Docker Swarm manejará esto automáticamente, pero puedes forzar:
docker service scale checkin24hs_dashboard=1
```

### 4. Verificar que el Servicio está Funcionando

```bash
# Ver estado del servicio
docker service ps checkin24hs_dashboard --no-trunc

# Ver logs del contenedor activo
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
docker logs --tail 20 ${CONTAINER_ID}
```

### 5. Verificar en el Navegador

1. Abre el dashboard en tu navegador
2. Abre la consola (F12)
3. Ejecuta:
   ```javascript
   console.log('Build:', window.DASHBOARD_BUILD_NUMBER);
   ```
4. **Debe mostrar:** `Build: 40`

---

## ✅ Verificación de Funcionalidades

### 1. Autenticación
- ✅ Abre en modo incógnito → Debe pedir login
- ✅ Inicia sesión → Debe mostrar dashboard

### 2. Botón de Cerrar Sesión
- ✅ Verifica que esté visible en el sidebar (al final del menú)

### 3. Timeout de Inactividad
- ✅ El sistema está activo (verificar en consola que no hay errores)

---

## 🔧 Si Hay Problemas

### Si el Build Number sigue siendo 39:

```bash
# Verificar que el archivo se descargó correctamente
cat /root/checkin24hs/dashboard.html | grep -A 1 "DASHBOARD_BUILD_NUMBER" | head -2

# Si no es 40, descargar nuevamente
curl -L -o /root/checkin24hs/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# Reiniciar el contenedor activo
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
docker restart ${CONTAINER_ID}
```

### Si hay múltiples contenedores:

```bash
# Forzar escala a 1 contenedor
docker service scale checkin24hs_dashboard=1

# Esperar a que termine
sleep 5

# Verificar
docker ps | grep dashboard
```

---

**Fecha:** 2026-01-17
**Build Esperado:** #40
