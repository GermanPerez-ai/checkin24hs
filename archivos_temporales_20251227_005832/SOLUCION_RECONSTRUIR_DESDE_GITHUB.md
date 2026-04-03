# 🔧 Solución: Reconstruir Dashboard desde GitHub

## 🚨 Problema

El dashboard está mostrando datos de prueba viejos (Hotel Plaza Mayor, etc.) en lugar de la versión actualizada de GitHub.

## ✅ Solución: Verificar y Reconstruir desde GitHub

### Paso 1: Verificar la Configuración de la Fuente en EasyPanel

1. **Ve a EasyPanel** → **Servicios** → **dashboard**
2. **Haz clic en "Fuente"** o **"Source"** en el menú lateral
3. **Verifica**:
   - **Tipo**: Debe ser **"GitHub"** o **"Git"**
   - **Propietario**: `GermanPerez-ai` (o tu usuario)
   - **Repositorio**: `checkin24hs`
   - **Rama**: `main` (o la rama correcta)
   - **Ruta de compilación**: `/checkin24hs-admin` (debe apuntar a la carpeta del admin)

### Paso 2: Forzar Reconstrucción

1. **En la misma página de "Fuente"**, busca un botón:
   - **"Reconstruir"** o **"Rebuild"**
   - **"Sincronizar"** o **"Sync"**
   - **"Actualizar"** o **"Update"**
2. **Haz clic** para forzar la descarga del código más reciente de GitHub
3. **Espera** a que termine la descarga

### Paso 3: Verificar el Build

1. **Ve a "Implementaciones"** o **"Deployments"** en el menú lateral
2. **Verifica** que haya una nueva implementación iniciándose
3. **Espera** a que termine (debería mostrar "Running" en verde)

### Paso 4: Limpiar Cache del Navegador

1. **Abre el navegador** en modo incógnito
2. **O limpia la cache**: `Ctrl+Shift+Delete` → Limpiar cache
3. **Accede de nuevo** a `https://dashboard.checkin24hs.com`

## 🔍 Si No Funciona

### Verificar en GitHub

1. **Ve a tu repositorio en GitHub**: `https://github.com/GermanPerez-ai/checkin24hs`
2. **Verifica** que la carpeta `checkin24hs-admin` tenga el código actualizado
3. **Verifica** que los últimos commits estén en la rama `main`

### Forzar Rebuild desde SSH

Si EasyPanel no reconstruye automáticamente:

```bash
# Ver la configuración actual del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Spec.Labels}}' | jq

# Forzar actualización del servicio (esto debería reconstruir)
docker service update --force checkin24hs_dashboard

# Ver los logs para verificar que está reconstruyendo
docker service logs checkin24hs_dashboard --tail 50 -f
```

## 🎯 Lo Más Importante

**La "Ruta de compilación" debe ser `/checkin24hs-admin`** para que EasyPanel sepa dónde está el código del dashboard.

Si está en `/` o en otra ruta, EasyPanel está construyendo el código incorrecto.

