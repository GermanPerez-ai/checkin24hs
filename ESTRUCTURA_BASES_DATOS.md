# 📊 Estructura de Bases de Datos del Dashboard

## 🔍 Resumen General

El dashboard utiliza **localStorage del navegador** para almacenar todas las bases de datos. Esto significa que:

- ✅ **Ventaja**: No requiere servidor, funciona completamente en el cliente
- ⚠️ **Limitación**: Los datos están almacenados solo en el navegador del usuario
- ⚠️ **Limitación**: Si se limpia el caché del navegador, se pierden los datos
- ⚠️ **Limitación**: Los datos no se sincronizan entre diferentes navegadores/dispositivos

## 📋 Bases de Datos Disponibles

### 1. **Hoteles** (`hotelsDB`)
- **Clave localStorage**: `hotelsDB`
- **Función de inicialización**: `initHotelsDB()`
- **Estructura**: Array de objetos con información de hoteles
- **Datos por defecto**: 6 hoteles precargados
- **Ejemplo**:
```javascript
[
  {
    id: "hotel-001",
    name: "Hotel Termas Chillán",
    location: "Chillán, Ñuble, Chile",
    rating: 5,
    price: 150000,
    status: "Activo",
    // ... más campos
  }
]
```

### 2. **Reservas** (`reservationsDB`)
- **Clave localStorage**: `reservationsDB`
- **Función de inicialización**: `initReservationsDB()`
- **Estructura**: Array de objetos con información de reservas
- **Ejemplo**:
```javascript
[
  {
    id: "res-001",
    code: "RES-2024-001",
    hotelId: "hotel-001",
    totalAmount: 600,
    status: "Confirmada",
    createdAt: "2025-11-28T19:04:54.115Z",
    // ... más campos
  }
]
```

### 3. **Cotizaciones** (`quotesDB`)
- **Clave localStorage**: `quotesDB`
- **Función de inicialización**: `initQuotesDB()`
- **Estructura**: Array de objetos con información de cotizaciones
- **Migración**: Migra automáticamente desde `checkin24hs_quotes` (sistema antiguo)
- **Ejemplo**:
```javascript
[
  {
    id: "quote-001",
    customerName: "Juan Pérez",
    email: "juan@example.com",
    status: "Pendiente",
    total: 500000,
    // ... más campos
  }
]
```

### 4. **Gastos** (`expensesDB`)
- **Clave localStorage**: `expensesDB`
- **Función de inicialización**: `initExpensesDB()`
- **Estructura**: Array de objetos con información de gastos
- **Presupuesto**: `expensesBudget` (presupuestos mensuales, trimestrales, anuales)
- **Ejemplo**:
```javascript
[
  {
    id: "expense-001",
    date: "2025-11-28",
    type: "fixed", // o "variable"
    category: "rent",
    amount: 50000,
    description: "Alquiler oficina",
    // ... más campos
  }
]
```

### 5. **Usuarios del Sistema** (`checkin24hs_users`)
- **Clave localStorage**: `checkin24hs_users`
- **Origen**: Usuarios registrados desde el dashboard
- **Estructura**: Array de objetos con información de usuarios
- **Ejemplo**:
```javascript
[
  {
    id: "user-001",
    name: "Juan Pérez",
    email: "juan@example.com",
    phone: "+56912345678",
    status: "active",
    // ... más campos
  }
]
```

### 6. **Clientes** (`clientesDB`)
- **Clave localStorage**: `clientesDB`
- **Origen**: Usuarios registrados desde index.html (versión móvil)
- **Estructura**: Array de objetos con información de clientes
- **Sincronización**: Se combina con `checkin24hs_users` en el dashboard

### 7. **Administradores del Dashboard** (`dashboard_admin_users`)
- **Clave localStorage**: `dashboard_admin_users`
- **Función de inicialización**: `initAdminUsers()`
- **Estructura**: Array de objetos con información de administradores
- **Roles**: `admin_total` o `usuario`
- **Ejemplo**:
```javascript
[
  {
    id: "admin-001",
    username: "admin",
    password: "admin123",
    name: "Administrador",
    role: "admin_total",
    email: "admin@checkin24hs.com",
    status: "active",
    createdAt: "2025-11-28T19:00:00.000Z",
    lastLogin: "2025-11-28T19:30:00.000Z"
  }
]
```

### 8. **Sesión de Autenticación** (`dashboard_auth_session`)
- **Clave localStorage**: `dashboard_auth_session`
- **Estructura**: Objeto con información de la sesión actual
- **Expiración**: 24 horas
- **Ejemplo**:
```javascript
{
  username: "admin",
  name: "Administrador",
  role: "admin_total",
  userId: "admin-001",
  loginTime: 1701200000000,
  expiresAt: 1701286400000
}
```

## 🔄 Inicialización de Bases de Datos

Las bases de datos se inicializan automáticamente cuando el dashboard se carga:

```javascript
function initializeDashboard() {
    // Inicializar bases de datos
    initClientesDB();      // Clientes
    initHotelsDB();        // Hoteles
    initReservationsDB();  // Reservas
    initQuotesDB();        // Cotizaciones
    initExpensesDB();      // Gastos
}
```

## 📝 Operaciones Comunes

### Leer datos
```javascript
const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
```

### Guardar datos
```javascript
localStorage.setItem('hotelsDB', JSON.stringify(hotels));
localStorage.setItem('reservationsDB', JSON.stringify(reservations));
localStorage.setItem('quotesDB', JSON.stringify(quotes));
```

### Limpiar datos
```javascript
localStorage.removeItem('hotelsDB');
localStorage.removeItem('reservationsDB');
localStorage.clear(); // Limpia TODO el localStorage
```

## 🔄 Sincronización

El dashboard tiene un sistema de sincronización automática:

1. **Sincronización cada 30 segundos**: Actualiza automáticamente los datos de usuarios
2. **Eventos de almacenamiento**: Escucha cambios en `localStorage` para actualizar en tiempo real
3. **Migración automática**: Migra datos del sistema antiguo al nuevo formato

## ⚠️ Consideraciones Importantes

### Limitaciones de localStorage
- **Tamaño máximo**: ~5-10MB dependiendo del navegador
- **Solo texto**: Solo puede almacenar strings (por eso se usa JSON.stringify/parse)
- **Específico del dominio**: Cada dominio tiene su propio localStorage
- **No se sincroniza**: Los datos no se comparten entre navegadores/dispositivos

### Recomendaciones
1. **Backup regular**: Exportar datos periódicamente
2. **Límite de datos**: Controlar el tamaño de las bases de datos
3. **Validación**: Validar datos antes de guardar
4. **Migración futura**: Considerar migrar a una base de datos real (MySQL, PostgreSQL, etc.) cuando el proyecto crezca

## 🚀 Migración Futura a Base de Datos Real

Cuando el proyecto necesite escalar, se recomienda:

1. **Backend API**: Crear un servidor con Node.js, Python, PHP, etc.
2. **Base de datos**: MySQL, PostgreSQL, MongoDB, etc.
3. **API REST**: Endpoints para CRUD de cada entidad
4. **Autenticación**: Sistema de autenticación con tokens JWT
5. **Sincronización**: Migrar datos de localStorage a la base de datos real

## 📊 Resumen de Claves localStorage

| Clave | Descripción | Tipo |
|-------|-------------|------|
| `hotelsDB` | Hoteles | Array |
| `reservationsDB` | Reservas | Array |
| `quotesDB` | Cotizaciones | Array |
| `expensesDB` | Gastos | Array |
| `expensesBudget` | Presupuestos | Object |
| `checkin24hs_users` | Usuarios del dashboard | Array |
| `clientesDB` | Clientes (móvil) | Array |
| `dashboard_admin_users` | Administradores | Array |
| `dashboard_auth_session` | Sesión actual | Object |
| `checkin24hs_quotes` | Cotizaciones (sistema antiguo) | Array |

## 🔧 Funciones de Utilidad

### Ver todas las bases de datos
```javascript
// En la consola del navegador (F12)
Object.keys(localStorage).forEach(key => {
    if (key.includes('DB') || key.includes('users') || key.includes('session')) {
        console.log(key, JSON.parse(localStorage.getItem(key)));
    }
});
```

### Exportar todas las bases de datos
```javascript
const allData = {};
Object.keys(localStorage).forEach(key => {
    if (key.includes('DB') || key.includes('users') || key.includes('session')) {
        allData[key] = JSON.parse(localStorage.getItem(key));
    }
});
console.log(JSON.stringify(allData, null, 2));
```

### Importar datos
```javascript
const importedData = { /* datos JSON */ };
Object.keys(importedData).forEach(key => {
    localStorage.setItem(key, JSON.stringify(importedData[key]));
});
```

