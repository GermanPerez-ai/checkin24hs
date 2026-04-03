# 🔍 Diagnóstico: Puerto 3000 No Accesible

## 🚨 Problema

- ✅ El alias `checkin24hs-dashboard` se resuelve a `10.11.52.98`
- ❌ El puerto 3000 no es accesible desde la red Docker Swarm
- ❌ El servicio responde en `localhost:3000` pero no desde la red interna

## 🔍 Verificaciones Necesarias

### 1. Verificar que el Servicio Esté Escuchando en 0.0.0.0

```bash
# Ver los logs del servicio para confirmar que escucha en 0.0.0.0:3000
docker service logs checkin24hs_dashboard --tail 20 | grep -i "listening\|running\|server"

# O ver todos los logs recientes
docker service logs checkin24hs_dashboard --tail 50
```

### 2. Verificar la Configuración del Puerto en el Servicio

```bash
# Ver la configuración de puertos del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# Ver la configuración completa del servicio
docker service inspect checkin24hs_dashboard --pretty | grep -A 10 Ports
```

### 3. Probar desde Dentro del Contenedor del Servicio

```bash
# Obtener el ID de un contenedor del servicio
docker service ps checkin24hs_dashboard --no-trunc

# Conectarse al contenedor y verificar
docker exec -it <CONTAINER_ID> sh

# Dentro del contenedor:
# wget -O- http://localhost:3000
# O
# curl http://localhost:3000
```

### 4. Verificar el Mapeo de Puertos

```bash
# Ver qué puertos están expuestos
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# Verificar si el puerto 3000 está publicado
docker service ls | grep dashboard
```

## 🎯 Posibles Causas

1. **El servidor no está escuchando en 0.0.0.0**: Está escuchando solo en `localhost` o `127.0.0.1`
2. **El puerto no está expuesto en Docker Swarm**: El puerto 3000 no está publicado en la configuración del servicio
3. **Firewall o reglas de red**: Alguna regla está bloqueando el puerto 3000 en la red interna
4. **El servicio no está corriendo correctamente**: El proceso se inició pero no está escuchando

## ✅ Soluciones

### Solución 1: Verificar y Corregir server.js

El archivo `checkin24hs-admin/server.js` debe escuchar en `0.0.0.0`:

```javascript
server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running at http://0.0.0.0:${PORT}/`);
});
```

### Solución 2: Exponer el Puerto en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **dashboard**
2. Busca la sección **"Ports"** o **"Puertos"**
3. Verifica que esté configurado: `3000:3000` (externo:interno)
4. Si no está, agrégalo y guarda

### Solución 3: Verificar Variables de Entorno

En EasyPanel, verifica que no haya una variable `PORT` que esté sobrescribiendo el puerto.

