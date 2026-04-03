# 📤 Solución: Subir Archivos Corregidos

## 🔍 Problema Identificado

- ✅ El archivo local tiene la versión CORRECTA (con `header-left`)
- ❌ El archivo en el servidor tiene versión ANTIGUA (sin `header-left`)
- ❌ El archivo en el contenedor tiene versión INTERMEDIA (sin `header-left`)
- ❌ `serve-dashboard.js` no existe en el contenedor

## 🚀 Pasos para Corregir

### Paso 1: Subir archivos desde tu COMPUTADORA (PowerShell)

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp dashboard.html root@72.61.58.240:/root/checkin24hs/
scp serve-dashboard.js root@72.61.58.240:/root/checkin24hs/
```

### Paso 2: En el SERVIDOR (SSH) - Copiar al contenedor y reiniciar

```bash
cd /root/checkin24hs
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
echo "Contenedor: $CONTAINER"

# Copiar ambos archivos
docker cp dashboard.html "$CONTAINER:/app/dashboard.html"
docker cp serve-dashboard.js "$CONTAINER:/app/serve-dashboard.js"

# Verificar que se copió correctamente
echo "=== Verificando header-left en el contenedor ==="
docker exec "$CONTAINER" grep -n "header-left" /app/dashboard.html | head -3

# Reiniciar contenedor
docker restart "$CONTAINER"
echo "✅ Archivos actualizados y contenedor reiniciado"
```

### Paso 3: Verificar en Chrome

1. Abre: https://dashboard.checkin24hs.com
2. Limpia caché: Ctrl+Shift+Delete → "Caché" → "Borrar datos"
3. Hard refresh: Ctrl+F5
4. Verifica que el header esté horizontal

## ✅ Verificación Final

Ejecuta de nuevo el diagnóstico para confirmar:

```bash
./DIAGNOSTICO_SERVIDOR.sh
```

Deberías ver:
- ✅ Hash del servidor y contenedor similares (pueden diferir ligeramente por diferencias de línea)
- ✅ `header-left` presente en ambos archivos
- ✅ `serve-dashboard.js` existe en el contenedor
