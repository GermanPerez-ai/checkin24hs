# 🔧 Solución Directa: Bad Gateway

## 🚨 Problema

**Bad Gateway** = Traefik recibe la solicitud pero no puede conectarse al servicio.

## ✅ Solución Rápida

El problema es que en la configuración del dominio, el puerto debe ser el **puerto INTERNO** (3000), no el externo (30002).

### En EasyPanel:

1. **Ve a** → **Servicios** → **dashboard** → **Dominios**
2. **Edita el dominio** `dashboard.checkin24hs.com`
3. **Cambia el puerto** de `30002` a `3000` (puerto interno)
4. **Target Service**: `checkin24hs-dashboard` (con guión)
5. **Guarda** y espera 10 segundos

### Si eso no funciona, usa la IP directa:

1. **Edita el dominio** de nuevo
2. **Target Service**: Cambia de `checkin24hs-dashboard` a `10.11.125.9:3000` (IP directa)
3. **Puerto**: `3000`
4. **Guarda**

## 🔍 Verificación Rápida

Desde SSH, ejecuta:

```bash
# Verificar que el servicio está corriendo
docker service ps checkin24hs_dashboard

# Probar desde Traefik
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -5
```

Si el segundo comando funciona, el problema es solo la configuración del dominio. Si no funciona, usamos la IP directa.

