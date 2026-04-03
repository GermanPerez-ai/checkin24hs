# 🔍 Revisar Logs: Servicio No Arranca

## 📋 Pasos para Diagnosticar

### Paso 1: Ver los Logs Completos

1. **Ve a EasyPanel** → Servicio `whatsapp`
2. **Haz clic en "Logs"** o **"Registros"**
3. **Haz scroll hacia arriba** para ver TODOS los logs desde el inicio
4. **Copia los últimos 50-100 líneas** de logs

---

## 🔍 Qué Buscar en los Logs

### ✅ Logs Correctos (Servicio Funcionando):

```
🚀 Iniciando servidor WhatsApp con Baileys...
✅ Cliente de Supabase inicializado
✅ Servidor iniciado en puerto 3001
📱 Instancia WhatsApp: 1
🌐 Servidor escuchando en 0.0.0.0:3001
```

### ❌ Errores Comunes:

#### Error 1: Cannot find module
```
Error: Cannot find module '@whiskeysockets/baileys'
Error: Cannot find module 'express'
Error: Cannot find module 'qrcode'
```
**Causa**: Dependencias no instaladas  
**Solución**: Verifica que `npm install` se ejecutó correctamente en el Dockerfile

---

#### Error 2: Port already in use
```
Error: listen EADDRINUSE: address already in use :::3001
Error: Port 3001 is already in use
```
**Causa**: Otro servicio está usando el puerto 3001  
**Solución**: 
1. Verifica otros servicios en EasyPanel
2. Detén el servicio que está usando el puerto 3001
3. O cambia el puerto del servicio WhatsApp

---

#### Error 3: File not found
```
Error: Cannot find module './whatsapp-server-baileys.js'
Error: ENOENT: no such file or directory
```
**Causa**: El archivo no está en la ubicación correcta  
**Solución**: 
1. Verifica que la ruta de compilación sea `/whatsapp-server`
2. Verifica que el archivo exista en GitHub

---

#### Error 4: Variables de entorno faltantes
```
Error: SUPABASE_URL is required
Error: Missing required environment variable
```
**Causa**: Variables de entorno no configuradas  
**Solución**: 
1. Ve a "Entorno" o "Environment"
2. Verifica que todas las variables estén configuradas:
   - `PORT=3001`
   - `INSTANCE_NUMBER=1`
   - `SUPABASE_URL=...`
   - `SUPABASE_ANON_KEY=...`

---

#### Error 5: El servicio se inicia pero se detiene inmediatamente
```
✅ Servidor iniciado en puerto 3001
... (luego se detiene)
```
**Causa**: Error después del inicio (conexión a Supabase, etc.)  
**Solución**: Revisa los logs completos para ver el error específico

---

#### Error 6: Build falló
```
Error: COPY failed: file not found
Error: npm install failed
Error: Step X/Y failed
```
**Causa**: Problema durante la construcción de la imagen Docker  
**Solución**: 
1. Verifica que el Dockerfile esté correcto
2. Verifica que los archivos existan en GitHub
3. Verifica la ruta de compilación: `/whatsapp-server`

---

## 📝 Checklist de Verificación

Mientras revisas los logs, verifica:

- [ ] **Estado del servicio**: ¿Está en "Building", "Running", "Failed" o "Stopped"?
- [ ] **Último mensaje en logs**: ¿Qué fue lo último que apareció?
- [ ] **Errores en rojo**: ¿Hay algún error visible?
- [ ] **Variables de entorno**: ¿Están todas configuradas?
- [ ] **Puerto**: ¿El puerto 3001 está libre?
- [ ] **Ruta de compilación**: ¿Es `/whatsapp-server`?
- [ ] **Comando de inicio**: ¿Está configurado como `node whatsapp-server-baileys.js`?

---

## 🎯 Qué Hacer Según el Error

### Si ves "Cannot find module":
1. Verifica que el Dockerfile tenga `RUN npm install --production`
2. Verifica que `package.json` exista en `whatsapp-server/`
3. Revisa los logs del build para ver si `npm install` falló

### Si ves "Port already in use":
1. Ve a otros servicios en EasyPanel
2. Busca cuál está usando el puerto 3001
3. Detén ese servicio o cambia el puerto

### Si ves "File not found":
1. Verifica la ruta de compilación: `/whatsapp-server`
2. Verifica que el archivo exista en GitHub: `whatsapp-server/whatsapp-server-baileys.js`
3. Verifica el comando de inicio: `node whatsapp-server-baileys.js`

### Si el build falla:
1. Ve a "Implementaciones" y revisa los logs del build
2. Busca en qué paso falló
3. Verifica que el Dockerfile esté correcto

### Si el servicio se detiene inmediatamente:
1. Revisa TODOS los logs (haz scroll hacia arriba)
2. Busca errores después de "Servidor iniciado"
3. Puede ser un error de conexión a Supabase o de autenticación

---

## 📤 Compartir Información para Diagnosticar

Si necesitas ayuda, comparte:

1. **Últimas 50 líneas de logs** (copia y pega)
2. **Estado del servicio** (Building, Running, Failed, Stopped)
3. **Mensaje de error específico** (si hay uno)
4. **Configuración actual**:
   - Ruta de compilación: `/whatsapp-server` ✅
   - Comando de inicio: `node whatsapp-server-baileys.js` ✅
   - Puerto: `3001` ✅
   - Variables de entorno: ¿Todas configuradas?

---

## ✅ Próximos Pasos

1. **Revisa los logs** siguiendo el Paso 1
2. **Identifica el error** usando la guía de arriba
3. **Aplica la solución** correspondiente
4. **Si no encuentras el error**, comparte los logs y te ayudo a diagnosticarlo
