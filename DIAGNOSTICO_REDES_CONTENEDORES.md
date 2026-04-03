# 🔍 Diagnóstico: Problema de Redes y Aliases

## 📊 Problemas Identificados

1. ❌ **5 contenedores activos** (debería haber 1 réplica)
2. ❌ **Contenedores en red `easypanel`** (IPs: 10.0.1.47-54)
3. ❌ **Alias apunta a red `easypanel-checkin24hs`** (IP: 10.0.2.104)
4. ❌ **IP del alias no corresponde a ningún contenedor activo**

## 🔍 Comandos de Diagnóstico

### Paso 1: Verificar configuración completa del servicio

```bash
# Ver todas las redes del servicio
docker service inspect checkin24hs_dashboard | grep -A 5 "Networks"

# Ver réplicas configuradas
docker service inspect checkin24hs_dashboard | grep -A 2 "Replicas"
```

### Paso 2: Probar conexión a IPs reales de los contenedores

```bash
# Probar conexión a una IP real (desde la red easypanel-checkin24hs)
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://10.0.1.54:3000/

# O probar desde la red easypanel
docker run --rm --network easypanel curlimages/curl:latest curl -I http://10.0.1.54:3000/
```

### Paso 3: Verificar en qué red está configurado el alias

```bash
# Ver detalles de la red easypanel-checkin24hs
docker network inspect easypanel-checkin24hs | grep -A 10 "checkin24hs_dashboard"
```

### Paso 4: Verificar si los contenedores deberían estar en easypanel-checkin24hs

```bash
# Ver configuración de redes del servicio
docker service inspect checkin24hs_dashboard --pretty | grep -i network
```

---

**Ejecuta estos comandos para identificar el problema de red.**
