# 🔧 Solución A: Agregar Alias Docker

## 📊 Información Necesaria

Necesitamos identificar:
1. El nombre exacto del servicio del dashboard
2. El nombre de la red donde está Traefik

## 🔍 Paso 1: Identificar Red de Traefik

```bash
# Ver redes de Traefik
docker service inspect traefik | grep -A 10 "Networks"

# Ver todas las redes
docker network ls | grep -E "traefik|easypanel"
```

## 🔍 Paso 2: Identificar Red Compartida

```bash
# Ver en qué red está el servicio dashboard
docker service inspect checkin24hs_dashboard | grep -A 10 "Networks"

# Ver en qué red está Traefik
docker service inspect traefik | grep -A 10 "Networks"
```

## 🔧 Paso 3: Agregar Alias al Servicio Dashboard

Una vez identificada la red compartida, agregaremos el alias `checkin24hs_dashboard` a esa red:

```bash
# Ejemplo (ajustar según la red real):
docker service update \
  --network-rm <nombre_red_actual> \
  --network-add name=<nombre_red_actual>,alias=checkin24hs_dashboard \
  checkin24hs_dashboard
```

---

**Ejecuta primero los Pasos 1-2 para identificar las redes. Luego te daré el comando exacto para agregar el alias.**
