# 📤 Subir dashboard.html al Servidor

## 🔍 Situación Actual

- **Servidor (Chrome)**: Build `2026-01-13T14:08:23Z` (versión antigua)
- **Local**: Build `2026-01-13T16:22:24Z` (versión nueva con correcciones)

## 📋 Pasos para Subir el Archivo

### Opción 1: Usando SCP (Recomendado - Rápido)

**Desde PowerShell en tu computadora:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp dashboard.html root@72.61.58.240:/root/checkin24hs/
```

**Luego en el servidor (SSH):**

```bash
cd /root/checkin24hs
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
echo "Contenedor encontrado: $CONTAINER"
docker cp dashboard.html "$CONTAINER:/app/dashboard.html"
docker restart "$CONTAINER"
echo "✅ Archivo actualizado y contenedor reiniciado"
```

### Opción 2: Usando Git (Permanente)

Si prefieres hacerlo de forma permanente:

```powershell
cd C:\Users\German\Downloads\Checkin24hs
git add dashboard.html
git commit -m "Corregir caracteres mal codificados y header horizontal"
git push origin main
```

Luego en EasyPanel, haz "Redeploy" del servicio dashboard.

## ✅ Verificación

Después de subir, verifica en Chrome:

1. Abre: https://dashboard.checkin24hs.com
2. Presiona F12 → Console
3. Escribe:
   ```javascript
   window.BUILD_TIMESTAMP
   ```
4. Deberías ver: `"2026-01-13T16:22:24Z"`

## 🔧 Si los cambios no aparecen

1. **Limpia la caché del navegador**: Ctrl+Shift+Delete
2. **Hard refresh**: Ctrl+F5
3. **Verifica el contenedor**: Asegúrate de que el contenedor se reinició correctamente
