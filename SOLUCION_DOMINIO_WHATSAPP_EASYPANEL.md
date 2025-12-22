# Solución: Configurar Dominio HTTPS para WhatsApp en EasyPanel

## 📊 Situación Actual

Según la consulta de dominios:
- ✅ `webmail.checkin24hs.com` tiene SSL configurado
- ❌ `dashboard.checkin24hs.com` NO tiene SSL (solo HTTP)
- ✅ Puerto 3001 está activo (WhatsApp instancia 1)
- ✅ Estás usando Docker/Traefik (EasyPanel)

---

## ✅ Opción 1: Crear Nuevo Subdominio para WhatsApp (RECOMENDADO)

### Paso 1: Crear Servicio en EasyPanel

1. **Ve a EasyPanel** → Tu proyecto → **Nuevo Servicio**
2. **Tipo de servicio**: Node.js o Static (según tu configuración)
3. **Nombre del servicio**: `whatsapp-api` o `whatsapp-server`
4. **Puerto interno**: `3001` (o el puerto que uses para WhatsApp)
5. **Dominio**: `api.checkin24hs.com` (o `whatsapp.checkin24hs.com`)

### Paso 2: Configurar Dominio con SSL

1. **En la configuración del servicio**, ve a la sección **"Domain"** o **"Dominio"**
2. **Agrega el dominio**: `api.checkin24hs.com`
3. **Habilita SSL**: EasyPanel debería configurar SSL automáticamente con Let's Encrypt
4. **Guarda los cambios**

### Paso 3: Configurar Proxy Reverso (si es necesario)

Si tu servicio WhatsApp está en otro contenedor, configura el proxy:

**En EasyPanel → Servicio → Configuración → Proxy:**

```
Target: whatsapp-server:3001
Path: /
```

O si está en el mismo servidor:

```
Target: 127.0.0.1:3001
Path: /
```

### Paso 4: Verificar SSL

1. Espera 1-2 minutos para que se genere el certificado SSL
2. Prueba en el navegador: `https://api.checkin24hs.com`
3. Deberías ver el certificado SSL válido

### Paso 5: Actualizar URL en el Dashboard

1. Ve a **Dashboard** → **Flor IA** → **WhatsApp**
2. En **"URL del Servidor WhatsApp"**, ingresa: `https://api.checkin24hs.com`
3. Haz clic en **"Guardar URL"**

---

## ✅ Opción 2: Agregar SSL a Dashboard Existente

Si prefieres usar el dominio del dashboard:

### Paso 1: Configurar SSL en EasyPanel

1. **Ve a EasyPanel** → Servicio `dashboard`
2. **Ve a la sección "Domain"** o **"Dominio"**
3. **Verifica que el dominio esté configurado**: `dashboard.checkin24hs.com`
4. **Habilita SSL**: Debería haber una opción para habilitar SSL automáticamente
5. **Guarda los cambios**

### Paso 2: Configurar Rutas para WhatsApp

Si quieres usar el mismo dominio con rutas diferentes:

**En EasyPanel → Servicio dashboard → Configuración → Rutas:**

```
/api/whatsapp/1 → Proxy a puerto 3001
/api/whatsapp/2 → Proxy a puerto 3002
/api/whatsapp/3 → Proxy a puerto 3003
/api/whatsapp/4 → Proxy a puerto 3004
```

### Paso 3: Actualizar Código del Dashboard

Necesitarías modificar el código para usar rutas en lugar de puertos:

```javascript
// En lugar de: https://dashboard.checkin24hs.com:3001/api/qr
// Usar: https://dashboard.checkin24hs.com/api/whatsapp/1/api/qr
```

---

## ✅ Opción 3: Usar Subdominio Existente (webmail)

**NO recomendado** porque webmail ya tiene su propio servicio, pero técnicamente posible:

1. Configurar proxy reverso en `webmail.checkin24hs.com` para rutas `/api/whatsapp/*`
2. Más complejo y puede causar conflictos

---

## 🎯 Recomendación Final

**Usa la Opción 1**: Crear `api.checkin24hs.com` como nuevo servicio en EasyPanel.

**Ventajas:**
- ✅ Separación clara de servicios
- ✅ SSL automático con EasyPanel
- ✅ Fácil de mantener
- ✅ No interfiere con otros servicios

---

## 📋 Pasos Resumidos (Opción 1)

1. **EasyPanel** → Nuevo Servicio → `whatsapp-api`
2. **Puerto**: `3001`
3. **Dominio**: `api.checkin24hs.com`
4. **Habilitar SSL**: Automático en EasyPanel
5. **Esperar 1-2 minutos** para certificado SSL
6. **Probar**: `https://api.checkin24hs.com`
7. **Actualizar dashboard**: URL → `https://api.checkin24hs.com`

---

## 🔍 Verificar que Funciona

Después de configurar, prueba:

```bash
# Desde el servidor
curl https://api.checkin24hs.com/api/qr?card=1

# O desde el navegador
https://api.checkin24hs.com/api/qr?card=1
```

Deberías ver una respuesta JSON o el QR code sin errores SSL.

---

## ⚠️ Nota sobre Múltiples Instancias

Si tienes 4 instancias de WhatsApp (puertos 3001-3004), puedes:

**Opción A**: Crear 4 subdominios:
- `api1.checkin24hs.com` → puerto 3001
- `api2.checkin24hs.com` → puerto 3002
- `api3.checkin24hs.com` → puerto 3003
- `api4.checkin24hs.com` → puerto 3004

**Opción B**: Usar rutas en un solo dominio:
- `api.checkin24hs.com/api1/` → puerto 3001
- `api.checkin24hs.com/api2/` → puerto 3002
- etc.

La Opción A es más simple pero requiere más configuración. La Opción B requiere modificar el código del dashboard.

