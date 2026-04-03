# Actualizar Código para Usar Rutas en Lugar de Puertos

Si eliges la **Opción A** (un solo dominio con rutas), necesitas modificar el código del dashboard.

## 🔧 Cambios Necesarios

### Antes (usando puertos):
```javascript
const baseServerUrl = getServerURL(); // https://configwp.checkin24hs.com
const port = 3000 + parseInt(cardNumber); // 3001, 3002, 3003, 3004
const serverUrl = `${baseServerUrl}:${port}`; // https://configwp.checkin24hs.com:3001
```

### Después (usando rutas):
```javascript
const baseServerUrl = getServerURL(); // https://configwp.checkin24hs.com
const route = `/api${cardNumber}`; // /api1, /api2, /api3, /api4
const serverUrl = `${baseServerUrl}${route}`; // https://configwp.checkin24hs.com/api1
```

---

## 📝 Archivos a Modificar

Necesitas actualizar la función `getServerURL()` y todas las funciones que construyen URLs de WhatsApp.

### Ubicaciones en `dashboard.html`:

1. **Función `connectWhatsApp`** (línea ~9019)
2. **Función `checkWhatsAppConnectionStatus`** (línea ~9456)
3. **Función `disconnectWhatsApp`** (línea ~9542)
4. **Función `updateWhatsApp`** (línea ~9579)
5. **Otras funciones que usen `getServerURL()`**

---

## ✅ Solución: Modificar `getServerURL()` para Detectar Modo

La mejor solución es hacer que `getServerURL()` detecte automáticamente si debe usar puertos o rutas.

**Agregar parámetro opcional:**
```javascript
function getServerURL(cardNumber = null) {
    let serverUrl = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl');
    if (serverUrl && serverUrl.trim() !== '') {
        serverUrl = serverUrl.trim();
    } else {
        serverUrl = 'http://72.61.58.240';
    }
    
    // Convertir HTTP a HTTPS si el dashboard está en HTTPS
    if (window.location.protocol === 'https:' && serverUrl.startsWith('http://')) {
        serverUrl = serverUrl.replace('http://', 'https://');
    }
    
    // Si se proporciona cardNumber y la URL no tiene puerto, usar rutas
    if (cardNumber && !serverUrl.includes(':300')) {
        const route = `/api${cardNumber}`;
        return `${serverUrl}${route}`;
    }
    
    // Si no hay cardNumber o la URL tiene puerto, retornar URL base
    return serverUrl;
}
```

**Luego actualizar las llamadas:**
```javascript
// Antes:
const baseServerUrl = getServerURL();
const port = 3000 + parseInt(cardNumber);
const serverUrl = `${baseServerUrl}:${port}`;

// Después:
const serverUrl = getServerURL(cardNumber); // Retorna URL completa con ruta o puerto
```

---

## 🎯 Alternativa: Variable de Configuración

Otra opción es agregar una variable de configuración para elegir el modo:

```javascript
// En localStorage o configuración
const useRoutes = localStorage.getItem('whatsappUseRoutes') === 'true';

function getServerURL(cardNumber = null) {
    let serverUrl = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl');
    if (serverUrl && serverUrl.trim() !== '') {
        serverUrl = serverUrl.trim();
    } else {
        serverUrl = 'http://72.61.58.240';
    }
    
    // Convertir HTTP a HTTPS
    if (window.location.protocol === 'https:' && serverUrl.startsWith('http://')) {
        serverUrl = serverUrl.replace('http://', 'https://');
    }
    
    // Si se usa modo rutas y hay cardNumber
    if (useRoutes && cardNumber) {
        return `${serverUrl}/api${cardNumber}`;
    }
    
    // Modo puertos (comportamiento actual)
    if (cardNumber) {
        const port = 3000 + parseInt(cardNumber);
        return `${serverUrl}:${port}`;
    }
    
    return serverUrl;
}
```

---

## 📋 Pasos para Implementar

1. **Modificar `getServerURL()`** para soportar rutas
2. **Actualizar todas las llamadas** a `getServerURL()` para pasar `cardNumber`
3. **Probar** con ambas configuraciones (rutas y puertos)
4. **Actualizar documentación** con la nueva configuración

---

## 🔍 Verificación

Después de los cambios, verifica que:

1. **Con rutas**: `https://configwp.checkin24hs.com/api1/api/qr?card=1` funciona
2. **Con puertos** (si mantienes compatibilidad): `https://configwp.checkin24hs.com:3001/api/qr?card=1` funciona

