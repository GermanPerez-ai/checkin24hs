# 📋 Instrucciones para Aplicar Correcciones en EasyPanel

## ✅ Cambios Realizados Localmente

Se han corregido los siguientes problemas de codificación UTF-8 en `deploy/dashboard.html`:

1. ✅ **Dashboard - Ventas/Gastos Mensuales**: `Mes/A?o` → `Mes/Año`
2. ✅ **Hoteles**: `Ubicaci?n` → `Ubicación`
3. ✅ **Programa Flexi**: 
   - `?Cómo` → `¿Cómo`
   - `Confirmaci?n` → `Confirmación`
   - `Estad?a` → `Estadía`
4. ✅ **Título**: `configuración de Flor IA` → `Configuración de Flor IA`

## 🚀 Pasos para Aplicar en EasyPanel

### Opción 1: Subir manualmente el archivo corregido (RECOMENDADO)

1. **Subir el archivo al servidor**:
   ```bash
   # Desde PowerShell en tu máquina local
   scp deploy/dashboard.html root@TU_SERVIDOR:/root/checkin24hs/dashboard.html
   ```

2. **Copiar al contenedor**:
   ```bash
   # En el servidor (SSH)
   CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
   docker cp /root/checkin24hs/dashboard.html $CONTAINER:/app/dashboard.html
   ```

3. **Recargar la página** con Ctrl+F5

### Opción 2: Usar GitHub (si se resuelve el conflicto)

1. **Resolver el conflicto de Git**:
   ```powershell
   # En PowerShell
   git checkout origin/main -- deploy/dashboard.html
   git add deploy/dashboard.html
   git commit -m "Fix: Corregir signos '?' y codificación UTF-8"
   git push origin main --force
   ```

2. **En EasyPanel**:
   - Ve al servicio `dashboard`
   - Haz clic en **"Deploy"** o **"Redeploy"**
   - Espera 2-5 minutos

### Opción 3: Aplicar directamente desde el servidor

1. **Conectarse al servidor**:
   ```bash
   ssh root@TU_SERVIDOR
   ```

2. **Ejecutar script de corrección**:
   ```bash
   cd ~/checkin24hs
   # Ejecutar los scripts de corrección que creamos
   bash CORREGIR_MES_ANO.sh
   bash CORREGIR_UBICACION.sh
   bash CORREGIR_FLEXI.sh
   ```

3. **Copiar al contenedor**:
   ```bash
   CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
   docker cp /root/checkin24hs/dashboard.html $CONTAINER:/app/dashboard.html
   ```

## ✅ Verificación

Después de aplicar los cambios:

1. Recarga la página con **Ctrl+F5** (hard refresh)
2. Verifica que no aparezcan signos "?" en:
   - Dashboard: "Mes/Año" (no "Mes/A?o")
   - Hoteles: "Ubicación" (no "Ubicaci?n")
   - Programa Flexi: "¿Cómo", "Confirmación", "Estadía"
   - Flor IA: "Configuración de Flor IA" (con C mayúscula)

## 📝 Nota

El archivo `deploy/dashboard.html` local ya tiene todas las correcciones aplicadas. Solo necesitas subirlo al servidor o hacer que EasyPanel lo despliegue desde GitHub.
