# 🗄️ Guía de Migración: localStorage → Base de Datos Real

## 📋 Resumen

Esta guía te ayudará a migrar el sistema de Checkin24hs de `localStorage` (almacenamiento en el navegador) a una **base de datos real** (MySQL, PostgreSQL, Firebase, etc.).

---

## 🔍 Datos Actuales en localStorage

### Datos Identificados:

1. **`hotelsDB`** - Hoteles y su información
2. **`reservationsDB`** - Reservas de clientes
3. **`quotesDB`** - Cotizaciones pendientes
4. **`checkin24hs_users`** - Usuarios registrados
5. **`clientesDB`** - Base de datos de clientes
6. **`agentsDB`** - Agentes de ventas
7. **`gastosDB`** - Gastos del negocio
8. **`flor_learning_interactions`** - Interacciones del chatbot Flor
9. **`flor_hotel_knowledge_{hotelId}`** - Conocimiento específico por hotel
10. **`flor_ai_config`** - Configuración de IA
11. **`whatsappConfig`** - Configuración de WhatsApp

---

## 🎯 Opciones de Base de Datos

### Opción 1: MySQL/PostgreSQL (Recomendado para Producción)
**Ventajas:**
- ✅ Robusto y confiable
- ✅ Escalable
- ✅ Soporte completo de SQL
- ✅ Ideal para aplicaciones empresariales

**Desventajas:**
- ⚠️ Requiere servidor dedicado
- ⚠️ Necesita mantenimiento

### Opción 2: Firebase (Recomendado para Inicio Rápido)
**Ventajas:**
- ✅ Fácil de configurar
- ✅ Gratis hasta cierto límite
- ✅ Real-time automático
- ✅ Autenticación incluida

**Desventajas:**
- ⚠️ Costos pueden aumentar con el uso
- ⚠️ Menos control sobre los datos

### Opción 3: MongoDB (NoSQL)
**Ventajas:**
- ✅ Flexible (sin esquema fijo)
- ✅ Fácil de escalar
- ✅ Ideal para datos JSON

**Desventajas:**
- ⚠️ Curva de aprendizaje
- ⚠️ Menos maduro que SQL

---

## 🚀 Migración con MySQL (Paso a Paso)

### Paso 1: Crear la Base de Datos

Ya tienes el archivo `database.sql` con el esquema básico. Necesitamos expandirlo:

```sql
-- Base de datos expandida para Checkin24hs
CREATE DATABASE IF NOT EXISTS checkin24hs_db;
USE checkin24hs_db;

-- Tabla de hoteles (expandida)
CREATE TABLE hotels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    address TEXT,
    description TEXT,
    rating DECIMAL(2,1) DEFAULT 0.0,
    image_url VARCHAR(255),
    amenities JSON,
    price_range JSON,
    is_active BOOLEAN DEFAULT TRUE,
    status VARCHAR(50) DEFAULT 'Activo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de reservas
CREATE TABLE reservations (
    id VARCHAR(50) PRIMARY KEY,
    reservation_code VARCHAR(50) UNIQUE,
    hotel_id INT,
    hotel_name VARCHAR(100),
    client_name VARCHAR(100),
    client_email VARCHAR(100),
    client_phone VARCHAR(20),
    check_in DATE,
    check_out DATE,
    adults INT DEFAULT 1,
    children INT DEFAULT 0,
    total_amount DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'Confirmada',
    agent VARCHAR(100),
    agent_name VARCHAR(100),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    reservation_date DATE,
    FOREIGN KEY (hotel_id) REFERENCES hotels(id) ON DELETE SET NULL
);

-- Tabla de cotizaciones
CREATE TABLE quotes (
    id VARCHAR(50) PRIMARY KEY,
    hotel_id INT,
    hotel_name VARCHAR(100),
    client_name VARCHAR(100),
    client_email VARCHAR(100),
    client_phone VARCHAR(20),
    check_in DATE,
    check_out DATE,
    nights INT,
    adults INT,
    children INT,
    infants INT,
    tariff DECIMAL(10,2),
    discount DECIMAL(10,2),
    final_tariff DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    source VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hotel_id) REFERENCES hotels(id) ON DELETE SET NULL
);

-- Tabla de usuarios
CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    password_hash VARCHAR(255),
    fecha_nacimiento VARCHAR(10),
    fecha_registro TIMESTAMP,
    tipo_cuenta VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de agentes
CREATE TABLE agents (
    id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE,
    name VARCHAR(100),
    agency VARCHAR(100),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Tabla de gastos
CREATE TABLE expenses (
    id VARCHAR(50) PRIMARY KEY,
    description TEXT,
    amount DECIMAL(10,2),
    category VARCHAR(100),
    type VARCHAR(50),
    date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de conocimiento de hoteles (para Flor)
CREATE TABLE hotel_knowledge (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_id INT NOT NULL,
    description TEXT,
    address TEXT,
    services_details JSON,
    room_types JSON,
    price_info JSON,
    policies JSON,
    additional_info JSON,
    integrations JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hotel_id) REFERENCES hotels(id) ON DELETE CASCADE,
    UNIQUE KEY unique_hotel (hotel_id)
);

-- Tabla de interacciones de Flor
CREATE TABLE flor_interactions (
    id VARCHAR(100) PRIMARY KEY,
    user_message TEXT,
    bot_response TEXT,
    intent VARCHAR(50),
    hotel_id INT,
    success BOOLEAN DEFAULT TRUE,
    used_ai BOOLEAN DEFAULT FALSE,
    response_length INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hotel_id) REFERENCES hotels(id) ON DELETE SET NULL
);

-- Índices para mejor rendimiento
CREATE INDEX idx_reservations_hotel ON reservations(hotel_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_checkin ON reservations(check_in);
CREATE INDEX idx_quotes_status ON quotes(status);
CREATE INDEX idx_flor_interactions_timestamp ON flor_interactions(timestamp);
```

### Paso 2: Crear el Backend (Node.js + Express)

Crea un archivo `server-api.js`:

```javascript
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

// Configuración de la base de datos
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'checkin24hs_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
};

const pool = mysql.createPool(dbConfig);

// ===== MIDDLEWARE DE AUTENTICACIÓN =====
const authenticateToken = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Token no proporcionado' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'tu-secret-key');
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(403).json({ error: 'Token inválido' });
    }
};

// ===== API DE HOTELES =====
app.get('/api/hotels', async (req, res) => {
    try {
        const [hotels] = await pool.execute('SELECT * FROM hotels WHERE is_active = 1 ORDER BY name');
        res.json(hotels);
    } catch (error) {
        console.error('Error al obtener hoteles:', error);
        res.status(500).json({ error: 'Error al obtener hoteles' });
    }
});

app.post('/api/hotels', authenticateToken, async (req, res) => {
    try {
        const { name, location, address, description, rating, image_url, amenities, price_range } = req.body;
        const [result] = await pool.execute(
            'INSERT INTO hotels (name, location, address, description, rating, image_url, amenities, price_range) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [name, location, address, description, rating, image_url, JSON.stringify(amenities), JSON.stringify(price_range)]
        );
        res.json({ id: result.insertId, ...req.body });
    } catch (error) {
        console.error('Error al crear hotel:', error);
        res.status(500).json({ error: 'Error al crear hotel' });
    }
});

app.put('/api/hotels/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { name, location, address, description, rating, image_url, amenities, price_range, is_active } = req.body;
        await pool.execute(
            'UPDATE hotels SET name = ?, location = ?, address = ?, description = ?, rating = ?, image_url = ?, amenities = ?, price_range = ?, is_active = ? WHERE id = ?',
            [name, location, address, description, rating, image_url, JSON.stringify(amenities), JSON.stringify(price_range), is_active, id]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('Error al actualizar hotel:', error);
        res.status(500).json({ error: 'Error al actualizar hotel' });
    }
});

// ===== API DE RESERVAS =====
app.get('/api/reservations', authenticateToken, async (req, res) => {
    try {
        const { status, hotel_id, date_from, date_to } = req.query;
        let query = 'SELECT * FROM reservations WHERE 1=1';
        const params = [];

        if (status) {
            query += ' AND status = ?';
            params.push(status);
        }
        if (hotel_id) {
            query += ' AND hotel_id = ?';
            params.push(hotel_id);
        }
        if (date_from) {
            query += ' AND check_in >= ?';
            params.push(date_from);
        }
        if (date_to) {
            query += ' AND check_in <= ?';
            params.push(date_to);
        }

        query += ' ORDER BY created_at DESC';
        const [reservations] = await pool.execute(query, params);
        res.json(reservations);
    } catch (error) {
        console.error('Error al obtener reservas:', error);
        res.status(500).json({ error: 'Error al obtener reservas' });
    }
});

app.post('/api/reservations', authenticateToken, async (req, res) => {
    try {
        const reservation = req.body;
        await pool.execute(
            `INSERT INTO reservations (id, reservation_code, hotel_id, hotel_name, client_name, client_email, client_phone, 
             check_in, check_out, adults, children, total_amount, status, agent, agent_name, created_at, updated_at, reservation_date)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                reservation.id, reservation.reservation_code, reservation.hotel_id, reservation.hotel_name,
                reservation.client_name, reservation.client_email, reservation.client_phone,
                reservation.check_in, reservation.check_out, reservation.adults, reservation.children,
                reservation.total_amount, reservation.status, reservation.agent, reservation.agent_name,
                reservation.created_at || new Date(), reservation.updated_at || new Date(), reservation.reservation_date
            ]
        );
        res.json({ success: true, id: reservation.id });
    } catch (error) {
        console.error('Error al crear reserva:', error);
        res.status(500).json({ error: 'Error al crear reserva' });
    }
});

// ===== API DE COTIZACIONES =====
app.get('/api/quotes', authenticateToken, async (req, res) => {
    try {
        const { status } = req.query;
        let query = 'SELECT * FROM quotes WHERE 1=1';
        const params = [];

        if (status) {
            query += ' AND status = ?';
            params.push(status);
        }

        query += ' ORDER BY created_at DESC';
        const [quotes] = await pool.execute(query, params);
        res.json(quotes);
    } catch (error) {
        console.error('Error al obtener cotizaciones:', error);
        res.status(500).json({ error: 'Error al obtener cotizaciones' });
    }
});

app.post('/api/quotes', async (req, res) => {
    try {
        const quote = req.body;
        await pool.execute(
            `INSERT INTO quotes (id, hotel_id, hotel_name, client_name, client_email, client_phone, 
             check_in, check_out, nights, adults, children, infants, tariff, discount, final_tariff, status, notes, source)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                quote.id, quote.hotel_id, quote.hotel, quote.clientName, quote.clientEmail, quote.clientPhone,
                quote.checkIn, quote.checkOut, quote.nights, quote.adults, quote.children, quote.infants || 0,
                quote.tariff || 0, quote.discount || 0, quote.finalTariff || 0, quote.status || 'pending',
                quote.notes, quote.source || 'cliente'
            ]
        );
        res.json({ success: true, id: quote.id });
    } catch (error) {
        console.error('Error al crear cotización:', error);
        res.status(500).json({ error: 'Error al crear cotización' });
    }
});

// ===== API DE USUARIOS =====
app.get('/api/users', authenticateToken, async (req, res) => {
    try {
        const [users] = await pool.execute('SELECT id, name, email, phone, fecha_registro, tipo_cuenta, status FROM users ORDER BY fecha_registro DESC');
        res.json(users);
    } catch (error) {
        console.error('Error al obtener usuarios:', error);
        res.status(500).json({ error: 'Error al obtener usuarios' });
    }
});

app.post('/api/users/register', async (req, res) => {
    try {
        const { name, email, password, phone, fecha_nacimiento } = req.body;
        const password_hash = await bcrypt.hash(password, 10);
        const id = 'user_' + Date.now();
        
        await pool.execute(
            'INSERT INTO users (id, name, email, password_hash, phone, fecha_nacimiento, fecha_registro) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [id, name, email, password_hash, phone, fecha_nacimiento, new Date()]
        );
        
        res.json({ success: true, id });
    } catch (error) {
        console.error('Error al registrar usuario:', error);
        res.status(500).json({ error: 'Error al registrar usuario' });
    }
});

app.post('/api/users/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const [users] = await pool.execute('SELECT * FROM users WHERE email = ?', [email]);
        
        if (users.length === 0) {
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }
        
        const user = users[0];
        const validPassword = await bcrypt.compare(password, user.password_hash);
        
        if (!validPassword) {
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }
        
        const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || 'tu-secret-key', { expiresIn: '24h' });
        res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
    } catch (error) {
        console.error('Error al iniciar sesión:', error);
        res.status(500).json({ error: 'Error al iniciar sesión' });
    }
});

// ===== API DE AGENTES =====
app.get('/api/agents', authenticateToken, async (req, res) => {
    try {
        const [agents] = await pool.execute('SELECT * FROM agents ORDER BY created_at DESC');
        res.json(agents);
    } catch (error) {
        console.error('Error al obtener agentes:', error);
        res.status(500).json({ error: 'Error al obtener agentes' });
    }
});

app.post('/api/agents', authenticateToken, async (req, res) => {
    try {
        const { code, name, agency, active } = req.body;
        const id = 'agent-' + Date.now();
        await pool.execute(
            'INSERT INTO agents (id, code, name, agency, active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [id, code, name, agency, active !== false, new Date(), new Date()]
        );
        res.json({ success: true, id });
    } catch (error) {
        console.error('Error al crear agente:', error);
        res.status(500).json({ error: 'Error al crear agente' });
    }
});

// ===== API DE CONOCIMIENTO DE HOTELES (FLOR) =====
app.get('/api/hotel-knowledge/:hotelId', async (req, res) => {
    try {
        const { hotelId } = req.params;
        const [knowledge] = await pool.execute('SELECT * FROM hotel_knowledge WHERE hotel_id = ?', [hotelId]);
        
        if (knowledge.length === 0) {
            return res.json(null);
        }
        
        const data = knowledge[0];
        // Convertir JSON strings a objetos
        data.services_details = JSON.parse(data.services_details || '{}');
        data.room_types = JSON.parse(data.room_types || '[]');
        data.price_info = JSON.parse(data.price_info || '{}');
        data.policies = JSON.parse(data.policies || '{}');
        data.additional_info = JSON.parse(data.additional_info || '{}');
        data.integrations = JSON.parse(data.integrations || '[]');
        
        res.json(data);
    } catch (error) {
        console.error('Error al obtener conocimiento:', error);
        res.status(500).json({ error: 'Error al obtener conocimiento' });
    }
});

app.post('/api/hotel-knowledge/:hotelId', authenticateToken, async (req, res) => {
    try {
        const { hotelId } = req.params;
        const knowledge = req.body;
        
        await pool.execute(
            `INSERT INTO hotel_knowledge (hotel_id, description, address, services_details, room_types, price_info, policies, additional_info, integrations)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
             description = VALUES(description),
             address = VALUES(address),
             services_details = VALUES(services_details),
             room_types = VALUES(room_types),
             price_info = VALUES(price_info),
             policies = VALUES(policies),
             additional_info = VALUES(additional_info),
             integrations = VALUES(integrations),
             updated_at = CURRENT_TIMESTAMP`,
            [
                hotelId,
                knowledge.description,
                knowledge.address,
                JSON.stringify(knowledge.servicesDetails || {}),
                JSON.stringify(knowledge.roomTypes || []),
                JSON.stringify(knowledge.priceInfo || {}),
                JSON.stringify(knowledge.policies || {}),
                JSON.stringify(knowledge.additionalInfo || {}),
                JSON.stringify(knowledge.integrations || [])
            ]
        );
        
        res.json({ success: true });
    } catch (error) {
        console.error('Error al guardar conocimiento:', error);
        res.status(500).json({ error: 'Error al guardar conocimiento' });
    }
});

// ===== API DE INTERACCIONES DE FLOR =====
app.get('/api/flor-interactions', authenticateToken, async (req, res) => {
    try {
        const { limit = 100 } = req.query;
        const [interactions] = await pool.execute(
            'SELECT * FROM flor_interactions ORDER BY timestamp DESC LIMIT ?',
            [parseInt(limit)]
        );
        res.json(interactions);
    } catch (error) {
        console.error('Error al obtener interacciones:', error);
        res.status(500).json({ error: 'Error al obtener interacciones' });
    }
});

app.post('/api/flor-interactions', async (req, res) => {
    try {
        const interaction = req.body;
        await pool.execute(
            'INSERT INTO flor_interactions (id, user_message, bot_response, intent, hotel_id, success, used_ai, response_length) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
                interaction.id,
                interaction.userMessage,
                typeof interaction.botResponse === 'string' ? interaction.botResponse : JSON.stringify(interaction.botResponse),
                interaction.intent || 'consulta_general',
                interaction.hotelId,
                interaction.success !== false,
                interaction.usedAI || false,
                interaction.responseLength || 0
            ]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('Error al guardar interacción:', error);
        res.status(500).json({ error: 'Error al guardar interacción' });
    }
});

// ===== API DE ESTADÍSTICAS =====
app.get('/api/stats', authenticateToken, async (req, res) => {
    try {
        const [hotelCount] = await pool.execute('SELECT COUNT(*) as count FROM hotels WHERE is_active = 1');
        const [reservationCount] = await pool.execute('SELECT COUNT(*) as count FROM reservations');
        const [quoteCount] = await pool.execute('SELECT COUNT(*) as count FROM quotes WHERE status = "pending"');
        const [userCount] = await pool.execute('SELECT COUNT(*) as count FROM users');
        
        res.json({
            totalHotels: hotelCount[0].count,
            totalReservations: reservationCount[0].count,
            pendingQuotes: quoteCount[0].count,
            totalUsers: userCount[0].count
        });
    } catch (error) {
        console.error('Error al obtener estadísticas:', error);
        res.status(500).json({ error: 'Error al obtener estadísticas' });
    }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`🚀 Servidor API corriendo en puerto ${PORT}`);
});
```

### Paso 3: Instalar Dependencias

Crea un `package.json`:

```json
{
  "name": "checkin24hs-api",
  "version": "1.0.0",
  "description": "API Backend para Checkin24hs",
  "main": "server-api.js",
  "scripts": {
    "start": "node server-api.js",
    "dev": "nodemon server-api.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "cors": "^2.8.5",
    "bcrypt": "^5.1.1",
    "jsonwebtoken": "^9.0.2",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

Instala las dependencias:
```bash
npm install
```

### Paso 4: Crear Cliente API para el Frontend

Crea un archivo `api-client.js`:

```javascript
// Cliente API para reemplazar localStorage
class Checkin24hsAPI {
    constructor(baseURL = 'http://localhost:3001') {
        this.baseURL = baseURL;
        this.token = localStorage.getItem('auth_token');
    }

    // Método genérico para hacer peticiones
    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers
        };

        if (this.token) {
            headers['Authorization'] = `Bearer ${this.token}`;
        }

        try {
            const response = await fetch(url, {
                ...options,
                headers
            });

            if (!response.ok) {
                const error = await response.json().catch(() => ({ error: 'Error desconocido' }));
                throw new Error(error.error || `Error ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error(`Error en ${endpoint}:`, error);
            throw error;
        }
    }

    // ===== HOTELES =====
    async getHotels() {
        return this.request('/api/hotels');
    }

    async createHotel(hotelData) {
        return this.request('/api/hotels', {
            method: 'POST',
            body: JSON.stringify(hotelData)
        });
    }

    async updateHotel(id, hotelData) {
        return this.request(`/api/hotels/${id}`, {
            method: 'PUT',
            body: JSON.stringify(hotelData)
        });
    }

    // ===== RESERVAS =====
    async getReservations(filters = {}) {
        const params = new URLSearchParams(filters);
        return this.request(`/api/reservations?${params}`);
    }

    async createReservation(reservationData) {
        return this.request('/api/reservations', {
            method: 'POST',
            body: JSON.stringify(reservationData)
        });
    }

    async updateReservation(id, reservationData) {
        return this.request(`/api/reservations/${id}`, {
            method: 'PUT',
            body: JSON.stringify(reservationData)
        });
    }

    // ===== COTIZACIONES =====
    async getQuotes(status = null) {
        const params = status ? `?status=${status}` : '';
        return this.request(`/api/quotes${params}`);
    }

    async createQuote(quoteData) {
        return this.request('/api/quotes', {
            method: 'POST',
            body: JSON.stringify(quoteData)
        });
    }

    // ===== USUARIOS =====
    async getUsers() {
        return this.request('/api/users');
    }

    async registerUser(userData) {
        return this.request('/api/users/register', {
            method: 'POST',
            body: JSON.stringify(userData)
        });
    }

    async loginUser(email, password) {
        const response = await this.request('/api/users/login', {
            method: 'POST',
            body: JSON.stringify({ email, password })
        });
        
        if (response.token) {
            this.token = response.token;
            localStorage.setItem('auth_token', response.token);
        }
        
        return response;
    }

    // ===== AGENTES =====
    async getAgents() {
        return this.request('/api/agents');
    }

    async createAgent(agentData) {
        return this.request('/api/agents', {
            method: 'POST',
            body: JSON.stringify(agentData)
        });
    }

    // ===== CONOCIMIENTO DE HOTELES (FLOR) =====
    async getHotelKnowledge(hotelId) {
        return this.request(`/api/hotel-knowledge/${hotelId}`);
    }

    async saveHotelKnowledge(hotelId, knowledgeData) {
        return this.request(`/api/hotel-knowledge/${hotelId}`, {
            method: 'POST',
            body: JSON.stringify(knowledgeData)
        });
    }

    // ===== INTERACCIONES DE FLOR =====
    async getFlorInteractions(limit = 100) {
        return this.request(`/api/flor-interactions?limit=${limit}`);
    }

    async saveFlorInteraction(interactionData) {
        return this.request('/api/flor-interactions', {
            method: 'POST',
            body: JSON.stringify(interactionData)
        });
    }

    // ===== ESTADÍSTICAS =====
    async getStats() {
        return this.request('/api/stats');
    }
}

// Crear instancia global
window.api = new Checkin24hsAPI();
```

### Paso 5: Modificar el Código Frontend

**Ejemplo: Reemplazar localStorage en dashboard.html**

**ANTES:**
```javascript
// Obtener hoteles
const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');

// Guardar hotel
localStorage.setItem('hotelsDB', JSON.stringify(hotels));
```

**DESPUÉS:**
```javascript
// Obtener hoteles
const hotels = await window.api.getHotels();

// Guardar hotel
await window.api.createHotel(newHotel);
```

### Paso 6: Script de Migración de Datos

Crea `migrate-data.js`:

```javascript
const mysql = require('mysql2/promise');
const fs = require('fs');

// Leer datos de localStorage (exportados manualmente)
const localStorageData = JSON.parse(fs.readFileSync('localStorage-export.json', 'utf8'));

async function migrateData() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: 'tu-password',
        database: 'checkin24hs_db'
    });

    try {
        // Migrar hoteles
        if (localStorageData.hotelsDB) {
            for (const hotel of localStorageData.hotelsDB) {
                await connection.execute(
                    'INSERT INTO hotels (id, name, location, address, description, rating, amenities, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                    [
                        hotel.id,
                        hotel.name,
                        hotel.location,
                        hotel.address,
                        hotel.description,
                        hotel.rating || 0,
                        JSON.stringify(hotel.amenities || []),
                        hotel.is_active !== false
                    ]
                );
            }
            console.log(`✅ Migrados ${localStorageData.hotelsDB.length} hoteles`);
        }

        // Migrar reservas
        if (localStorageData.reservationsDB) {
            for (const reservation of localStorageData.reservationsDB) {
                await connection.execute(
                    `INSERT INTO reservations (id, reservation_code, hotel_id, hotel_name, client_name, client_email, 
                     client_phone, check_in, check_out, adults, children, total_amount, status, agent, created_at)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                    [
                        reservation.id,
                        reservation.reservationCode,
                        reservation.hotelId,
                        reservation.hotelName,
                        reservation.clientName,
                        reservation.clientEmail,
                        reservation.clientPhone,
                        reservation.checkIn,
                        reservation.checkOut,
                        reservation.adults || 1,
                        reservation.children || 0,
                        reservation.totalAmount,
                        reservation.status,
                        reservation.agent,
                        reservation.createdAt || new Date()
                    ]
                );
            }
            console.log(`✅ Migradas ${localStorageData.reservationsDB.length} reservas`);
        }

        // Migrar cotizaciones
        if (localStorageData.quotesDB) {
            for (const quote of localStorageData.quotesDB) {
                await connection.execute(
                    `INSERT INTO quotes (id, hotel_id, hotel_name, client_name, client_email, client_phone,
                     check_in, check_out, nights, adults, children, status, notes, source)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                    [
                        quote.id,
                        quote.hotelId,
                        quote.hotel,
                        quote.clientName,
                        quote.clientEmail,
                        quote.clientPhone,
                        quote.checkIn,
                        quote.checkOut,
                        quote.nights,
                        quote.adults,
                        quote.children,
                        quote.status,
                        quote.notes,
                        quote.source
                    ]
                );
            }
            console.log(`✅ Migradas ${localStorageData.quotesDB.length} cotizaciones`);
        }

        console.log('✅ Migración completada');
    } catch (error) {
        console.error('❌ Error en migración:', error);
    } finally {
        await connection.end();
    }
}

migrateData();
```

---

## 🔄 Migración con Firebase (Alternativa Más Simple)

### Paso 1: Configurar Firebase

1. Ve a [firebase.google.com](https://firebase.google.com)
2. Crea un proyecto
3. Habilita **Firestore Database**
4. Obtén las credenciales

### Paso 2: Instalar Firebase SDK

```bash
npm install firebase
```

### Paso 3: Configurar Firebase en el Frontend

Crea `firebase-config.js`:

```javascript
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
    apiKey: "tu-api-key",
    authDomain: "tu-proyecto.firebaseapp.com",
    projectId: "tu-proyecto-id",
    storageBucket: "tu-proyecto.appspot.com",
    messagingSenderId: "123456789",
    appId: "tu-app-id"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
```

### Paso 4: Reemplazar localStorage con Firestore

**Ejemplo:**
```javascript
import { collection, getDocs, addDoc, updateDoc, doc } from 'firebase/firestore';
import { db } from './firebase-config';

// Obtener hoteles
async function getHotels() {
    const querySnapshot = await getDocs(collection(db, 'hotels'));
    return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

// Guardar hotel
async function saveHotel(hotelData) {
    await addDoc(collection(db, 'hotels'), hotelData);
}
```

---

## 📝 Checklist de Migración

- [ ] Crear base de datos (MySQL/Firebase)
- [ ] Crear backend API (Node.js)
- [ ] Crear cliente API en frontend
- [ ] Exportar datos de localStorage
- [ ] Migrar datos a base de datos
- [ ] Reemplazar todas las llamadas a localStorage
- [ ] Probar todas las funcionalidades
- [ ] Configurar autenticación
- [ ] Configurar HTTPS
- [ ] Hacer backup de datos antiguos

---

## 🆘 Troubleshooting

### Error: "Cannot connect to database"
- Verifica que MySQL esté corriendo
- Verifica credenciales en `.env`
- Verifica que el puerto esté abierto

### Error: "CORS policy"
- Configura CORS en el servidor
- O usa un proxy

### Datos no se guardan
- Verifica que el token de autenticación sea válido
- Revisa los logs del servidor
- Verifica permisos de la base de datos

---

## ✅ Ventajas de la Migración

1. **Datos centralizados** - Todos los usuarios ven los mismos datos
2. **Backup automático** - La base de datos se respalda automáticamente
3. **Escalabilidad** - Puede manejar millones de registros
4. **Seguridad** - Mejor control de acceso y encriptación
5. **Sincronización** - Datos actualizados en tiempo real
6. **Análisis** - Fácil generar reportes y estadísticas

¡Éxito con tu migración! 🎉

