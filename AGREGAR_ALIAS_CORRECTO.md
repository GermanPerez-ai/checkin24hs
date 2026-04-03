# 🔧 Agregar Alias Correctamente al Servicio Docker

## 🎯 Comando Correcto

Necesitamos especificar la red al agregar el alias. Hay dos redes, necesitamos agregar el alias a ambas.

### Paso 1: Obtener los IDs de las Redes

```bash
# Obtener los IDs de las redes
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq -r '.[].Target'
```

### Paso 2: Agregar el Alias a Cada Red

```bash
# Agregar alias a la primera red
docker service update \
  --network-add target=xmv09tpxwryie79b0jv531623,alias=checkin24hs_dashboard \
  checkin24hs_dashboard

# Agregar alias a la segunda red
docker service update \
  --network-add target=nvhtv52umzihypz8u7adejvpo,alias=checkin24hs_dashboard \
  checkin24hs_dashboard
```

### Paso 3: Verificar

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Deberías ver `checkin24hs_dashboard` (con guión bajo) en ambas redes.

---

## ⚠️ Nota

Si el comando `--network-add` no funciona porque la red ya está agregada, necesitamos usar `--network-rm` primero y luego `--network-add` con todos los aliases.

---

**Ejecuta los comandos y comparte el resultado.**
