# 🔧 Solución: Red de Traefik No Encontrada

## 🚨 Problema Identificado

- ❌ La red `traefik` no existe
- ✅ El servicio está en 2 redes diferentes
- ❌ El alias es `checkin24hs-dashboard` (con guión), pero intentamos conectar con `checkin24hs_dashboard` (con guión bajo)

## 🔍 Diagnóstico

El servicio ya está en 2 redes:
1. Red `lvb2r5b5m4ls3y2jwaj9n2nne` - Alias: `checkin24hs-dashboard`
2. Red `fggi0aimm4b7i8i7tgy4yfwse` - Alias: `checkin24hs-dashboard`, `dashboard`

Necesitamos encontrar la red donde está Traefik.

## ✅ Solución Paso a Paso

### Paso 1: Encontrar la Red de Traefik

```bash
# Ver todas las redes
docker network ls

# Ver en qué red está Traefik
docker ps | grep traefik
docker inspect $(docker ps | grep traefik | awk '{print $1}') | grep -A 10 Networks

# O ver las redes de Traefik directamente
docker inspect traefik | grep -A 10 Networks
```

### Paso 2: Ver los Nombres de las Redes del Servicio

```bash
# Ver los nombres de las redes (no solo los IDs)
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' | xargs -I {} docker network inspect {} --format '{{.Name}}'
```

### Paso 3: Agregar el Servicio a la Red Correcta

Una vez que identifiques la red de Traefik (ej: `traefik_web`, `traefik_default`, etc.):

```bash
docker service update --network-add <NOMBRE_REAL_DE_LA_RED> checkin24hs_dashboard
```

### Paso 4: Usar el Alias Correcto

El alias es `checkin24hs-dashboard` (con guión), así que debemos usar ese nombre en la configuración del dominio.

