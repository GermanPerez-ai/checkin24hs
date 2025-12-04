# 🔐 Sistema de Autenticación Checkin24hs

## 📋 Descripción General

El sistema de autenticación de Checkin24hs permite a los usuarios registrarse, iniciar sesión y gestionar sus cuentas de forma segura. El sistema está integrado con el dashboard de administración para sincronización automática de datos.

## ✨ Características Principales

### 🔑 Autenticación
- **Registro de usuarios** con validación completa
- **Inicio de sesión** con email y contraseña
- **Autenticación social** (Google y Facebook)
- **Cerrar sesión** con confirmación
- **Darse de baja** con desactivación permanente

### 📊 Datos del Usuario
- **Nombre y Apellido**
- **Email** (único)
- **Teléfono**
- **Fecha de Nacimiento** (día y mes únicamente)
- **Fecha de Registro**
- **Estado de cuenta** (activo/inactivo)

### 🔄 Sincronización
- **Integración automática** con dashboard
- **Sincronización en tiempo real** de datos
- **Historial de sesiones** completo
- **Estadísticas de usuario** detalladas

## 🚀 Cómo Usar

### 1. Registro de Usuario

```javascript
// El usuario llena el formulario de registro
// Campos requeridos:
- Nombre
- Apellido  
- Email (único)
- Teléfono
- Fecha de Nacimiento (día y mes únicamente)
- Contraseña (mínimo 6 caracteres)
```

### 2. Inicio de Sesión

```javascript
// El usuario puede iniciar sesión de 3 formas:
1. Email + Contraseña
2. Google (simulado)
3. Facebook (simulado)
```

### 3. Gestión de Cuenta

```javascript
// Una vez logueado, el usuario puede:
- Ver su información personal
- Editar perfil (en desarrollo)
- Ver historial (en desarrollo)
- Cerrar sesión
- Darse de baja
```

## 🔧 Integración con Dashboard

### Archivos Necesarios

1. **`index.html`** - Contiene el sistema de autenticación principal
2. **`dashboard-integration.js`** - Script de integración para el dashboard
3. **`dashboard.html`** - Panel de administración

### Configuración del Dashboard

Agregar el script de integración al `dashboard.html`:

```html
<script src="dashboard-integration.js"></script>
```

### API Disponible

```javascript
// Acceder a la API desde el dashboard
window.checkin24hsAPI = {
    getCurrentUser(),        // Obtener usuario actual
    getUserStatistics(),     // Obtener estadísticas
    getSessionHistory(),     // Obtener historial de sesiones
    getAllUsers(),          // Obtener todos los usuarios
    forceLogout(userId)     // Forzar cierre de sesión
};
```

## 📁 Estructura de Datos

### Usuario (localStorage: `checkin24hs_users`)
```json
{
    "id": "user_1234567890",
    "nombre": "Juan",
    "apellido": "Pérez",
    "email": "juan@example.com",
    "telefono": "+56 9 1234 5678",
    "fechaNacimiento": "15/3",
    "password": "hashed_password",
    "fechaRegistro": "2024-01-01T00:00:00.000Z",
    "tipo": "usuario",
    "activo": true,
    "proveedor": "email|google|facebook"
}
```

### Sesión Actual (localStorage: `checkin24hs_user`)
```json
{
    "id": "user_1234567890",
    "nombre": "Juan",
    "apellido": "Pérez",
    "email": "juan@example.com",
    "telefono": "+56 9 1234 5678",
    "fechaNacimiento": "15/3",
    "fechaRegistro": "2024-01-01T00:00:00.000Z",
    "tipo": "usuario",
    "activo": true
}
```

### Datos del Dashboard (localStorage: `dashboard_user_data`)
```json
{
    "id": "user_1234567890",
    "nombre": "Juan",
    "apellido": "Pérez",
    "email": "juan@example.com",
    "telefono": "+56 9 1234 5678",
    "fechaNacimiento": "15/3",
    "fechaRegistro": "2024-01-01T00:00:00.000Z",
    "tipo": "usuario",
    "activo": true,
    "proveedor": "email",
    "ultimoAcceso": "2024-01-01T12:00:00.000Z"
}
```

## 🔔 Eventos del Sistema

### Eventos Disparados

```javascript
// Usuario logueado
window.dispatchEvent(new CustomEvent('userLoggedIn', {
    detail: { user: userObject }
}));

// Usuario deslogueado
window.dispatchEvent(new CustomEvent('userLoggedOut'));

// Usuario desactivado
window.dispatchEvent(new CustomEvent('userDeactivated', {
    detail: { user: userObject }
}));
```

### Escuchar Eventos

```javascript
// En el dashboard
window.addEventListener('userLoggedIn', (event) => {
    console.log('Usuario logueado:', event.detail.user);
    // Actualizar UI del dashboard
});

window.addEventListener('userLoggedOut', () => {
    console.log('Usuario deslogueado');
    // Limpiar UI del dashboard
});
```

## 🎨 Interfaz de Usuario

### Modal de Autenticación

El modal se adapta automáticamente según el estado de autenticación:

- **No autenticado**: Muestra formularios de login/registro
- **Autenticado**: Muestra información del perfil y opciones

### Notificaciones

El sistema muestra notificaciones automáticas para:

- ✅ Registro exitoso
- ✅ Login exitoso
- ❌ Errores de validación
- 🚪 Cierre de sesión
- 👋 Desactivación de cuenta

## 🔒 Seguridad

### Validaciones Implementadas

- **Email único** en el sistema
- **Contraseña mínima** de 6 caracteres
- **Campos requeridos** completos
- **Confirmación** para acciones críticas
- **Desactivación** en lugar de eliminación

### Almacenamiento

- **localStorage** para persistencia local
- **Datos encriptados** (en producción)
- **Tokens de sesión** únicos
- **Limpieza automática** de datos expirados

## 🚧 Funcionalidades en Desarrollo

- [ ] **Edición de perfil** en tiempo real
- [ ] **Historial de reservas** detallado
- [ ] **Recuperación de contraseña**
- [ ] **Verificación de email**
- [ ] **Autenticación de dos factores**
- [ ] **Integración con base de datos real**

## 📱 Responsive Design

El sistema está completamente optimizado para:

- 📱 **Móviles** (320px+)
- 📱 **Tablets** (768px+)
- 💻 **Desktop** (1024px+)
- 🖥️ **Pantallas grandes** (1440px+)

## 🐛 Solución de Problemas

### Problemas Comunes

1. **Modal no se abre**
   - Verificar que `showMiCuentaModal()` esté definida
   - Revisar consola para errores JavaScript

2. **Datos no se sincronizan**
   - Verificar que `dashboard-integration.js` esté incluido
   - Comprobar que los eventos se disparen correctamente

3. **localStorage no funciona**
   - Verificar que el navegador soporte localStorage
   - Comprobar que no esté en modo incógnito

### Debug

```javascript
// Verificar estado de autenticación
console.log('Usuario actual:', localStorage.getItem('checkin24hs_user'));

// Verificar todos los usuarios
console.log('Todos los usuarios:', localStorage.getItem('checkin24hs_users'));

// Verificar datos del dashboard
console.log('Datos del dashboard:', localStorage.getItem('dashboard_user_data'));
```

## 📞 Soporte

Para soporte técnico o preguntas sobre el sistema de autenticación, contactar al equipo de desarrollo de Checkin24hs.

---

**Versión**: 1.0.0  
**Última actualización**: Enero 2024  
**Desarrollado por**: Equipo Checkin24hs
