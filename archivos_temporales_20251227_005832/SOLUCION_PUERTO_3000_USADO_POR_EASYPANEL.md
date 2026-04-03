# 🔧 Solución: Puerto 3000 Usado por EasyPanel

## ✅ Entendido

El puerto 3000 lo usa EasyPanel para su interfaz web (`http://72.61.58.240:3000`). Por eso el dashboard usa el puerto 30002 externamente.

## 🎯 Configuración Correcta

- **Puerto externo**: 30002 (para acceso directo desde fuera)
- **Puerto interno**: 3000 (donde el servidor escucha dentro del contenedor)
- **En el dominio de Traefik**: Debe usar el puerto **3000** (interno) y el alias `checkin24hs-dashboard`

## ✅ Verificación

En el modal del dominio:
- **Puerto**: `3000` ✅ (correcto - puerto interno)
- **Target Service**: `checkin24hs-dashboard` (con guión) ✅

## 🔍 Si Sigue Sin Funcionar

El problema puede ser que el alias `checkin24hs-dashboard` no funciona correctamente. Necesitamos usar la IP directa del contenedor.

### Obtener la IP del Contenedor

Si tienes acceso SSH, ejecuta:

```bash
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}')
docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Networks.easypanel.IPAddress'
```

Luego en EasyPanel, en el dominio:
- **Target Service**: Cambia a la IP que obtuviste (ej: `10.11.125.9:3000`)
- **Puerto**: `3000`
- **Guarda**

### O Probar desde SSH

```bash
# Probar si el alias funciona
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -5

# Si no funciona, obtener la IP y probar
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}')
EASYPANEL_IP=$(docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Networks.easypanel.IPAddress')
echo "IP del contenedor: $EASYPANEL_IP"
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://$EASYPANEL_IP:3000 2>&1 | head -5
```

---

**El puerto 3000 en el dominio está correcto (es el interno). El problema puede ser el alias. ¿Tienes acceso SSH para obtener la IP del contenedor y probarla?**

