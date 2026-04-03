# 🔍 Verificar Alias DNS del Dashboard

## 📊 Estado Actual

- ✅ Contenedores en `easypanel-checkin24hs`: IPs 10.0.2.43, 10.0.2.44, 10.0.2.48, 10.0.2.52, 10.0.2.55, 10.0.2.58
- ❌ Alias `checkin24hs_dashboard` apunta a `10.0.2.104` (IP inexistente)

## 🔍 Comandos de Diagnóstico

### Paso 1: Verificar si el alias está configurado en la red

```bash
# Ver configuración completa de la red easypanel-checkin24hs
docker network inspect easypanel-checkin24hs | grep -B 5 -A 15 "checkin24hs_dashboard" | head -30
```

### Paso 2: Verificar configuración del servicio (aliases)

```bash
# Ver aliases configurados en el servicio
docker service inspect checkin24hs_dashboard | grep -A 20 "Aliases"
```

### Paso 3: Probar conexión a una IP real de easypanel-checkin24hs

```bash
# Probar conexión a 10.0.2.44 (que sabemos que funciona)
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://10.0.2.44:3000/
```

### Paso 4: Verificar si hay un contenedor antiguo con IP 10.0.2.104

```bash
# Ver todos los contenedores (incluyendo detenidos)
docker ps -a | grep dashboard
```

---

**El problema es que el alias apunta a una IP que no existe. Necesitamos verificar la configuración del alias.**
