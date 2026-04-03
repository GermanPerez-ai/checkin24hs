# 🔍 Verificar por qué el Alias No Funciona

## 🎯 Problema

El alias `checkin24hs_dashboard` no se puede resolver desde la red Docker.

## ✅ Verificaciones

### Paso 1: Verificar que el Alias Sigue Estar

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Verifica que `checkin24hs_dashboard` (guión bajo) esté en la lista.

### Paso 2: Probar con el Alias que SÍ Funciona

```bash
# Probar con el alias que sabemos que funciona (con guión)
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://checkin24hs-dashboard:3000/
```

Si este funciona, el problema es que el alias con guión bajo no se está resolviendo correctamente.

### Paso 3: Verificar Contenedores del Servicio

```bash
# Ver contenedores actuales
docker ps | grep dashboard

# Ver en qué red están
docker inspect $(docker ps | grep dashboard | head -1 | awk '{print $1}') | jq '.[0].NetworkSettings.Networks | keys'
```

### Paso 4: Verificar DNS en la Red

```bash
# Probar resolución DNS
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup checkin24hs_dashboard
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup checkin24hs-dashboard
```

---

**Ejecuta estos comandos para diagnosticar el problema. Empieza con el Paso 1 y 2.**
