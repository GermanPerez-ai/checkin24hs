# 🔧 Usar Alias con Guión que Sí Existe

## Problema
EasyPanel genera `checkin24hs_dashboard-proxy` (con guión bajo) pero el servicio tiene `checkin24hs-dashboard-proxy` (con guión).

## Solución: Verificar si el alias con guión funciona

El servicio tiene estos aliases:
- `checkin24hs-dashboard-proxy` (con guión) ✅
- `dashboard-proxy` ✅

### Paso 1: Probar si el alias con guión funciona

```bash
# Probar resolución del alias con guión
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest nslookup checkin24hs-dashboard-proxy

# Probar conexión con el alias con guión
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest curl -I http://checkin24hs-dashboard-proxy:80/
```

### Paso 2: Si funciona, verificar configuración en EasyPanel

En EasyPanel, el dominio `dashboard.checkin24hs.com` debería estar configurado con destino:
- `http://checkin24hs-dashboard-proxy:80/` (con guión, no guión bajo)

Si EasyPanel genera automáticamente `checkin24hs_dashboard-proxy` (con guión bajo), necesitaremos otra solución.

### Opción Alternativa: Usar el alias `dashboard-proxy`

Si el alias con guión no funciona o EasyPanel no lo acepta, podemos intentar usar el alias más corto:

```bash
# Probar el alias dashboard-proxy
docker run --rm --network nvhtv52umzihypz8u7adejvpo curlimages/curl:latest curl -I http://dashboard-proxy:80/
```

---

**Si ninguno de estos aliases funciona desde Traefik, necesitaremos una solución diferente, como hacer que el proxy esté en el mismo servicio que el dashboard o usar una IP fija.**
