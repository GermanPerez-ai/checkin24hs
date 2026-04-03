# 🚀 Pasos para Hoy - Configurar Dashboard

## Estado Actual
- ✅ `server.js` configurado en puerto **3000**
- ✅ Proxy Nginx configurado para redirigir al puerto **3000**
- ⚠️ Necesitamos actualizar el proxy con el contenedor activo actual

## Paso 1: Verificar servicios en el servidor

Conéctate al servidor y ejecuta:

```bash
# Ver servicios dashboard
docker service ls | grep dashboard

# Ver contenedores activos
docker ps | grep dashboard
```

## Paso 2: Actualizar el proxy con el contenedor activo

Ejecuta el script de actualización del proxy:

```bash
cd /ruta/donde/esta/proxy-dashboard
./actualizar-proxy-directo.sh
```

Este script:
- Encuentra el contenedor activo del dashboard
- Actualiza el `nginx.conf` del proxy
- Recarga Nginx

## Paso 3: Configurar dominio en EasyPanel

**IMPORTANTE**: El dominio debe apuntar al servicio `dashboard-proxy`, NO al `dashboard`.

1. Ve a **EasyPanel** → **Servicios** → `dashboard-proxy`
2. Si no existe el servicio `dashboard-proxy`, créalo:
   - Tipo: **Dockerfile**
   - Build Path: `/proxy-dashboard` (o donde esté el proxy)
   - Puerto interno: **80**
3. En la sección **"Dominios"**:
   - Agrega o edita: `dashboard.checkin24hs.com`
   - El destino debería ser: `http://checkin24hs_dashboard-proxy:80/` (EasyPanel lo genera automáticamente)
4. Guarda los cambios

## Paso 4: Verificar que el dashboard esté corriendo

En EasyPanel → Servicio `dashboard`:
- Verifica que esté **verde** (corriendo)
- Pestaña **"Entorno"**: Debe tener `PORT=3000`
- Pestaña **"Logs"**: Debe mostrar `Servidor iniciado en http://0.0.0.0:3000`

## Paso 5: Probar

1. Espera 30-60 segundos después de guardar
2. Abre: `https://dashboard.checkin24hs.com/`
3. Debería cargar el dashboard

---

## Si no funciona

### Verificar logs del proxy:
```bash
docker service logs checkin24hs_dashboard-proxy --tail 50
```

### Verificar que el proxy puede conectar al dashboard:
```bash
# Desde dentro del contenedor del proxy
docker exec <proxy_container_id> wget -O- http://checkin24hs_dashboard.1.<id>:3000/
```

### Verificar configuración de Traefik:
```bash
docker service logs traefik --tail 50 | grep dashboard
```
