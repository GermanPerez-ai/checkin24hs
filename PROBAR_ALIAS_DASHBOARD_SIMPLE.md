# 🔍 Probar Alias "dashboard"

## 📊 Estado Actual

- ❌ `checkin24hs-dashboard` resuelve a IP antigua (`10.0.2.104`)
- ❌ `checkin24hs_dashboard` no se resuelve (SERVFAIL)
- ✅ Alias `dashboard` está configurado en el servicio

## 🔍 Comandos

### Paso 1: Probar alias "dashboard"

```bash
# Probar resolución DNS del alias "dashboard"
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard

# Probar conexión con alias "dashboard"
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://dashboard:3000/
```

### Paso 2: Si funciona, actualizar EasyPanel

Si `dashboard:3000` funciona, actualiza el dominio en EasyPanel para usar:
- Destino: `http://dashboard:3000/`

### Paso 3: Si no funciona, limpiar contenedores antiguos manualmente

```bash
# Ver todos los contenedores (incluyendo detenidos)
docker ps -a | grep dashboard

# Detener y eliminar contenedores antiguos (excepto el más reciente)
# CUIDADO: Solo elimina contenedores que NO sean el más reciente
docker stop <container_id_antiguo>
docker rm <container_id_antiguo>
```

---

**Primero prueba el Paso 1 con el alias "dashboard".**
