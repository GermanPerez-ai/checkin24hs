# 🔧 Solución: Limpiar Contenedores Antiguos y Actualizar DNS

## 📊 Problema Identificado

- ❌ **5 contenedores activos** (debería haber 1)
- ❌ **DNS resuelve a IP antigua** (`10.0.2.104`)
- ✅ **Servicio funciona** (200 OK en IPs directas)

## 🔧 Solución

### Paso 1: Forzar Actualización del Servicio

```bash
# Forzar actualización del servicio para limpiar contenedores antiguos
docker service update --force checkin24hs_dashboard
```

### Paso 2: Esperar y Verificar

```bash
# Esperar 30 segundos y verificar contenedores
sleep 30
docker ps | grep dashboard
```

### Paso 3: Probar Alias con Guión (checkin24hs-dashboard)

El alias `checkin24hs-dashboard` (con guión) está configurado en ambas redes:

```bash
# Probar resolución DNS del alias con guión
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup checkin24hs-dashboard

# Probar conexión con alias con guión
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://checkin24hs-dashboard:3000/
```

### Paso 4: Si el Paso 3 funciona, actualizar EasyPanel

Si `checkin24hs-dashboard` funciona, actualiza el dominio en EasyPanel para usar:
- Destino: `http://checkin24hs-dashboard:3000/` (con guión, no guión bajo)

---

**Ejecuta primero el Paso 1 y espera 30 segundos. Luego prueba el Paso 3.**
