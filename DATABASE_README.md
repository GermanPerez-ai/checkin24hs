# Base de Datos Checkin24hs

## 📋 Descripción General

Este proyecto incluye dos versiones de la base de datos para Checkin24hs:

1. **`database.sql`** - Esquema de base de datos MySQL para producción
2. **`database.js`** - Base de datos simulada en JavaScript para desarrollo frontend

## 🗄️ Estructura de la Base de Datos

### Tablas Principales

#### 1. **users** - Usuarios del sistema
```sql
- id (INT, AUTO_INCREMENT, PRIMARY KEY)
- name (VARCHAR(100)) - Nombre completo
- email (VARCHAR(100), UNIQUE) - Email único
- password_hash (VARCHAR(255)) - Contraseña hasheada
- phone (VARCHAR(20)) - Teléfono
- avatar_url (VARCHAR(255)) - URL del avatar
- rewards_points (INT) - Puntos de recompensa
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de actualización
- is_active (BOOLEAN) - Estado activo
- last_login (TIMESTAMP) - Último login
```

#### 2. **hotels** - Hoteles disponibles
```sql
- id (INT, AUTO_INCREMENT, PRIMARY KEY)
- name (VARCHAR(100)) - Nombre del hotel
- description (TEXT) - Descripción
- location (VARCHAR(100)) - Ubicación
- address (TEXT) - Dirección completa
- rating (DECIMAL(2,1)) - Calificación
- image_url (VARCHAR(255)) - URL de la imagen
- amenities (JSON) - Amenities disponibles
- is_active (BOOLEAN) - Estado activo
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de actualización
```

#### 3. **quotes** - Cotizaciones de reservas
```sql
- id (INT, AUTO_INCREMENT, PRIMARY KEY)
- user_id (INT, FOREIGN KEY) - ID del usuario
- hotel_id (INT, FOREIGN KEY) - ID del hotel
- check_in_date (DATE) - Fecha de check-in
- check_out_date (DATE) - Fecha de check-out
- guests (INT) - Número de huéspedes
- total_price (DECIMAL(10,2)) - Precio total
- status (ENUM) - Estado: pending/approved/rejected/cancelled
- special_requests (TEXT) - Solicitudes especiales
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de actualización
```

#### 4. **search_history** - Historial de búsquedas
```sql
- id (INT, AUTO_INCREMENT, PRIMARY KEY)
- user_id (INT, FOREIGN KEY) - ID del usuario
- search_term (VARCHAR(100)) - Término de búsqueda
- location (VARCHAR(100)) - Ubicación buscada
- filters (JSON) - Filtros aplicados
- created_at (TIMESTAMP) - Fecha de búsqueda
```

#### 5. **rewards** - Sistema de recompensas
```sql
- id (INT, AUTO_INCREMENT, PRIMARY KEY)
- user_id (INT, FOREIGN KEY) - ID del usuario
- points_earned (INT) - Puntos ganados
- points_spent (INT) - Puntos gastados
- activity_type (ENUM) - Tipo: booking/review/referral/login_bonus
- description (VARCHAR(255)) - Descripción de la actividad
- created_at (TIMESTAMP) - Fecha de la actividad
```

#### 6. **user_sessions** - Sesiones de usuario
```sql
- id (INT, AUTO_INCREMENT, PRIMARY KEY)
- user_id (INT, FOREIGN KEY) - ID del usuario
- session_token (VARCHAR(255), UNIQUE) - Token de sesión
- expires_at (TIMESTAMP) - Fecha de expiración
- created_at (TIMESTAMP) - Fecha de creación
```

#### 7. **social_auth** - Autenticación social
```sql
- id (INT, AUTO_INCREMENT, PRIMARY KEY)
- user_id (INT, FOREIGN KEY) - ID del usuario
- provider (ENUM) - Proveedor: google/facebook
- provider_user_id (VARCHAR(100)) - ID del usuario en el proveedor
- access_token (VARCHAR(255)) - Token de acceso
- refresh_token (VARCHAR(255)) - Token de refresco
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de actualización
```

## 🚀 Instalación y Configuración

### Base de Datos MySQL (Producción)

1. **Instalar MySQL** (si no está instalado)
2. **Ejecutar el script SQL:**
   ```bash
   mysql -u root -p < database.sql
   ```

3. **Configurar conexión en tu aplicación:**
   ```javascript
   const mysql = require('mysql2');
   
   const connection = mysql.createConnection({
     host: 'localhost',
     user: 'tu_usuario',
     password: 'tu_contraseña',
     database: 'checkin24hs_db'
   });
   ```

### Base de Datos JavaScript (Desarrollo)

1. **Incluir el archivo en tu HTML:**
   ```html
   <script src="database.js"></script>
   ```

2. **Usar la instancia global:**
   ```javascript
   // La base de datos ya está disponible como 'db'
   const users = db.getAllUsers();
   ```

## 📚 API de la Base de Datos JavaScript

### Gestión de Usuarios

```javascript
// Crear nuevo usuario
const newUser = db.createUser({
    name: 'Juan Pérez',
    email: 'juan@email.com',
    password: 'password123',
    phone: '+34 612 345 678'
});

// Autenticar usuario
const user = db.authenticateUser('juan@email.com', 'password123');

// Buscar usuario por email
const user = db.findUserByEmail('juan@email.com');

// Actualizar usuario
const updatedUser = db.updateUser(1, { rewards_points: 300 });
```

### Gestión de Hoteles

```javascript
// Obtener todos los hoteles
const hotels = db.getAllHotels();

// Buscar hotel por ID
const hotel = db.getHotelById(1);

// Buscar hoteles con filtros
const results = db.searchHotels('madrid', { rating: '4.5' });
```

### Gestión de Cotizaciones

```javascript
// Crear nueva cotización
const quote = db.createQuote({
    user_id: 1,
    hotel_id: 1,
    check_in_date: '2024-03-15',
    check_out_date: '2024-03-18',
    guests: 2,
    total_price: 450.00,
    special_requests: 'Habitación con vista'
});

// Obtener cotizaciones de un usuario
const userQuotes = db.getUserQuotes(1);

// Actualizar estado de cotización
const updatedQuote = db.updateQuoteStatus(1, 'approved');
```

### Historial de Búsquedas

```javascript
// Agregar búsqueda al historial
const search = db.addSearchHistory(1, {
    search_term: 'hotel madrid',
    location: 'Madrid',
    filters: { rating: '4.5' }
});

// Obtener historial de un usuario
const history = db.getUserSearchHistory(1);
```

### Sistema de Recompensas

```javascript
// Agregar recompensa
const reward = db.addReward(1, {
    points_earned: 100,
    activity_type: 'booking',
    description: 'Reserva en Hotel Terma de Puyehue'
});

// Obtener recompensas de un usuario
const rewards = db.getUserRewards(1);
```

### Gestión de Sesiones

```javascript
// Crear sesión
const session = db.createSession(1);

// Validar sesión
const validSession = db.validateSession(session.session_token);
```

### Estadísticas de Administración

```javascript
// Obtener estadísticas
const stats = db.getAdminStats();
// Retorna: { total_users, active_hotels, pending_quotes, total_rewards }
```

## 💾 Persistencia de Datos

### LocalStorage

La base de datos JavaScript utiliza localStorage para persistir datos:

```javascript
// Guardar todos los datos
db.saveAll();

// Resetear base de datos
db.resetDatabase();
```

### Datos Iniciales

La base de datos incluye datos de ejemplo:

- **3 usuarios** con diferentes puntos de recompensa
- **5 hoteles** en diferentes ciudades españolas
- **3 cotizaciones** con diferentes estados
- **3 búsquedas** en el historial
- **3 recompensas** de diferentes tipos

## 🔐 Seguridad

### En Producción (MySQL)

- Usar contraseñas hasheadas (bcrypt)
- Implementar validación de entrada
- Usar consultas preparadas
- Configurar SSL/TLS
- Implementar rate limiting

### En Desarrollo (JavaScript)

- Los datos se almacenan en localStorage del navegador
- No usar para datos sensibles en producción
- Implementar validación en el frontend

## 📊 Índices de Rendimiento

La base de datos MySQL incluye índices optimizados:

```sql
- idx_users_email - Búsqueda rápida por email
- idx_hotels_location - Filtrado por ubicación
- idx_quotes_user_id - Cotizaciones por usuario
- idx_quotes_status - Filtrado por estado
- idx_search_history_user_id - Historial por usuario
- idx_rewards_user_id - Recompensas por usuario
- idx_user_sessions_token - Validación de sesiones
- idx_social_auth_provider_user - Autenticación social
```

## 🛠️ Migración de Datos

### De JavaScript a MySQL

```javascript
// Exportar datos de localStorage
const exportData = {
    users: JSON.parse(localStorage.getItem('checkin24hs_users')),
    hotels: JSON.parse(localStorage.getItem('checkin24hs_hotels')),
    quotes: JSON.parse(localStorage.getItem('checkin24hs_quotes')),
    // ... otros datos
};
```

### Script de Migración

```sql
-- Insertar usuarios desde JavaScript
INSERT INTO users (name, email, phone, rewards_points) 
SELECT name, email, phone, rewards_points 
FROM imported_users;
```

## 🔧 Mantenimiento

### Backup de Datos

```bash
# Backup de MySQL
mysqldump -u root -p checkin24hs_db > backup.sql

# Backup de localStorage
# Exportar manualmente desde las herramientas de desarrollador
```

### Limpieza de Datos

```sql
-- Limpiar sesiones expiradas
DELETE FROM user_sessions WHERE expires_at < NOW();

-- Limpiar historial antiguo (más de 1 año)
DELETE FROM search_history WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);
```

## 📝 Notas de Desarrollo

- La base de datos JavaScript es ideal para prototipado y desarrollo
- Para producción, usar MySQL con las configuraciones de seguridad apropiadas
- Implementar migraciones para actualizaciones de esquema
- Considerar usar un ORM como Sequelize o Prisma para Node.js
- Implementar logging para auditoría de cambios

## 🆘 Soporte

Para problemas o preguntas sobre la base de datos:

1. Revisar los logs de error
2. Verificar la conectividad de la base de datos
3. Validar la estructura de datos
4. Consultar la documentación de MySQL/JavaScript 