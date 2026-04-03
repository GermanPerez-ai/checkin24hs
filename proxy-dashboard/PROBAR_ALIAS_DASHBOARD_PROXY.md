# ✅ Probar Alias dashboard-proxy

## 📊 Estado Actual

- ✅ Aliases configurados: `checkin24hs-dashboard-proxy` y `dashboard-proxy`
- ✅ Proxy funciona con IP directa (10.0.2.130)

## 🔧 Verificación

### Paso 1: Probar alias dashboard-proxy desde la red correcta

```bash
# Probar resolución DNS del alias dashboard-proxy
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard-proxy

# Probar conexión con el alias dashboard-proxy
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard-proxy:80/
```

### Paso 2: Si funciona, configurar dominio en EasyPanel

1. Ve a EasyPanel → Servicios → `dashboard`
2. Edita el dominio `dashboard.checkin24hs.com`
3. Cambia el destino a: `http://dashboard-proxy:80/`
4. Guarda

### Paso 3: Si NO funciona, usar IP directa o nombre completo

Si el alias no funciona, usa una de estas opciones:

**Opción A: IP directa (temporal)**
- Destino: `http://10.0.2.130:80/`

**Opción B: Nombre completo del contenedor**
- Destino: `http://checkin24hs_dashboard-proxy.1.m1itwcwwap2yllx2e0jun33s8:80/`

---

**Ejecuta el Paso 1. Si funciona (200 OK), usa el Paso 2. Si no funciona, usa el Paso 3.**
