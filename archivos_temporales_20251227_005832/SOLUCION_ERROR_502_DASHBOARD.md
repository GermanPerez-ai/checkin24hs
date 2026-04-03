# 🔧 Solución: Error 502 en Dashboard

## 🚨 Problema

Error 502 = Traefik recibe la solicitud pero no puede conectarse al servicio backend.

## ✅ Solución: Verificar Configuración del Dominio

### Paso 1: Verificar Configuración del Dominio

1. **Ve a EasyPanel** → **Servicios** → **dashboard** → **Dominios**
2. **Edita el dominio** `dashboard.checkin24hs.com`
3. **Verifica EXACTAMENTE**:
   - **Puerto**: Debe ser `3000` (puerto interno del contenedor)
   - **Target Service**: Debe ser `checkin24hs-dashboard` (con guión, NO con guión bajo)
   - **Protocolo**: `HTTP`
4. **Guarda** los cambios
5. **Espera 15-20 segundos** para que Traefik actualice

### Paso 2: Si No Funciona, Usar IP Directa

Si el alias no funciona:

1. **Edita el dominio** de nuevo
2. **Target Service**: Cambia a la IP directa del contenedor
   - Primero necesitamos obtener la IP actual del contenedor
3. **Puerto**: `3000`

### Paso 3: Verificar Estado del Servicio

En EasyPanel:
1. **Ve a** → **Servicios** → **dashboard**
2. **Verifica** que esté en **verde** (Running)
3. Si está en amarillo o rojo, **ve a "Logs"** y comparte los errores

### Paso 4: Reiniciar el Servicio

1. En la página del servicio dashboard
2. **Haz clic en el botón de reiniciar** (icono de flecha circular)
3. **Espera** a que termine de reiniciar
4. **Prueba de nuevo** en el navegador

## 🔍 Verificación desde SSH (Si Tienes Acceso)

```bash
# Ver estado del servicio
docker service ps checkin24hs_dashboard

# Ver logs recientes
docker service logs checkin24hs_dashboard --tail 20

# Obtener IP del contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}')
docker inspect $CONTAINER_ID | jq -r '.[0].NetworkSettings.Networks.easypanel.IPAddress'

# Probar acceso directo
curl http://localhost:30002 | head -5
```

## 🎯 Lo Más Probable

El problema más común es que:
- El **puerto en el dominio** está mal (debe ser 3000, no 30002)
- O el **Target Service** está mal escrito (debe ser `checkin24hs-dashboard` con guión)

---

**Primero verifica la configuración del dominio (puerto 3000, target service correcto) y guarda. Luego espera 15 segundos y prueba de nuevo.**

