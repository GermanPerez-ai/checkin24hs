# 🚀 Guía Paso a Paso: Configurar WhatsApp con SSL en EasyPanel

## 📋 Paso 1: Acceder a EasyPanel

1. Abre tu navegador y accede a **EasyPanel**
2. Inicia sesión con tus credenciales
3. Selecciona tu proyecto/servidor donde está corriendo WhatsApp

---

## 📋 Paso 2: Crear Nuevo Servicio para WhatsApp

### 2.1. Crear el Servicio

1. En el panel principal, haz clic en **"Nuevo Servicio"** o **"Add Service"**
2. Selecciona el tipo de servicio:
   - Si tu WhatsApp es una aplicación Node.js → Selecciona **"Node.js"**
   - Si es un servicio estático → Selecciona **"Static"**
   - Si no estás seguro → Selecciona **"Proxy"** o **"Reverse Proxy"**

### 2.2. Configurar el Servicio

**Nombre del servicio:**
```
whatsapp-api
```

**Puerto interno (si aplica):**
```
3001
```
*(Este es el puerto donde corre tu primera instancia de WhatsApp)*

---

## 📋 Paso 3: Configurar el Dominio

### 3.1. Agregar Dominio

1. En la configuración del servicio, busca la sección **"Domain"** o **"Dominio"**
2. Haz clic en **"Agregar Dominio"** o **"Add Domain"**
3. Ingresa el dominio:
```
configwp.checkin24hs.com
```

### 3.2. Habilitar SSL

1. Busca la opción **"Enable SSL"** o **"Habilitar SSL"**
2. Activa el switch/toggle para habilitar SSL
3. EasyPanel debería configurar automáticamente SSL con **Let's Encrypt**
4. Haz clic en **"Guardar"** o **"Save"**

**⏱️ Espera 1-2 minutos** para que se genere el certificado SSL

---

## 📋 Paso 4: Configurar Rutas de Proxy (OPCIÓN A)

### 4.1. Acceder a Configuración de Rutas

1. En la configuración del servicio `whatsapp-api`
2. Busca la sección **"Routes"**, **"Rutas"**, **"Proxy Routes"** o **"Path Routing"**

### 4.2. Agregar Rutas

Agrega las siguientes rutas una por una:

**Ruta 1:**
- **Path/Ruta**: `/api1/`
- **Target/Destino**: `127.0.0.1:3001`
- **Preserve Path**: ✅ (marcar si existe esta opción)

**Ruta 2:**
- **Path/Ruta**: `/api2/`
- **Target/Destino**: `127.0.0.1:3002`
- **Preserve Path**: ✅

**Ruta 3:**
- **Path/Ruta**: `/api3/`
- **Target/Destino**: `127.0.0.1:3003`
- **Preserve Path**: ✅

**Ruta 4:**
- **Path/Ruta**: `/api4/`
- **Target/Destino**: `127.0.0.1:3004`
- **Preserve Path**: ✅

### 4.3. Guardar Configuración

1. Haz clic en **"Guardar"** o **"Save"**
2. Espera a que se apliquen los cambios (puede tardar unos segundos)

---

## 📋 Paso 5: Verificar Configuración DNS

### 5.1. Verificar Registro DNS

Asegúrate de que el registro DNS esté configurado:

**Tipo**: `A` o `CNAME`
**Nombre**: `configwp`
**Valor**: IP de tu servidor (ej: `72.61.58.240`)

### 5.2. Verificar Propagación DNS

Puedes verificar con:
```bash
# En Windows PowerShell
nslookup configwp.checkin24hs.com

# O en navegador
# Visita: https://www.whatsmydns.net/#A/configwp.checkin24hs.com
```

---

## 📋 Paso 6: Probar SSL y Rutas

### 6.1. Probar SSL

1. Abre tu navegador
2. Visita: `https://configwp.checkin24hs.com`
3. Deberías ver:
   - ✅ Candado verde (SSL válido)
   - ✅ Sin errores de certificado
   - ✅ Posiblemente una página de error o respuesta del servidor (eso está bien)

### 6.2. Probar Rutas

Prueba cada ruta en el navegador:

```
https://configwp.checkin24hs.com/api1/api/qr?card=1
https://configwp.checkin24hs.com/api2/api/qr?card=2
https://configwp.checkin24hs.com/api3/api/qr?card=3
https://configwp.checkin24hs.com/api4/api/qr?card=4
```

**Resultado esperado:**
- ✅ Sin errores SSL
- ✅ Respuesta JSON o imagen QR (dependiendo del estado de WhatsApp)

---

## 📋 Paso 7: Actualizar Dashboard

### 7.1. Acceder al Dashboard

1. Abre tu dashboard: `https://dashboard.checkin24hs.com`
2. Inicia sesión
3. Ve a la sección **"Flor IA"** → **"WhatsApp"**

### 7.2. Configurar URL del Servidor

1. En el campo **"URL del Servidor WhatsApp"**, ingresa:
```
https://configwp.checkin24hs.com
```

2. Haz clic en **"Guardar URL"**

**⚠️ IMPORTANTE:** 
- NO incluyas puerto (no uses `:3001`)
- NO incluyas rutas (no uses `/api1`)
- Solo el dominio base: `https://configwp.checkin24hs.com`

### 7.3. Probar Conexión

1. Haz clic en **"Conectar"** en cualquier tarjeta de WhatsApp (1, 2, 3 o 4)
2. Deberías ver:
   - ✅ QR code generándose
   - ✅ Sin errores de Mixed Content
   - ✅ Sin errores SSL

---

## 🔍 Verificación Final

### Checklist de Verificación

- [ ] Servicio creado en EasyPanel
- [ ] Dominio `configwp.checkin24hs.com` configurado
- [ ] SSL habilitado y funcionando
- [ ] 4 rutas configuradas (`/api1/`, `/api2/`, `/api3/`, `/api4/`)
- [ ] DNS propagado correctamente
- [ ] SSL funciona en navegador (candado verde)
- [ ] Rutas responden correctamente
- [ ] URL guardada en dashboard
- [ ] QR code se genera correctamente

---

## 🆘 Solución de Problemas

### Problema: SSL no se genera

**Solución:**
1. Verifica que el DNS esté propagado: `nslookup configwp.checkin24hs.com`
2. Asegúrate de que el puerto 80 y 443 estén abiertos en el firewall
3. Espera 5-10 minutos y vuelve a intentar
4. Revisa los logs de EasyPanel para ver errores

### Problema: Rutas no funcionan

**Solución:**
1. Verifica que las rutas estén escritas exactamente: `/api1/`, `/api2/`, etc.
2. Asegúrate de que los puertos 3001-3004 estén corriendo
3. Verifica que el target sea `127.0.0.1:3001` (no `localhost`)
4. Revisa si hay opción "Preserve Path" y actívala

### Problema: Mixed Content Error

**Solución:**
1. Asegúrate de usar `https://` (no `http://`)
2. Verifica que SSL esté funcionando en el dominio
3. Limpia caché del navegador
4. Verifica que la URL guardada en dashboard sea `https://configwp.checkin24hs.com`

### Problema: QR code no aparece

**Solución:**
1. Abre la consola del navegador (F12)
2. Busca errores en la pestaña "Console"
3. Verifica que la URL sea correcta
4. Prueba la ruta directamente en el navegador

---

## 📞 Comandos Útiles para Verificar

### Desde el Servidor (SSH)

```bash
# Verificar que los puertos estén escuchando
netstat -tuln | grep -E '3001|3002|3003|3004'

# Probar rutas localmente
curl http://127.0.0.1:3001/api/qr?card=1
curl http://127.0.0.1:3002/api/qr?card=2

# Verificar certificado SSL
openssl s_client -connect configwp.checkin24hs.com:443 -servername configwp.checkin24hs.com
```

### Desde el Dashboard (Consola del Navegador)

```javascript
// Verificar URL guardada
localStorage.getItem('whatsappServerURL')

// Probar conexión manualmente
fetch('https://configwp.checkin24hs.com/api1/api/qr?card=1')
  .then(r => r.json())
  .then(console.log)
  .catch(console.error)
```

---

## ✅ ¡Listo!

Una vez completados todos los pasos, tu configuración de WhatsApp debería funcionar con SSL y rutas.

**Próximo paso:** Probar conectando WhatsApp desde el dashboard y escanear el QR code.
