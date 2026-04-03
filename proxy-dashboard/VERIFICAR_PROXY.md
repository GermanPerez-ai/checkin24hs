# ✅ Verificar que el Proxy Funciona

## Paso 1: Probar el health check del proxy

```bash
# Obtener el ID del proxy
PROXY_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)

# Probar el health check
docker exec $PROXY_ID wget -qO- http://localhost/health
```

Debería devolver: `healthy`

## Paso 2: Probar que el proxy conecta al dashboard

```bash
# Obtener el nombre del dashboard
DASHBOARD_NAME=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

# Probar desde el proxy hacia el dashboard
docker exec $PROXY_ID wget -qO- http://$DASHBOARD_NAME:3000/health
```

Debería devolver algo como: `{"status":"OK","message":"Servidor funcionando correctamente"}`

## Paso 3: Verificar configuración del dominio en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → `dashboard-proxy`
2. Verifica que el dominio `dashboard.checkin24hs.com` esté configurado
3. El destino debería ser: `http://checkin24hs_dashboard-proxy:80/` (generado automáticamente por EasyPanel)

## Paso 4: Probar desde el navegador

1. Espera 30-60 segundos después de verificar la configuración
2. Abre: `https://dashboard.checkin24hs.com/`
3. Debería cargar el dashboard

---

## Si no funciona, verificar logs:

```bash
# Logs del proxy
docker service logs checkin24hs_dashboard-proxy --tail 20

# Logs del dashboard
docker service logs checkin24hs_dashboard --tail 20
```
