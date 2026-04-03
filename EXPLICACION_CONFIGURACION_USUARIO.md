# 🔧 Explicación: Configuración del Usuario para WhatsApp

## 📍 ¿Dónde se configura la URL del servidor?

### Ubicación en el Dashboard

La configuración del usuario está en un **modal (ventana emergente)** que se abre desde algún lugar del dashboard. El campo específico es:

**Campo**: `whatsappServerURL`  
**Etiqueta**: "URL del Servidor (Opcional)"  
**Ubicación HTML**: Línea 4992 de `dashboard.html`

### Cómo se guarda

1. **El usuario ingresa la URL** en el campo del modal (ej: `http://72.61.58.240`)
2. **Se guarda en localStorage** con la clave `whatsappServerURL`
3. **Se persiste** entre sesiones del navegador

### Función que lee la configuración

```javascript
function getServerURL() {
    // Lee desde localStorage
    const serverUrl = localStorage.getItem('whatsappServerURL');
    if (serverUrl && serverUrl.trim() !== '') {
        return serverUrl.trim();
    }
    return null; // No devuelve valor por defecto
}
```

**Ubicación**: Línea 10068 de `dashboard.html`

---

## ❌ Problema Actual

Las funciones que conectan WhatsApp **NO están usando** la configuración del usuario. Tienen hardcodeado:

```javascript
const serverUrl = 'http://localhost:3001'; // ❌ HARDCODEADO
```

**Funciones afectadas**:
1. `connectWhatsApp()` - Línea 9140
2. `checkWhatsAppConnectionStatus()` - Línea 9293
3. `updateWhatsApp()` - Línea 9380

---

## ✅ Solución

Cambiar las funciones para que usen `getServerURL()` en lugar de `'http://localhost:3001'`.

### Ejemplo de corrección:

**ANTES (Incorrecto)**:
```javascript
async function connectWhatsApp(cardNumber) {
    const serverUrl = 'http://localhost:3001'; // ❌ Hardcodeado
    // ...
}
```

**DESPUÉS (Correcto)**:
```javascript
async function connectWhatsApp(cardNumber) {
    const baseUrl = getServerURL(); // ✅ Lee configuración del usuario
    if (!baseUrl) {
        alert('⚠️ Por favor configura la URL del servidor WhatsApp primero');
        return;
    }
    
    // Calcular puerto según la tarjeta (3001, 3002, 3003, 3004)
    const port = 3000 + cardNumber;
    const serverUrl = `${baseUrl}:${port}`; // Ej: http://72.61.58.240:3001
    // ...
}
```

---

## 🎯 ¿Qué URL debe ingresar el usuario?

El usuario debe ingresar la **URL base del servidor**, sin el puerto. Por ejemplo:

- ✅ `http://72.61.58.240` (correcto)
- ✅ `https://whatsapp.checkin24hs.com` (si tienes dominio)
- ❌ `http://72.61.58.240:3001` (incorrecto - el puerto se agrega automáticamente)

El sistema agregará automáticamente el puerto según la tarjeta:
- WhatsApp 1 → Puerto 3001
- WhatsApp 2 → Puerto 3002
- WhatsApp 3 → Puerto 3003
- WhatsApp 4 → Puerto 3004

---

## 📋 Flujo Completo

```
1. Usuario abre Dashboard
   ↓
2. Usuario abre modal de configuración WhatsApp
   ↓
3. Usuario ingresa: http://72.61.58.240
   ↓
4. Sistema guarda en localStorage: whatsappServerURL = "http://72.61.58.240"
   ↓
5. Usuario hace clic en "Conectar" en WhatsApp 1
   ↓
6. Sistema lee: getServerURL() → "http://72.61.58.240"
   ↓
7. Sistema agrega puerto: "http://72.61.58.240:3001"
   ↓
8. Sistema hace petición a: http://72.61.58.240:3001/api/qr
   ↓
9. Servidor responde con QR
   ↓
10. Dashboard muestra QR al usuario
```

---

## 🔍 Dónde está el modal de configuración

El modal se abre con la función `showWhatsAppConfig()` (probablemente desde un botón en alguna parte del dashboard). El modal tiene:

- Campo para Access Token (WhatsApp Business API)
- Campo para Phone Number ID
- Campo para API Version
- **Campo para URL del Servidor** ← Este es el importante

---

## 💡 Resumen

**"Configuración del usuario"** = La URL del servidor que el usuario ingresa en el modal de configuración de WhatsApp, que se guarda en `localStorage` con la clave `whatsappServerURL`.

**Problema**: Las funciones de conexión no están leyendo esta configuración, tienen hardcodeado `localhost:3001`.

**Solución**: Modificar las funciones para que usen `getServerURL()` y agreguen el puerto correspondiente según la tarjeta (1→3001, 2→3002, etc.).










