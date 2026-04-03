# ✅ Solución: Agregar Alias con Guión Bajo a la Red de Traefik

## 🎯 Solución del Soporte de EasyPanel

El soporte sugiere agregar el alias `checkin24hs_dashboard` (guión bajo) a la red donde está Traefik.

## ✅ Pasos

### Paso 1: Identificar la Red de Traefik

```bash
# Ver todas las redes
docker network ls

# Ver qué red usa Traefik
docker ps | grep traefik
docker inspect $(docker ps | grep traefik | head -1 | awk '{print $1}') | jq '.[0].NetworkSettings.Networks'
```

### Paso 2: Verificar la Red del Servicio Dashboard

```bash
# Ver las redes del servicio dashboard
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Esto mostrará los IDs de las redes. Necesitamos encontrar cuál es la red compartida con Traefik.

### Paso 3: Agregar el Alias a la Red Compartida

Una vez que identifiquemos la red compartida (probablemente `nvhtv52umzihypz8u7adejvpo` que es donde está el alias `dashboard`), ejecutaremos:

```bash
# Obtener el nombre de la red (no solo el ID)
docker network inspect nvhtv52umzihypz8u7adejvpo --format '{{.Name}}'
```

Luego actualizar el servicio:

```bash
docker service update \
  --network-rm nvhtv52umzihypz8u7adejvpo \
  --network-add name=<nombre_red>,alias=checkin24hs-dashboard,alias=dashboard,alias=checkin24hs_dashboard \
  checkin24hs_dashboard
```

---

**Ejecuta primero los comandos del Paso 1 y 2 para identificar la red de Traefik y luego ejecutamos el comando para agregar el alias.**
