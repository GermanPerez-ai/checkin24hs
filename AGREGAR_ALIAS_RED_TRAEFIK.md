# ✅ Agregar Alias checkin24hs_dashboard a la Red de Traefik

## 🎯 Información que Ya Tenemos

- **Servicio**: `checkin24hs_dashboard`
- **Redes del servicio**:
  - `xmv09tpxwryie79b0jv531623` (alias: `checkin24hs-dashboard`)
  - `nvhtv52umzihypz8u7adejvpo` (aliases: `checkin24hs-dashboard`, `dashboard`) ← **Esta probablemente es la red de Traefik**

## ✅ Pasos

### Paso 1: Obtener el Nombre de la Red (No Solo el ID)

```bash
# Obtener el nombre de la red que probablemente es la de Traefik
docker network inspect nvhtv52umzihypz8u7adejvpo --format '{{.Name}}'
```

### Paso 2: Verificar si Traefik Está en Esa Red

```bash
# Ver contenedores de Traefik
docker ps | grep traefik

# Ver redes de Traefik
docker inspect $(docker ps | grep traefik | head -1 | awk '{print $1}') | jq '.[0].NetworkSettings.Networks | keys'
```

### Paso 3: Agregar el Alias checkin24hs_dashboard

Una vez confirmado, ejecuta (reemplaza `<nombre_red>` con el nombre real):

```bash
docker service update \
  --network-rm nvhtv52umzihypz8u7adejvpo \
  --network-add name=<nombre_red>,alias=checkin24hs-dashboard,alias=dashboard,alias=checkin24hs_dashboard \
  checkin24hs_dashboard
```

### Paso 4: Verificar que el Alias se Agregó

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Deberías ver `checkin24hs_dashboard` (con guión bajo) en la lista de aliases.

### Paso 5: Probar el Dominio

1. Espera 30-60 segundos para que el servicio se actualice
2. Prueba acceder a: `https://dashboard.checkin24hs.com/`
3. **¿Funciona?**

---

**Ejecuta primero el Paso 1 para obtener el nombre de la red, luego el Paso 2 para verificar, y finalmente el Paso 3 para agregar el alias.**
