# 🔧 Solución: Error 404 en /qr

## ⚠️ Problema
Al acceder a `https://whatsapp.checkin24hs.com/qr` aparece error 404.

## 🔍 Diagnóstico

### 1. Verificar que el Servicio Esté Corriendo

En EasyPanel → Servicios → `whatsapp`:
- ✅ Estado debe ser **"Running"** (verde)
- ✅ CPU y Memoria deben tener valores (no 0%)

### 2. Probar Rutas Alternativas

El endpoint QR está configurado en ambas rutas:
- `/qr` 
- `/api/qr`

**Prueba estas URLs:**

1. **Con `/api/qr`:**
   ```
   https://whatsapp.checkin24hs.com/api/qr
   ```

2. **Directamente al puerto (si tienes acceso):**
   ```
   http://[IP_SERVIDOR]:3001/api/qr
   http://[IP_SERVIDOR]:3001/qr
   ```

3. **Verificar estado del servicio:**
   ```
   https://whatsapp.checkin24hs.com/api/health
   https://whatsapp.checkin24hs.com/api/status
   ```

### 3. Verificar Configuración del Dominio en EasyPanel

1. Ve a EasyPanel → Servicios → `whatsapp` → **Dominios**
2. Verifica que `whatsapp.checkin24hs.com` esté configurado
3. Verifica que el puerto sea **3001**
4. Verifica que Traefik esté habilitado

### 4. Verificar Logs del Servicio

En EasyPanel → Servicios → `whatsapp` → **Logs**:

Busca estos mensajes:
- `✅ Servidor iniciado en puerto 3001`
- `📋 Endpoints disponibles:`
- `   - GET  .../api/qr`

Si NO ves estos mensajes, el servidor no inició correctamente.

### 5. Verificar que el Servidor Esté Escuchando

Si tienes acceso SSH al servidor:

```bash
# Verificar que el puerto 3001 esté escuchando
netstat -tulpn | grep 3001
# o
ss -tulpn | grep 3001

# Ver logs del contenedor
docker ps | grep whatsapp
docker logs <nombre_contenedor> --tail 50
```

---

## ✅ Soluciones

### Solución 1: Reiniciar el Servicio

1. En EasyPanel → Servicios → `whatsapp`
2. Haz clic en **"Restart"**
3. Espera 1-2 minutos
4. Prueba nuevamente: `https://whatsapp.checkin24hs.com/api/qr`

### Solución 2: Verificar Configuración de Traefik

Si el dominio no funciona, puede ser un problema de Traefik:

1. Ve a EasyPanel → Servicios → `whatsapp` → **Dominios**
2. Verifica que Traefik esté habilitado
3. Verifica las etiquetas de Traefik:
   - `traefik.enable=true`
   - `traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)`
   - `traefik.http.routers.whatsapp.entrypoints=websecure`
   - `traefik.http.routers.whatsapp.tls.certresolver=letsencrypt`

### Solución 3: Probar Directamente el Puerto

Si el dominio no funciona, prueba acceder directamente:

1. Obtén la IP del servidor
2. Accede a: `http://[IP]:3001/api/qr`
3. Si funciona, el problema es la configuración del dominio

### Solución 4: Verificar que el Servidor Inició Correctamente

Si en los logs solo ves "Connecting to websocket..." y no ves:
- `✅ Servidor iniciado en puerto 3001`

Entonces el servidor HTTP no inició. Necesitas revisar los logs completos desde el inicio.

---

## 🧪 Pruebas Rápidas

### Test 1: Health Check
```
https://whatsapp.checkin24hs.com/api/health
```
**Debería devolver:** JSON con `{"status":"ok",...}`

### Test 2: Status
```
https://whatsapp.checkin24hs.com/api/status
```
**Debería devolver:** JSON con el estado de WhatsApp

### Test 3: QR Code
```
https://whatsapp.checkin24hs.com/api/qr
```
**Debería devolver:** HTML con el QR code (si está disponible)

---

## 📊 Resumen

- ✅ La ruta `/qr` y `/api/qr` están definidas en el código
- ❌ El 404 indica que el dominio no está apuntando al servicio
- 🔍 Verifica: Estado del servicio, configuración del dominio, logs del servidor

---

## 🆘 Si Nada Funciona

1. **Verifica los logs completos** desde el inicio
2. **Reinicia el servicio** en EasyPanel
3. **Verifica la configuración del dominio** en EasyPanel
4. **Prueba acceder directamente al puerto** (si es posible)
