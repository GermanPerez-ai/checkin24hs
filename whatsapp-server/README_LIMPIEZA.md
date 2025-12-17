# 🧹 Guía de Limpieza de Sesión de WhatsApp

## Problema: "The profile appears to be in use by another Chromium process"

Este error ocurre cuando el perfil de Chrome/Puppeteer está bloqueado por otro proceso.

## Solución Rápida

### Opción 1: Limpiar solo los locks (recomendado)

**Windows:**
```bash
cd whatsapp-server
node limpiar_sesion.js
```

**Linux/Mac:**
```bash
cd whatsapp-server
chmod +x limpiar_sesion.sh
./limpiar_sesion.sh
```

Luego reinicia el servidor.

### Opción 2: Limpiar toda la sesión (necesitarás escanear QR nuevamente)

**Windows:**
```bash
cd whatsapp-server
node limpiar_sesion.js --clear-all
```

**Linux/Mac:**
```bash
cd whatsapp-server
./limpiar_sesion.sh --clear-all
```

Luego reinicia el servidor y escanea el QR nuevamente.

## Solución Manual

Si los scripts no funcionan, puedes hacerlo manualmente:

1. **Detener el servidor** (si está corriendo)

2. **Eliminar archivos de lock:**
   - Ve a la carpeta `whatsapp-server/.wwebjs_auth/Default/`
   - Elimina estos archivos si existen:
     - `SingletonLock`
     - `SingletonSocket`
     - `SingletonCookie`
     - Cualquier archivo que contenga "Lock" o "Singleton"

3. **Matar procesos de Chrome** (si es necesario):
   ```bash
   # Linux/Mac
   pkill -f chromium
   pkill -f chrome
   pkill -f puppeteer
   
   # Windows (PowerShell)
   Get-Process | Where-Object {$_.ProcessName -like "*chrome*" -or $_.ProcessName -like "*chromium*"} | Stop-Process -Force
   ```

4. **Reiniciar el servidor**

## Prevención

El código ahora limpia automáticamente los locks al iniciar, pero si el problema persiste:

1. Asegúrate de que solo hay **una instancia** del servidor corriendo
2. Si usas PM2, verifica que no hay procesos duplicados:
   ```bash
   pm2 list
   pm2 delete whatsapp-flor  # Si hay duplicados
   ```
3. Si usas Docker, reinicia el contenedor:
   ```bash
   docker restart whatsapp-server
   ```

## Notas

- **No elimines** la carpeta `.wwebjs_auth` completa a menos que quieras escanear el QR nuevamente
- La sesión de WhatsApp se guarda en `.wwebjs_auth` y persiste entre reinicios
- Si eliminas toda la sesión, necesitarás escanear el QR nuevamente desde tu teléfono

