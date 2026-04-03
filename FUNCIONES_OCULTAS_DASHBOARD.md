# 🔍 Funciones Ocultas y Deshabilitadas en dashboard.html

## 📋 Índice
1. [Funciones Deshabilitadas (_DISABLED)](#funciones-deshabilitadas)
2. [Funciones de Debug/Test](#funciones-de-debugtest)
3. [Funciones Globales (window.*)](#funciones-globales)
4. [Funciones de Administración Ocultas](#funciones-de-administración-ocultas)
5. [Funciones de Utilidad No Documentadas](#funciones-de-utilidad-no-documentadas)

---

## 🚫 Funciones Deshabilitadas (_DISABLED)

Estas funciones están deshabilitadas pero aún existen en el código:

### 1. `sendWhatsAppMessage_DISABLED`
**Línea:** ~8774
**Estado:** Deshabilitada
**Propósito:** Enviar mensajes de WhatsApp directamente usando la API de Facebook
```javascript
async function sendWhatsAppMessage_DISABLED(phoneNumber, message)
```
**Razón de deshabilitación:** Se reemplazó por `sendViaServerAPI()` que usa el servidor como intermediario.

---

### 2. `sendWhatsAppImage_DISABLED`
**Línea:** ~8857
**Estado:** Deshabilitada
**Propósito:** Enviar imágenes por WhatsApp usando la API de Facebook
```javascript
async function sendWhatsAppImage_DISABLED(phoneNumber, imageFile, caption = '')
```
**Razón de deshabilitación:** Se reemplazó por `sendImageViaServerAPI()` que usa el servidor.

---

### 3. `uploadWhatsAppMedia_DISABLED`
**Línea:** ~8934
**Estado:** Deshabilitada
**Propósito:** Subir archivos multimedia a WhatsApp API
```javascript
async function uploadWhatsAppMedia_DISABLED(file, config)
```
**Razón de deshabilitación:** Ya no se usa la API directa de WhatsApp.

---

### 4. `getWhatsAppConfig_DISABLED`
**Línea:** ~9008
**Estado:** Deshabilitada
**Propósito:** Obtener configuración de WhatsApp desde localStorage
```javascript
function getWhatsAppConfig_DISABLED()
```
**Razón de deshabilitación:** Se reemplazó por `getServerURL()` que obtiene la URL del servidor.

---

## 🧪 Funciones de Debug/Test

### 1. `testQuotesSync`
**Línea:** ~9489
**Propósito:** Probar sincronización de cotizaciones
```javascript
function testQuotesSync()
```

---

### 2. `testCoordinatesExtraction`
**Línea:** ~10479
**Propósito:** Probar extracción de coordenadas de Google Maps
```javascript
function testCoordinatesExtraction()
```

---

### 3. `createTestUser`
**Línea:** ~11963
**Propósito:** Crear un usuario de prueba
```javascript
function createTestUser()
```

---

### 4. `crearUsuariosPrueba`
**Línea:** ~11969
**Propósito:** Crear múltiples usuarios de prueba
```javascript
function crearUsuariosPrueba()
```

---

## 🌐 Funciones Globales (window.*)

Estas funciones están disponibles globalmente pero pueden no estar documentadas:

### 1. `window.showSection`
**Línea:** ~6
**Propósito:** Mostrar una sección del dashboard
```javascript
window.showSection = function(section, event)
```

---

### 2. `window.abrirModalImagenesDirecto`
**Línea:** ~4593
**Propósito:** Abrir el modal de gestión de imágenes directamente
```javascript
window.abrirModalImagenesDirecto = function(mode)
```

---

### 3. `window.handleLogin`
**Línea:** ~4818
**Propósito:** Manejar el proceso de login
```javascript
window.handleLogin = handleLogin
```

---

### 4. `window.loadAIConfigFromSupabase`
**Línea:** ~11378
**Propósito:** Cargar configuración de IA desde Supabase
```javascript
window.loadAIConfigFromSupabase = async function loadAIConfigFromSupabase()
```

---

### 5. `window.initRealtimeSubscriptions`
**Línea:** ~11235
**Propósito:** Inicializar suscripciones en tiempo real
```javascript
window.initRealtimeSubscriptions = initRealtimeSubscriptions
```

---

### 6. `window.showRealtimeNotification`
**Línea:** ~11236
**Propósito:** Mostrar notificaciones en tiempo real
```javascript
window.showRealtimeNotification = showRealtimeNotification
```

---

### 7. `window.getArgentinaDateString`
**Línea:** ~11286
**Propósito:** Obtener fecha en formato Argentina (string)
```javascript
window.getArgentinaDateString = getArgentinaDateString
```

---

### 8. `window.getArgentinaDateTime`
**Línea:** ~11287
**Propósito:** Obtener fecha y hora en formato Argentina
```javascript
window.getArgentinaDateTime = getArgentinaDateTime
```

---

### 9. `window.formatDateArgentina`
**Línea:** ~11288
**Propósito:** Formatear fecha en formato Argentina
```javascript
window.formatDateArgentina = formatDateArgentina
```

---

### 10. `window.formatDateTimeArgentina`
**Línea:** ~11289
**Propósito:** Formatear fecha y hora en formato Argentina
```javascript
window.formatDateTimeArgentina = formatDateTimeArgentina
```

---

### 11. `window.syncHotelToFlorKnowledge`
**Línea:** Múltiples referencias (5707, 5729, etc.)
**Propósito:** Sincronizar información de hotel con el conocimiento de Flor IA
```javascript
window.syncHotelToFlorKnowledge(hotelId, hotelData)
```
**Nota:** Esta función puede no estar definida si Flor IA no está configurada.

---

## 🔐 Funciones de Administración Ocultas

### 1. `isAdminTotal`
**Línea:** ~4854
**Propósito:** Verificar si el usuario actual es administrador total
```javascript
function isAdminTotal()
```

---

### 2. `initAdminUsers`
**Línea:** ~4658
**Propósito:** Inicializar usuarios administradores en localStorage
```javascript
function initAdminUsers()
```

---

### 3. `getAdminUsers`
**Línea:** ~4706
**Propósito:** Obtener todos los usuarios administradores
```javascript
function getAdminUsers()
```

---

### 4. `saveAdminUsers`
**Línea:** ~4711
**Propósito:** Guardar usuarios administradores
```javascript
function saveAdminUsers(users)
```

---

### 5. `checkAuthStatus`
**Línea:** ~4719
**Propósito:** Verificar estado de autenticación
```javascript
function checkAuthStatus()
```

---

### 6. `showLogin`
**Línea:** ~4760
**Propósito:** Mostrar pantalla de login
```javascript
function showLogin()
```

---

### 7. `showDashboard`
**Línea:** ~4777
**Propósito:** Mostrar dashboard
```javascript
function showDashboard()
```

---

### 8. `logout`
**Línea:** ~4868
**Propósito:** Cerrar sesión del usuario
```javascript
function logout()
```

---

## 🛠️ Funciones de Utilidad No Documentadas

### 1. `preservarCamposImagen`
**Línea:** ~4582
**Propósito:** Preservar campos de imagen (script desactivado)
```javascript
(function preservarCamposImagen() {
    // Script desactivado
})
```

---

### 2. `hideDashboardAndShowLogin`
**Línea:** ~4632
**Propósito:** Ocultar dashboard y mostrar login
```javascript
function hideDashboardAndShowLogin()
```

---

### 3. `showError`
**Línea:** ~4821
**Propósito:** Mostrar mensaje de error
```javascript
function showError(message)
```

---

### 4. `togglePasswordVisibility`
**Línea:** ~4828
**Propósito:** Mostrar/ocultar contraseña en formularios
```javascript
function togglePasswordVisibility(event)
```

---

### 5. `updateUserMenu`
**Línea:** ~4845
**Propósito:** Actualizar menú de usuario
```javascript
function updateUserMenu(userName, userRole)
```

---

### 6. `getServerURL`
**Línea:** ~9028
**Propósito:** Obtener URL del servidor desde configuración
```javascript
function getServerURL()
```

---

### 7. `sendViaServerAPI`
**Línea:** ~8823
**Propósito:** Enviar mensaje de WhatsApp vía API del servidor
```javascript
async function sendViaServerAPI(phoneNumber, message)
```

---

### 8. `sendImageViaServerAPI`
**Línea:** ~8974
**Propósito:** Enviar imagen de WhatsApp vía API del servidor
```javascript
async function sendImageViaServerAPI(phoneNumber, imageFile, caption)
```

---

### 9. `formatWhatsAppMessage`
**Línea:** ~9040
**Propósito:** Formatear mensaje de WhatsApp para cotizaciones
```javascript
function formatWhatsAppMessage(quote)
```

---

### 10. `openGoogleMapsHelp`
**Línea:** ~10450
**Propósito:** Abrir ayuda sobre Google Maps
```javascript
function openGoogleMapsHelp()
```

---

### 11. `syncQuotesFromIndex`
**Línea:** ~9521
**Propósito:** Sincronizar cotizaciones desde index.html
```javascript
function syncQuotesFromIndex()
```

---

### 12. `cleanDuplicateImages`
**Línea:** ~7249
**Propósito:** Limpiar imágenes duplicadas
```javascript
function cleanDuplicateImages()
```

---

### 13. `resetImageManager`
**Línea:** ~7255
**Propósito:** Reiniciar el gestor de imágenes
```javascript
function resetImageManager()
```

---

### 14. `sobrescribirBotonesImagenes`
**Línea:** ~11051
**Propósito:** Sobrescribir botones de imágenes
```javascript
function sobrescribirBotonesImagenes()
```

---

## 📝 Notas Importantes

1. **Funciones _DISABLED**: Aunque están deshabilitadas, el código aún existe. Pueden ser reactivadas cambiando el nombre de la función.

2. **Funciones Globales**: Las funciones en `window.*` están disponibles desde la consola del navegador (F12).

3. **Funciones de Debug**: Las funciones de test pueden ser útiles para desarrollo pero no deberían usarse en producción.

4. **Funciones de Administración**: Algunas funciones de administración están ocultas pero accesibles desde la consola del navegador.

5. **Funciones No Documentadas**: Muchas funciones de utilidad no están documentadas pero son usadas internamente por el dashboard.

---

## 🔧 Cómo Usar Estas Funciones

### Desde la Consola del Navegador (F12):

```javascript
// Ejemplo: Mostrar una sección
window.showSection('hotels', null);

// Ejemplo: Abrir modal de imágenes
window.abrirModalImagenesDirecto('main');

// Ejemplo: Verificar si es admin
isAdminTotal();

// Ejemplo: Obtener fecha Argentina
window.getArgentinaDateString();

// Ejemplo: Sincronizar hotel con Flor IA
window.syncHotelToFlorKnowledge(1, hotelData);
```

### ⚠️ Advertencias:

- **No uses funciones _DISABLED** a menos que sepas lo que haces
- **Las funciones de debug** pueden modificar datos
- **Las funciones de administración** requieren permisos adecuados
- **Algunas funciones** pueden no estar disponibles si ciertos servicios no están configurados

---

**Última actualización:** 2026-01-03
**Archivo analizado:** dashboard.html

