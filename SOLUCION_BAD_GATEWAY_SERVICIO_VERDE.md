# 🔧 Solución: Bad Gateway con Servicio en Verde

## 🚨 Problema

- ✅ El servicio existe en EasyPanel
- ✅ El servicio está en verde (corriendo)
- ❌ Pero sigue dando Bad Gateway

**Esto significa que el servicio está corriendo pero Traefik no puede alcanzarlo.**

---

## 🔍 Diagnóstico

### Paso 1: Ver Logs del Servicio desde EasyPanel

1. **Haz clic en el servicio "dashboard" en EasyPanel**
2. **Ve a la pestaña "Logs"**
3. **Revisa los últimos logs:**
   - ¿Hay errores?
   - ¿El servidor se inició correctamente?
   - ¿Está escuchando en el puerto correcto?

**Busca mensajes como:**
- `Server listening on port 3000`
- `Error: Cannot find module`
- `EADDRINUSE` (puerto en uso)
- `ENOENT` (archivo no encontrado)

---

### Paso 2: Verificar la Configuración del Servicio

En EasyPanel, verifica:

1. **Puerto:**
   - ¿Está configurado el puerto `3000`?
   - ¿El puerto interno y externo coinciden?

2. **Red:**
   - ¿Está en la red `traefik` o la red correcta?
   - ¿Está en la misma red que Traefik?

3. **Dominio:**
   - ¿Está configurado `dashboard.checkin24hs.com`?
   - ¿HTTPS está activado?

---

### Paso 3: Verificar desde SSH

Ejecuta estos comandos en el servidor:

```bash
# 1. Ver todos los contenedores (ahora debería aparecer)
docker ps

# 2. Buscar el contenedor del dashboard
docker ps | grep dashboard

# 3. Ver logs del contenedor
docker logs $(docker ps -q -f name=dashboard) --tail 50

# 4. Verificar la IP del contenedor
docker inspect $(docker ps -q -f name=dashboard) | grep -A 10 "Networks"

# 5. Verificar que Traefik puede alcanzarlo
docker network inspect traefik_default | grep -A 5 "Containers"
```

---

## 🔧 Soluciones

### Solución 1: Reiniciar el Servicio desde EasyPanel

1. **Haz clic en el servicio "dashboard"**
2. **Busca el botón "Restart" o "Reiniciar"**
3. **Haz clic y espera 1-2 minutos**
4. **Prueba el dashboard nuevamente**

---

### Solución 2: Verificar y Corregir la Red

Si el servicio no está en la red correcta:

1. **En EasyPanel:**
   - Haz clic en el servicio "dashboard"
   - Ve a "Settings" o "Configuración"
   - Verifica la red: debe estar en `traefik` o la red correcta
   - Si no está, cámbiala y guarda

2. **O desde SSH:**
   ```bash
   # Ver redes disponibles
   docker network ls
   
   # Ver la red de Traefik
   docker network inspect traefik_default
   
   # Conectar el contenedor a la red correcta
   docker network connect traefik_default $(docker ps -q -f name=dashboard)
   ```

---

### Solución 3: Reiniciar Traefik

```bash
# Encontrar el servicio Traefik
docker service ls | grep traefik

# O si es un contenedor
docker ps | grep traefik

# Reiniciar Traefik
docker service update --force $(docker service ls -q -f name=traefik)

# O si es contenedor
docker restart $(docker ps -q -f name=traefik)
```

---

### Solución 4: Verificar el Puerto

```bash
# Ver qué puerto está usando el contenedor
docker port $(docker ps -q -f name=dashboard)

# Verificar que el puerto 3000 está expuesto
docker inspect $(docker ps -q -f name=dashboard) | grep -A 10 "Ports"
```

**Si el puerto no está correcto:**
- En EasyPanel, verifica la configuración del puerto
- Debe ser `3000` (o el que uses)
- Guarda y reinicia el servicio

---

### Solución 5: Verificar la Configuración de Traefik

```bash
# Ver la configuración de Traefik para el dashboard
docker exec $(docker ps -q -f name=traefik) cat /etc/traefik/traefik.yml | grep -A 10 dashboard

# O ver los labels del contenedor
docker inspect $(docker ps -q -f name=dashboard) | grep -A 20 "Labels"
```

**Busca:**
- `traefik.http.routers.dashboard`
- `traefik.http.services.dashboard`
- La configuración del dominio y puerto

---

## 🚀 Solución Rápida (Script)

Crea este script y ejecútalo:

```bash
#!/bin/bash

echo "🔍 Diagnóstico del Bad Gateway con servicio en verde..."
echo ""

# 1. Encontrar el contenedor del dashboard
DASHBOARD_CONTAINER=$(docker ps -q -f name=dashboard | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró el contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor encontrado: $DASHBOARD_CONTAINER"
echo ""

# 2. Ver logs
echo "📋 Logs del contenedor (últimas 20 líneas):"
docker logs $DASHBOARD_CONTAINER --tail 20
echo ""

# 3. Verificar puerto
echo "📋 Puerto del contenedor:"
docker port $DASHBOARD_CONTAINER
echo ""

# 4. Verificar red
echo "📋 Red del contenedor:"
docker inspect $DASHBOARD_CONTAINER | grep -A 10 "Networks"
echo ""

# 5. Reiniciar el contenedor
echo "🔄 Reiniciando contenedor..."
docker restart $DASHBOARD_CONTAINER
sleep 10
echo ""

# 6. Reiniciar Traefik
echo "🔄 Reiniciando Traefik..."
TRAEFIK_SERVICE=$(docker service ls -q -f name=traefik | head -1)
if [ -n "$TRAEFIK_SERVICE" ]; then
    docker service update --force $TRAEFIK_SERVICE
    echo "✅ Traefik reiniciado"
else
    TRAEFIK_CONTAINER=$(docker ps -q -f name=traefik | head -1)
    if [ -n "$TRAEFIK_CONTAINER" ]; then
        docker restart $TRAEFIK_CONTAINER
        echo "✅ Traefik reiniciado"
    else
        echo "⚠️  No se encontró Traefik"
    fi
fi

echo ""
echo "✅ Diagnóstico completado"
echo "   Espera 30 segundos y prueba el dashboard nuevamente"
```

**Guarda como `diagnosticar_servicio_verde.sh` y ejecuta:**

```bash
chmod +x diagnosticar_servicio_verde.sh
./diagnosticar_servicio_verde.sh
```

---

## 📋 Comandos Rápidos (Copia y Pega)

```bash
# 1. Ver contenedor del dashboard
docker ps | grep dashboard

# 2. Ver logs
docker logs $(docker ps -q -f name=dashboard) --tail 30

# 3. Reiniciar dashboard
docker restart $(docker ps -q -f name=dashboard)
sleep 10

# 4. Reiniciar Traefik
docker service update --force $(docker service ls -q -f name=traefik)
# O si es contenedor:
docker restart $(docker ps -q -f name=traefik)
sleep 10
```

---

## ✅ Verificación Final

1. **Espera 30 segundos** después de reiniciar
2. **Abre el dashboard:** `https://dashboard.checkin24hs.com`
3. **Presiona Ctrl+F5** (limpiar caché)
4. **Verifica que carga correctamente**

---

## 🆘 Si Sigue Fallando

1. **Revisa los logs desde EasyPanel:**
   - Ve a "Logs" del servicio
   - Busca errores específicos
   - Comparte los errores que veas

2. **Verifica la configuración:**
   - Puerto correcto
   - Red correcta
   - Dominio correcto

3. **Prueba acceder directamente al puerto:**
   ```bash
   # Obtener la IP del contenedor
   CONTAINER_IP=$(docker inspect $(docker ps -q -f name=dashboard) | grep -A 10 "Networks" | grep IPAddress | awk '{print $2}' | tr -d '",')
   
   # Probar acceso directo
   curl -I http://$CONTAINER_IP:3000
   ```

---

## 💡 Recomendación

**Empieza por:**
1. Ver los logs del servicio desde EasyPanel
2. Reiniciar el servicio desde EasyPanel
3. Reiniciar Traefik desde SSH
4. Esperar 30 segundos
5. Probar el dashboard

¿Puedes revisar los logs del servicio en EasyPanel y decirme qué ves? ¿Hay algún error específico?
