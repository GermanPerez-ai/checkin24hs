# 🔧 Solución: Bad Gateway Después de Reconstruir

## 🚨 Problema

Después de reconstruir, aparece "Bad Gateway". Esto significa que:
- El servicio se reconstruyó pero no está corriendo
- O Traefik no puede conectarse al servicio

## ✅ Verificación Rápida

### Paso 1: Verificar Estado del Servicio

En EasyPanel:
1. **Ve a** → **Servicios** → **dashboard**
2. **Mira el estado** del servicio:
   - ¿Está en **verde** (Running)?
   - ¿Está en **amarillo** (Starting)?
   - ¿Está en **rojo** (Error)?

### Paso 2: Ver los Logs

1. En la página del servicio dashboard, busca **"Logs"** o **"Registros"** en el menú lateral
2. **Haz clic en "Logs"**
3. **Mira los últimos mensajes**:
   - ¿Hay errores?
   - ¿Dice "Server running at http://0.0.0.0:3000/"?
   - ¿Hay algún error de compilación?

### Paso 3: Verificar Configuración del Dominio

1. **Ve a** → **Servicios** → **dashboard** → **Dominios**
2. **Edita el dominio** `dashboard.checkin24hs.com`
3. **Verifica**:
   - **Puerto**: Debe ser `3000` (puerto interno)
   - **Target Service**: `checkin24hs-dashboard` (con guión)
4. **Guarda** si hiciste cambios

## 🔍 Si el Servicio Está en Rojo o Amarillo

Si el servicio no está en verde:

1. **Ve a "Logs"** y comparte los últimos mensajes
2. Puede haber un error de compilación o de inicio
3. Necesitamos ver el error exacto para solucionarlo

## 🔍 Si el Servicio Está en Verde pero Sigue Bad Gateway

Si el servicio está en verde pero sigue apareciendo Bad Gateway:

1. **Verifica la configuración del dominio** (Paso 3 arriba)
2. **Espera 30 segundos** y recarga la página
3. **Limpia la cache** del navegador de nuevo

## 🆘 Solución Rápida desde SSH

Si necesitas verificar desde SSH:

```bash
# Ver estado del servicio
docker service ps checkin24hs_dashboard

# Ver logs recientes
docker service logs checkin24hs_dashboard --tail 30

# Verificar que está escuchando
docker exec $(docker ps | grep checkin24hs_dashboard | awk '{print $1}') wget -O- http://localhost:3000 2>&1 | head -5
```

---

**Primero dime: ¿El servicio está en verde en EasyPanel? Si no, comparte los logs para ver el error.**

