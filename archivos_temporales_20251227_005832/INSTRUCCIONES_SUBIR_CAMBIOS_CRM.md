# Instrucciones para Subir Cambios del CRM

## Opción 1: Desde Windows (PowerShell)

1. **Abre PowerShell** en el directorio del proyecto

2. **Ejecuta el script:**
   ```powershell
   .\SUBIR_CAMBIOS_CRM.ps1
   ```

3. **Si te pide permisos**, ejecuta primero:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## Opción 2: Desde Windows (Git Bash o WSL)

1. **Abre Git Bash** o WSL en el directorio del proyecto

2. **Ejecuta el script:**
   ```bash
   bash SUBIR_Y_APLICAR_CRM_COMPLETO.sh
   ```

## Opción 3: Manualmente

### Paso 1: Subir el archivo
```bash
scp deploy/crm.js root@72.61.58.240:/root/checkin24hs/deploy/
```

### Paso 2: Conectarte al servidor
```bash
ssh root@72.61.58.240
```

### Paso 3: Aplicar cambios
```bash
cd /root/checkin24hs/deploy
chmod +x APLICAR_CAMBIOS_CRM_SERVIDOR.sh
./APLICAR_CAMBIOS_CRM_SERVIDOR.sh
```

## Opción 4: Directamente en el servidor

Si ya tienes el archivo en el servidor:

```bash
# En el servidor
cd /root/checkin24hs/deploy
chmod +x APLICAR_CAMBIOS_CRM_SERVIDOR.sh
./APLICAR_CAMBIOS_CRM_SERVIDOR.sh
```

## Verificar Cambios

Después de aplicar los cambios:

1. **Abre el CRM:** https://crm.checkin24hs.com
2. **Recarga la página** con `Ctrl+F5` (Windows) o `Cmd+Shift+R` (Mac) para forzar recarga sin caché
3. **Abre la consola del navegador** (F12)
4. **Verifica que aparezcan estos mensajes:**
   ```
   [CRM] 🔄 Inicializando suscripciones en tiempo real...
   [CRM] ✅ Suscrito a chats de WhatsApp
   [CRM] ✅ Suscrito a mensajes de WhatsApp
   [CRM] ✅ Suscrito a interacciones de Flor
   [CRM] ✅ Todas las suscripciones en tiempo real inicializadas
   ```

## Probar Sincronización en Tiempo Real

1. **Abre el CRM** en una pestaña
2. **Ve a la sección "Chats"**
3. **Envía un mensaje de WhatsApp** desde otro dispositivo
4. **Verifica** que el chat aparece automáticamente sin recargar la página

5. **Ve a la sección "Interacciones"**
6. **Crea una nueva interacción** desde el Dashboard
7. **Verifica** que la interacción aparece automáticamente

## Solución de Problemas

### Si no aparecen los mensajes de suscripción:

1. **Verifica que Supabase esté inicializado:**
   ```javascript
   // En la consola del navegador
   console.log(window.supabaseClient?.isInitialized());
   ```

2. **Verifica la conexión a Supabase:**
   ```javascript
   window.supabaseClient?.testConnection();
   ```

3. **Verifica que el archivo se copió correctamente:**
   ```bash
   # En el servidor
   docker exec $(docker ps --filter "name=crm" --format "{{.ID}}" | head -1) ls -lh /app/crm.js
   ```

### Si los cambios no se aplican:

1. **Fuerza la recarga sin caché:** `Ctrl+F5` o `Cmd+Shift+R`
2. **Limpia la caché del navegador**
3. **Verifica que el archivo en el contenedor sea el correcto:**
   ```bash
   docker exec $(docker ps --filter "name=crm" --format "{{.ID}}" | head -1) head -20 /app/crm.js | grep "initRealtimeSubscriptions"
   ```






