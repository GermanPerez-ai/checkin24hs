# 📋 Paso 7: Probar SSL y Actualizar Dashboard

## 🎯 Objetivo
Verificar que el DNS y SSL funcionen correctamente, y luego actualizar el dashboard con la nueva URL.

---

## 📝 Paso 7.1: Verificar DNS

### Desde PowerShell

Abre PowerShell y ejecuta:

```powershell
nslookup configwp.checkin24hs.com
```

**Resultado esperado:**
- Debería mostrar: `72.61.58.240`
- Si muestra "No se puede resolver", espera 5-10 minutos más

**⏱️ Nota:** La propagación DNS puede tardar 5-30 minutos. Si no funciona inmediatamente, espera un poco.

---

## 📝 Paso 7.2: Probar SSL

### En el Navegador

1. Abre tu navegador
2. Visita: `https://configwp.checkin24hs.com`
3. Deberías ver:
   - ✅ Candado verde 🔒 (SSL válido)
   - ✅ Sin errores de certificado
   - ⚠️ Posiblemente una página de error o "502 Bad Gateway" (eso está bien, significa que el dominio funciona)

---

## 📝 Paso 7.3: Probar Rutas

### Probar cada ruta en el navegador:

**Ruta 1:**
```
https://configwp.checkin24hs.com/api1/api/qr?card=1
```

**Ruta 2:**
```
https://configwp.checkin24hs.com/api2/api/qr?card=2
```

**Ruta 3:**
```
https://configwp.checkin24hs.com/api3/api/qr?card=3
```

**Ruta 4:**
```
https://configwp.checkin24hs.com/api4/api/qr?card=4
```

**Resultado esperado:**
- ✅ Sin errores SSL
- ✅ Respuesta JSON o imagen QR (si WhatsApp está corriendo)
- ✅ O error 502/503 si WhatsApp no está corriendo (eso está bien, significa que la ruta funciona pero el servicio no está activo)

---

## 📝 Paso 7.4: Actualizar Dashboard

### 7.4.1. Acceder al Dashboard

1. Abre tu dashboard: `https://dashboard.checkin24hs.com`
2. Inicia sesión si es necesario
3. Ve a la sección **"Flor IA"** → **"WhatsApp"**

### 7.4.2. Configurar URL del Servidor

1. Busca el campo **"URL del Servidor WhatsApp"** o **"WhatsApp Server URL"**
2. **Borra** la URL anterior (si había una)
3. Ingresa la nueva URL:
   ```
   https://configwp.checkin24hs.com
   ```

**⚠️ IMPORTANTE:**
- ✅ Usa `https://` (no `http://`)
- ✅ NO incluyas puerto (no uses `:3001`)
- ✅ NO incluyas rutas (no uses `/api1`)
- ✅ Solo el dominio base: `https://configwp.checkin24hs.com`

4. Haz clic en **"Guardar URL"** o **"Save"**

### 7.4.3. Verificar que se Guardó

1. Recarga la página
2. Verifica que la URL guardada sea: `https://configwp.checkin24hs.com`
3. Puedes verificar en la consola del navegador (F12):
   ```javascript
   localStorage.getItem('whatsappServerURL')
   ```
   Debería mostrar: `https://configwp.checkin24hs.com`

---

## 📝 Paso 7.5: Probar Conexión WhatsApp

### Probar desde el Dashboard

1. En la sección WhatsApp, busca la tarjeta de **WhatsApp 1**
2. Haz clic en el botón **"Conectar"**
3. Deberías ver:
   - ✅ QR code generándose
   - ✅ Sin errores de Mixed Content
   - ✅ Sin errores SSL
   - ✅ La URL en la consola debería ser: `https://configwp.checkin24hs.com/api1/api/qr?card=1`

### Probar las otras instancias

Repite el proceso para WhatsApp 2, 3 y 4:
- WhatsApp 2 debería usar: `https://configwp.checkin24hs.com/api2/api/qr?card=2`
- WhatsApp 3 debería usar: `https://configwp.checkin24hs.com/api3/api/qr?card=3`
- WhatsApp 4 debería usar: `https://configwp.checkin24hs.com/api4/api/qr?card=4`

---

## ✅ Checklist Final

- [ ] DNS resuelve correctamente (`nslookup configwp.checkin24hs.com`)
- [ ] SSL funciona (candado verde en navegador)
- [ ] Ruta `/api1/` responde (aunque sea con error 502)
- [ ] Ruta `/api2/` responde
- [ ] Ruta `/api3/` responde
- [ ] Ruta `/api4/` responde
- [ ] URL guardada en dashboard: `https://configwp.checkin24hs.com`
- [ ] QR code se genera correctamente desde el dashboard

---

## 🆘 Solución de Problemas

### Problema: DNS no resuelve
**Solución:**
- Espera 10-30 minutos más
- Verifica que el registro DNS esté guardado correctamente
- Prueba desde otro dispositivo o red

### Problema: Error SSL
**Solución:**
- Espera 2-5 minutos más para que se genere el certificado
- Verifica en EasyPanel que SSL esté activo
- Limpia caché del navegador

### Problema: Error 502 en las rutas
**Solución:**
- Esto puede ser normal si WhatsApp no está corriendo
- Verifica que los puertos 3001-3004 estén activos
- Revisa los logs de NGINX en EasyPanel

### Problema: QR code no aparece en dashboard
**Solución:**
- Abre la consola del navegador (F12)
- Busca errores en la pestaña "Console"
- Verifica que la URL sea correcta
- Prueba la ruta directamente en el navegador

---

## 🎉 ¡Configuración Completa!

Una vez que hayas completado todos los pasos, tu configuración de WhatsApp debería estar funcionando con SSL y rutas.

**Próximo paso:** Escanear el QR code con tu teléfono para conectar WhatsApp.


