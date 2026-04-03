# 🔧 Solucionar Bad Gateway Después de Restaurar

## 🚨 Problema: Bad Gateway (502)

Después de restaurar el `dashboard.html`, aparece el error "Bad Gateway". Esto significa que Traefik no puede alcanzar el contenedor del dashboard.

---

## 🔍 Diagnóstico Rápido

### Paso 1: Verificar que el Contenedor Está Corriendo

```bash
# Conectarte al servidor
ssh usuario@tu-servidor

# Ver todos los contenedores
docker ps

# Buscar el contenedor del dashboard
docker ps | grep dashboard
```

**Si NO está corriendo:**
```bash
# Ver todos los contenedores (incluso detenidos)
docker ps -a | grep dashboard

# Iniciar el contenedor
docker start checkin24hs-dashboard-1  # ← Cambia el nombre
```

**Si está corriendo pero sigue dando Bad Gateway:** Continúa con el siguiente paso.

---

### Paso 2: Verificar los Logs del Contenedor

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto

# Ver los últimos logs
docker logs $CONTAINER_NAME --tail 50

# Ver logs en tiempo real
docker logs -f $CONTAINER_NAME
```

**Busca errores como:**
- `Error: Cannot find module`
- `SyntaxError`
- `EADDRINUSE` (puerto en uso)
- `ENOENT` (archivo no encontrado)

---

### Paso 3: Verificar que el Archivo Existe y es Válido

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto

# Verificar que el archivo existe
docker exec $CONTAINER_NAME ls -lh /usr/share/nginx/html/dashboard.html

# Verificar que es un HTML válido
docker exec $CONTAINER_NAME head -5 /usr/share/nginx/html/dashboard.html
```

**Debe mostrar:**
```
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
```

---

### Paso 4: Verificar que el Servidor Responde

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto

# Obtener la IP del contenedor
CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_NAME)

# Probar si responde
curl -I http://$CONTAINER_IP:3000  # O el puerto que uses
```

**Si NO responde:** El contenedor puede tener un problema interno.

---

## 🔧 Soluciones Comunes

### Solución 1: Reiniciar el Contenedor

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto

# Reiniciar el contenedor
docker restart $CONTAINER_NAME

# Esperar 10 segundos
sleep 10

# Verificar que está corriendo
docker ps | grep $CONTAINER_NAME
```

---

### Solución 2: Verificar y Corregir Traefik

```bash
# Ver la configuración de Traefik
docker service ls | grep traefik

# Obtener el ID del servicio Traefik
TRAEFIK_SERVICE=$(docker service ls | grep traefik | awk '{print $1}')

# Forzar actualización de Traefik
docker service update --force $TRAEFIK_SERVICE

# Esperar 10 segundos
sleep 10
```

---

### Solución 3: Verificar la Red Docker

```bash
# Ver las redes disponibles
docker network ls

# Verificar que el contenedor está en la red correcta
docker inspect $CONTAINER_NAME | grep -A 10 "Networks"

# Verificar que Traefik puede alcanzar el contenedor
docker network inspect traefik_default  # O el nombre de tu red
```

---

### Solución 4: Verificar el Puerto

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto

# Ver qué puertos está usando el contenedor
docker port $CONTAINER_NAME

# Verificar que el puerto 3000 (o el que uses) está expuesto
docker inspect $CONTAINER_NAME | grep -A 10 "Ports"
```

---

### Solución 5: Recrear el Contenedor

Si nada funciona, puedes recrear el contenedor:

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto

# Detener el contenedor
docker stop $CONTAINER_NAME

# Eliminar el contenedor
docker rm $CONTAINER_NAME

# Volver a crear desde EasyPanel o usar docker-compose
# O simplemente reiniciar el servicio desde EasyPanel
```

---

## 🚀 Solución Rápida (Script Automático)

```bash
#!/bin/bash

CONTAINER_NAME="checkin24hs-dashboard-1"  # ← CAMBIA ESTO

echo "🔍 Diagnóstico del Bad Gateway..."
echo ""

# 1. Verificar que el contenedor está corriendo
echo "1. Verificando contenedor..."
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ Contenedor está corriendo"
else
    echo "❌ Contenedor NO está corriendo"
    echo "   Iniciando contenedor..."
    docker start $CONTAINER_NAME
    sleep 5
fi

# 2. Verificar logs
echo ""
echo "2. Verificando logs (últimas 10 líneas)..."
docker logs $CONTAINER_NAME --tail 10

# 3. Reiniciar el contenedor
echo ""
echo "3. Reiniciando contenedor..."
docker restart $CONTAINER_NAME
sleep 10

# 4. Verificar que está corriendo
echo ""
echo "4. Verificando estado..."
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ Contenedor está corriendo"
else
    echo "❌ Contenedor NO está corriendo después del reinicio"
    echo "   Revisa los logs: docker logs $CONTAINER_NAME"
fi

# 5. Verificar Traefik
echo ""
echo "5. Verificando Traefik..."
TRAEFIK_SERVICE=$(docker service ls | grep traefik | awk '{print $1}' | head -1)
if [ -n "$TRAEFIK_SERVICE" ]; then
    echo "   Forzando actualización de Traefik..."
    docker service update --force $TRAEFIK_SERVICE
    sleep 10
    echo "✅ Traefik actualizado"
else
    echo "⚠️  No se encontró servicio Traefik"
fi

echo ""
echo "✅ Diagnóstico completado"
echo "   Espera 30 segundos y prueba el dashboard nuevamente"
```

**Guarda este script como `diagnosticar_bad_gateway.sh` y ejecútalo:**

```bash
chmod +x diagnosticar_bad_gateway.sh
./diagnosticar_bad_gateway.sh
```

---

## 📋 Comandos Rápidos (Copia y Pega)

```bash
# Configurar variables
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← CAMBIA ESTO

# 1. Verificar contenedor
docker ps | grep $CONTAINER_NAME

# 2. Ver logs
docker logs $CONTAINER_NAME --tail 20

# 3. Reiniciar contenedor
docker restart $CONTAINER_NAME
sleep 10

# 4. Verificar estado
docker ps | grep $CONTAINER_NAME

# 5. Actualizar Traefik
TRAEFIK_SERVICE=$(docker service ls | grep traefik | awk '{print $1}' | head -1)
docker service update --force $TRAEFIK_SERVICE
sleep 10
```

---

## ✅ Verificación Final

Después de aplicar las soluciones:

1. **Espera 30 segundos** para que los servicios se reinicien
2. **Abre el dashboard:** `https://dashboard.checkin24hs.com`
3. **Presiona Ctrl+F5** (limpiar caché)
4. **Verifica que carga correctamente**

---

## 🆘 Si Nada Funciona

### Opción 1: Recrear el Servicio desde EasyPanel

1. Ve a EasyPanel
2. Busca el servicio "dashboard"
3. Elimina el servicio
4. Crea un nuevo servicio con la misma configuración
5. Espera a que se despliegue

### Opción 2: Verificar el Archivo Restaurado

```bash
# Verificar que el archivo no tiene errores de sintaxis
docker exec $CONTAINER_NAME node -c /usr/share/nginx/html/dashboard.html 2>&1 || echo "No es un archivo JS válido (normal para HTML)"

# Verificar que el archivo tiene contenido
docker exec $CONTAINER_NAME wc -l /usr/share/nginx/html/dashboard.html
```

### Opción 3: Restaurar desde Backup

```bash
# Si creaste un backup antes de restaurar
CONTAINER_NAME="checkin24hs-dashboard-1"
docker exec $CONTAINER_NAME cp /tmp/dashboard_backup_servidor_*.html /usr/share/nginx/html/dashboard.html
docker restart $CONTAINER_NAME
```

---

## 💡 Tips

- **Siempre espera 10-30 segundos** después de reiniciar servicios
- **Limpia el caché del navegador** (Ctrl+F5) después de cambios
- **Revisa los logs** si el problema persiste
- **Verifica que el contenedor está en la red correcta** de Docker

---

## 📞 Si Necesitas Más Ayuda

Dime:
1. ¿El contenedor está corriendo? (`docker ps | grep dashboard`)
2. ¿Qué muestran los logs? (`docker logs checkin24hs-dashboard-1 --tail 20`)
3. ¿Qué error específico ves en el navegador?

