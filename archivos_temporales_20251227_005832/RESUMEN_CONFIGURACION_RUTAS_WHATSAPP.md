# Resumen: Configuración de Rutas para WhatsApp (Opción A)

## ✅ Cambios Aplicados en el Código

He actualizado el código del dashboard para soportar **rutas en lugar de puertos** cuando uses un dominio HTTPS como `configwp.checkin24hs.com`.

### Funcionamiento Automático

El código ahora detecta automáticamente si debe usar **rutas** o **puertos**:

- **Si la URL NO tiene puerto** (ej: `https://configwp.checkin24hs.com`):
  - Usa **rutas**: `/api1`, `/api2`, `/api3`, `/api4`
  - URLs resultantes: `https://configwp.checkin24hs.com/api1/api/qr?card=1`

- **Si la URL tiene puerto** (ej: `http://72.61.58.240` o `https://72.61.58.240:3001`):
  - Usa **puertos**: `:3001`, `:3002`, `:3003`, `:3004`
  - URLs resultantes: `https://72.61.58.240:3001/api/qr?card=1`

---

## 📋 Pasos para Configurar en EasyPanel

### Paso 1: Crear Servicio en EasyPanel

1. **Ve a EasyPanel** → Tu proyecto → **Nuevo Servicio**
2. **Nombre del servicio**: `whatsapp-api` o `whatsapp-server`
3. **Tipo**: Node.js o Static (según tu configuración)
4. **Puerto interno**: `3001` (o el puerto base que uses)

### Paso 2: Configurar Dominio

1. **En la configuración del servicio**, ve a **"Domain"** o **"Dominio"**
2. **Agrega el dominio**: `configwp.checkin24hs.com`
3. **Habilita SSL**: EasyPanel configurará SSL automáticamente
4. **Guarda los cambios**

### Paso 3: Configurar Rutas de Proxy

En EasyPanel, configura las rutas de proxy:

```
Ruta: /api1/  → Target: 127.0.0.1:3001
Ruta: /api2/  → Target: 127.0.0.1:3002
Ruta: /api3/  → Target: 127.0.0.1:3003
Ruta: /api4/  → Target: 127.0.0.1:3004
```

**Nota**: El formato exacto puede variar según la versión de EasyPanel. Busca la sección de "Routes", "Proxy Routes", o "Path Mapping".

### Paso 4: Esperar Certificado SSL

1. Espera 1-2 minutos para que se genere el certificado SSL
2. Verifica que funciona: `https://configwp.checkin24hs.com`

### Paso 5: Actualizar URL en el Dashboard

1. Ve a **Dashboard** → **Flor IA** → **WhatsApp**
2. En **"URL del Servidor WhatsApp"**, ingresa: `https://configwp.checkin24hs.com`
   - **IMPORTANTE**: Sin puerto, sin `/api1`, solo el dominio base
3. Haz clic en **"Guardar URL"**

El código automáticamente agregará las rutas `/api1`, `/api2`, etc. según la tarjeta.

---

## 🔍 Verificación

### Probar desde el Navegador

```
https://configwp.checkin24hs.com/api1/api/qr?card=1
https://configwp.checkin24hs.com/api2/api/qr?card=2
https://configwp.checkin24hs.com/api3/api/qr?card=3
https://configwp.checkin24hs.com/api4/api/qr?card=4
```

Deberías ver respuestas JSON o QR codes sin errores SSL.

### Probar desde el Dashboard

1. Ve a **Flor IA** → **WhatsApp**
2. Haz clic en **"Conectar"** en cualquier tarjeta
3. Deberías ver el QR code generarse correctamente
4. Verifica en la consola del navegador que la URL sea correcta:
   ```
   🔗 URL completa construida: https://configwp.checkin24hs.com/api1
   ```

---

## 🔧 Compatibilidad hacia Atrás

El código mantiene compatibilidad con el modo de puertos:

- Si configuras: `https://72.61.58.240:3001` → Usará puertos
- Si configuras: `https://configwp.checkin24hs.com` → Usará rutas

---

## 📝 URLs Resultantes

Con la configuración de rutas, las URLs serán:

- **WhatsApp 1**: `https://configwp.checkin24hs.com/api1/api/qr?card=1`
- **WhatsApp 2**: `https://configwp.checkin24hs.com/api2/api/qr?card=2`
- **WhatsApp 3**: `https://configwp.checkin24hs.com/api3/api/qr?card=3`
- **WhatsApp 4**: `https://configwp.checkin24hs.com/api4/api/qr?card=4`

---

## ✅ Ventajas de esta Configuración

- ✅ **Un solo certificado SSL** para todas las instancias
- ✅ **Una sola configuración** en EasyPanel
- ✅ **Código automático**: detecta rutas vs puertos
- ✅ **Compatible**: funciona con ambos modos
- ✅ **Fácil de mantener**: cambios centralizados

---

## 🎯 Próximos Pasos

1. ✅ **Código actualizado** (ya hecho)
2. ⏳ **Configurar servicio en EasyPanel** (tú)
3. ⏳ **Configurar rutas de proxy** (tú)
4. ⏳ **Actualizar URL en dashboard** (tú)
5. ⏳ **Probar conexión** (tú)

¡Listo para configurar en EasyPanel!



