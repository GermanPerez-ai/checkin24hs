# 🔍 Probar Alias con Guión

## 📊 Estado Actual

- ⚠️ **4 contenedores activos** (debería haber 1)
- ✅ Servicio actualizado

## 🔍 Comandos

### Paso 1: Probar resolución DNS del alias con guión

```bash
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup checkin24hs-dashboard
```

### Paso 2: Probar conexión con alias con guión

```bash
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://checkin24hs-dashboard:3000/
```

### Paso 3: Probar también el alias con guión bajo (por si acaso)

```bash
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup checkin24hs_dashboard
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://checkin24hs_dashboard:3000/
```

---

**Ejecuta estos comandos para ver cuál alias funciona.**
