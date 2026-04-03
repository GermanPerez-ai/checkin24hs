# 🔧 Solución: Bad Gateway con Puerto 3000

## 🚨 Problema

El puerto ya está en 3000 pero sigue sin funcionar. Necesitamos verificar otras cosas.

## ✅ Verificaciones Adicionales

### 1. Verificar Target Service

En el modal del dominio:
- **Target Service**: Debe ser `checkin24hs-dashboard` (con guión)
- **NO** debe ser `checkin24hs_dashboard` (con guión bajo)

### 2. Reiniciar el Servicio

1. **Ve a** → **Servicios** → **dashboard**
2. **Haz clic en el botón de reiniciar** (icono de flecha circular)
3. **Espera** a que termine de reiniciar (30 segundos)
4. **Prueba de nuevo**

### 3. Verificar que el Servicio Esté en la Red Correcta

El servicio debe estar en la red `easypanel` donde está Traefik. Esto ya lo verificamos antes y estaba bien.

### 4. Usar IP Directa (Solución Temporal)

Si el alias no funciona, podemos usar la IP directa del contenedor:

1. **Obtén la IP del contenedor** (desde SSH si tienes acceso):
```bash
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}')
docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Networks.easypanel.IPAddress'
```

2. **En EasyPanel**, en el dominio:
   - **Target Service**: Cambia a la IP que obtuviste (ej: `10.11.125.9:3000`)
   - **Puerto**: `3000`
   - **Guarda**

### 5. Verificar Logs de Traefik

Si tienes acceso SSH, puedes verificar los logs de Traefik para ver qué error muestra:

```bash
docker service logs traefik --tail 50 | grep -i dashboard
```

## 🎯 Lo Más Probable

El problema puede ser:
1. **El alias no funciona** → Necesitamos usar la IP directa
2. **Traefik necesita reiniciarse** → Reiniciar el servicio dashboard puede ayudar
3. **El servicio no está accesible desde la red** → Aunque los logs dicen que está corriendo

---

**Primero, reinicia el servicio dashboard y espera 30 segundos. Luego prueba de nuevo.**

**Si sigue sin funcionar, necesitamos obtener la IP del contenedor y usarla directamente en el dominio.**

