# 📤 Subir dashboard.html al Servidor - Pasos Ejecutables

## ✅ Confirmación
- Archivo local: ✅ Corregido (sin signos de pregunta, con emojis)
- Servidor: ⚠️ Necesita actualización

## 🚀 Pasos para Subir

### Paso 1: Subir el archivo al servidor (desde PowerShell)

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp dashboard.html root@72.61.58.240:/root/checkin24hs/
```

Cuando te pida la contraseña, ingrésala.

### Paso 2: Copiar al contenedor y reiniciar (en el servidor vía SSH)

Conéctate al servidor:
```bash
ssh root@72.61.58.240
```

Luego ejecuta estos comandos:
```bash
cd /root/checkin24hs
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
echo "Contenedor encontrado: $CONTAINER"
docker cp dashboard.html "$CONTAINER:/app/dashboard.html"
docker restart "$CONTAINER"
echo "✅ Archivo actualizado y contenedor reiniciado"
```

### Paso 3: Verificar en Chrome

1. Abre: https://dashboard.checkin24hs.com
2. Presiona **Ctrl+Shift+Delete** para limpiar caché
3. Selecciona "Caché" y haz clic en "Borrar datos"
4. Recarga la página con **Ctrl+F5** (hard refresh)
5. Verifica en la consola (F12):
   ```javascript
   window.BUILD_TIMESTAMP
   ```
   Deberías ver: `"2026-01-13T16:22:24Z"`

## ✅ Verificación Visual

Después de subir, deberías ver:
- ✅ "Panel de Administración" (sin `Ã³`)
- ✅ Header horizontal (botón, logo, texto en una línea)
- ✅ Emojis en los modales (📱, 📄, 💼, etc.)
- ✅ Sin signos de pregunta (`?`, `??`) en los textos
