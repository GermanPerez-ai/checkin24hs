# 🗄️ Guía: Base de Datos en la Nube para Checkin24hs

## 🎯 Recomendación: **Supabase**

### ¿Por qué Supabase?

✅ **PostgreSQL** - Base de datos relacional potente y confiable  
✅ **API REST automática** - No necesitas crear backend  
✅ **Autenticación incluida** - Sistema de usuarios listo  
✅ **Real-time** - Actualizaciones en tiempo real  
✅ **Gratis** - Plan gratuito generoso (500MB base de datos, 1GB storage)  
✅ **Fácil integración** - Funciona perfecto con aplicaciones estáticas  
✅ **Storage** - Para imágenes y archivos  
✅ **Dashboard visual** - Interfaz web para gestionar datos  

### Comparación con otras opciones

| Característica | Supabase | Firebase | MongoDB Atlas |
|---------------|----------|----------|---------------|
| Tipo de BD | PostgreSQL (SQL) | Firestore (NoSQL) | MongoDB (NoSQL) |
| API REST | ✅ Automática | ✅ Automática | ⚠️ Requiere código |
| Autenticación | ✅ Incluida | ✅ Incluida | ⚠️ Requiere código |
| Real-time | ✅ Incluido | ✅ Incluido | ⚠️ Requiere código |
| Plan Gratuito | 500MB BD | 1GB BD | 512MB BD |
| Facilidad | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Costo escalado | 💰💰 | 💰💰💰 | 💰💰 |

## 🚀 Implementación Paso a Paso

### Paso 1: Crear cuenta en Supabase

1. Ve a [supabase.com](https://supabase.com)
2. Haz clic en "Start your project"
3. Inicia sesión con GitHub (recomendado)
4. Crea un nuevo proyecto:
   - **Nombre**: `checkin24hs`
   - **Database Password**: (guarda esta contraseña)
   - **Region**: Elige la más cercana (ej: South America - São Paulo)
   - **Plan**: Free

### Paso 2: Crear las tablas

Una vez creado el proyecto, ve a **SQL Editor** y ejecuta este script:

```sql
-- Tabla de Hoteles
CREATE TABLE hotels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    location TEXT,
    description TEXT,
    rating DECIMAL(2,1),
    price DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'Activo',
    amenities JSONB,
    images JSONB,
    coordinates JSONB,
    google_maps TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Reservas
CREATE TABLE reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    hotel_id UUID REFERENCES hotels(id) ON DELETE SET NULL,
    customer_name VARCHAR(255),
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    check_in DATE,
    check_out DATE,
    adults INTEGER DEFAULT 1,
    children INTEGER DEFAULT 0,
    total_amount DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'Pendiente',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Cotizaciones
CREATE TABLE quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_name VARCHAR(255),
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    hotel_id UUID REFERENCES hotels(id) ON DELETE SET NULL,
    check_in DATE,
    check_out DATE,
    adults INTEGER DEFAULT 1,
    children INTEGER DEFAULT 0,
    total DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'Pendiente',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Gastos
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'fixed' o 'variable'
    category VARCHAR(100),
    subcategory VARCHAR(100),
    description TEXT,
    amount DECIMAL(10,2) NOT NULL,
    exchange_rate DECIMAL(10,4),
    usd_amount DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Usuarios del Sistema
CREATE TABLE system_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active',
    tipo_cuenta VARCHAR(50),
    birth_day INTEGER,
    birth_month INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Administradores del Dashboard
CREATE TABLE dashboard_admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    role VARCHAR(50) DEFAULT 'usuario', -- 'admin_total' o 'usuario'
    status VARCHAR(50) DEFAULT 'active',
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejor rendimiento
CREATE INDEX idx_reservations_hotel ON reservations(hotel_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_checkin ON reservations(check_in);
CREATE INDEX idx_quotes_status ON quotes(status);
CREATE INDEX idx_expenses_date ON expenses(date);
CREATE INDEX idx_expenses_type ON expenses(type);
```

### Paso 3: Obtener las credenciales de API

1. Ve a **Settings** → **API**
2. Copia:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: (clave pública)
   - **service_role key**: (clave privada - solo para backend)

### Paso 4: Instalar Supabase JS Client

Crea un archivo `supabase-config.js`:

```javascript
// supabase-config.js
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm'

const supabaseUrl = 'TU_PROJECT_URL'
const supabaseKey = 'TU_ANON_KEY'

export const supabase = createClient(supabaseUrl, supabaseKey)
```

O usando CDN en HTML:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script>
  const supabaseUrl = 'TU_PROJECT_URL'
  const supabaseKey = 'TU_ANON_KEY'
  const supabase = window.supabase.createClient(supabaseUrl, supabaseKey)
</script>
```

### Paso 5: Crear funciones de migración

Crea un archivo `supabase-client.js`:

```javascript
// supabase-client.js
class SupabaseClient {
    constructor(url, key) {
        this.client = window.supabase.createClient(url, key);
    }

    // ===== HOTELES =====
    async getHotels() {
        const { data, error } = await this.client
            .from('hotels')
            .select('*')
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        return data;
    }

    async createHotel(hotel) {
        const { data, error } = await this.client
            .from('hotels')
            .insert([hotel])
            .select();
        
        if (error) throw error;
        return data[0];
    }

    async updateHotel(id, updates) {
        const { data, error } = await this.client
            .from('hotels')
            .update({ ...updates, updated_at: new Date().toISOString() })
            .eq('id', id)
            .select();
        
        if (error) throw error;
        return data[0];
    }

    async deleteHotel(id) {
        const { error } = await this.client
            .from('hotels')
            .delete()
            .eq('id', id);
        
        if (error) throw error;
    }

    // ===== RESERVAS =====
    async getReservations(filters = {}) {
        let query = this.client.from('reservations').select('*, hotels(*)');
        
        if (filters.status) {
            query = query.eq('status', filters.status);
        }
        if (filters.hotel_id) {
            query = query.eq('hotel_id', filters.hotel_id);
        }
        if (filters.date_from) {
            query = query.gte('check_in', filters.date_from);
        }
        
        const { data, error } = await query.order('created_at', { ascending: false });
        
        if (error) throw error;
        return data;
    }

    async createReservation(reservation) {
        const { data, error } = await this.client
            .from('reservations')
            .insert([reservation])
            .select();
        
        if (error) throw error;
        return data[0];
    }

    async updateReservation(id, updates) {
        const { data, error } = await this.client
            .from('reservations')
            .update({ ...updates, updated_at: new Date().toISOString() })
            .eq('id', id)
            .select();
        
        if (error) throw error;
        return data[0];
    }

    // ===== COTIZACIONES =====
    async getQuotes(filters = {}) {
        let query = this.client.from('quotes').select('*, hotels(*)');
        
        if (filters.status) {
            query = query.eq('status', filters.status);
        }
        
        const { data, error } = await query.order('created_at', { ascending: false });
        
        if (error) throw error;
        return data;
    }

    async createQuote(quote) {
        const { data, error } = await this.client
            .from('quotes')
            .insert([quote])
            .select();
        
        if (error) throw error;
        return data[0];
    }

    // ===== GASTOS =====
    async getExpenses(filters = {}) {
        let query = this.client.from('expenses').select('*');
        
        if (filters.type) {
            query = query.eq('type', filters.type);
        }
        if (filters.date_from) {
            query = query.gte('date', filters.date_from);
        }
        if (filters.date_to) {
            query = query.lte('date', filters.date_to);
        }
        
        const { data, error } = await query.order('date', { ascending: false });
        
        if (error) throw error;
        return data;
    }

    async createExpense(expense) {
        const { data, error } = await this.client
            .from('expenses')
            .insert([expense])
            .select();
        
        if (error) throw error;
        return data[0];
    }

    // ===== USUARIOS =====
    async getUsers() {
        const { data, error } = await this.client
            .from('system_users')
            .select('*')
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        return data;
    }

    async createUser(user) {
        const { data, error } = await this.client
            .from('system_users')
            .insert([user])
            .select();
        
        if (error) throw error;
        return data[0];
    }

    // ===== REAL-TIME SUBSCRIPTIONS =====
    subscribeToReservations(callback) {
        return this.client
            .channel('reservations-changes')
            .on('postgres_changes', 
                { event: '*', schema: 'public', table: 'reservations' },
                callback
            )
            .subscribe();
    }

    subscribeToQuotes(callback) {
        return this.client
            .channel('quotes-changes')
            .on('postgres_changes',
                { event: '*', schema: 'public', table: 'quotes' },
                callback
            )
            .subscribe();
    }
}

// Exportar instancia global
window.supabaseClient = new SupabaseClient(
    'TU_PROJECT_URL',
    'TU_ANON_KEY'
);
```

### Paso 6: Migrar datos de localStorage a Supabase

Crea un script de migración `migrate-to-supabase.js`:

```javascript
// migrate-to-supabase.js
async function migrateLocalStorageToSupabase() {
    console.log('🚀 Iniciando migración de datos...');
    
    // Migrar hoteles
    const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
    if (hotels.length > 0) {
        console.log(`📦 Migrando ${hotels.length} hoteles...`);
        for (const hotel of hotels) {
            try {
                await window.supabaseClient.createHotel({
                    name: hotel.name,
                    location: hotel.location,
                    description: hotel.description,
                    rating: hotel.rating,
                    price: parseFloat(hotel.price?.replace('$', '').replace(/\./g, '') || 0),
                    status: hotel.status || 'Activo',
                    amenities: hotel.amenities || [],
                    images: hotel.images || [],
                    coordinates: hotel.coordinates || null,
                    google_maps: hotel.googleMaps || null
                });
            } catch (error) {
                console.error('Error migrando hotel:', hotel.name, error);
            }
        }
    }
    
    // Migrar reservas
    const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
    if (reservations.length > 0) {
        console.log(`📦 Migrando ${reservations.length} reservas...`);
        for (const reservation of reservations) {
            try {
                await window.supabaseClient.createReservation({
                    code: reservation.code,
                    hotel_id: null, // Necesitarías mapear el ID del hotel
                    customer_name: reservation.customerName,
                    customer_email: reservation.customerEmail,
                    customer_phone: reservation.customerPhone,
                    check_in: reservation.checkIn,
                    check_out: reservation.checkOut,
                    adults: reservation.adults || 1,
                    children: reservation.children || 0,
                    total_amount: reservation.totalAmount,
                    status: reservation.status || 'Pendiente',
                    notes: reservation.notes
                });
            } catch (error) {
                console.error('Error migrando reserva:', reservation.code, error);
            }
        }
    }
    
    // Migrar cotizaciones
    const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
    if (quotes.length > 0) {
        console.log(`📦 Migrando ${quotes.length} cotizaciones...`);
        for (const quote of quotes) {
            try {
                await window.supabaseClient.createQuote({
                    customer_name: quote.customerName,
                    customer_email: quote.customerEmail,
                    customer_phone: quote.customerPhone,
                    hotel_id: null,
                    check_in: quote.checkIn,
                    check_out: quote.checkOut,
                    adults: quote.adults || 1,
                    children: quote.children || 0,
                    total: quote.total,
                    status: quote.status || 'Pendiente',
                    notes: quote.notes
                });
            } catch (error) {
                console.error('Error migrando cotización:', error);
            }
        }
    }
    
    // Migrar gastos
    const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
    if (expenses.length > 0) {
        console.log(`📦 Migrando ${expenses.length} gastos...`);
        for (const expense of expenses) {
            try {
                await window.supabaseClient.createExpense({
                    date: expense.date,
                    type: expense.type,
                    category: expense.category,
                    subcategory: expense.subcategory,
                    description: expense.description,
                    amount: expense.amount,
                    exchange_rate: expense.exchangeRate,
                    usd_amount: expense.usd
                });
            } catch (error) {
                console.error('Error migrando gasto:', error);
            }
        }
    }
    
    console.log('✅ Migración completada');
}
```

### Paso 7: Actualizar el dashboard para usar Supabase

En lugar de:
```javascript
const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
```

Usa:
```javascript
const hotels = await window.supabaseClient.getHotels();
```

## 🔒 Seguridad: Row Level Security (RLS)

Supabase incluye seguridad a nivel de fila. Activa RLS en las tablas:

```sql
-- Activar RLS en todas las tablas
ALTER TABLE hotels ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Política: Todos pueden leer (ajusta según necesites)
CREATE POLICY "Public read access" ON hotels FOR SELECT USING (true);
CREATE POLICY "Public read access" ON reservations FOR SELECT USING (true);
CREATE POLICY "Public read access" ON quotes FOR SELECT USING (true);
CREATE POLICY "Public read access" ON expenses FOR SELECT USING (true);

-- Política: Solo autenticados pueden escribir (ajusta según necesites)
CREATE POLICY "Authenticated write access" ON hotels FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated write access" ON reservations FOR INSERT WITH CHECK (auth.role() = 'authenticated');
```

## 📊 Alternativas

### Opción 2: Firebase (Firestore)

Si prefieres Firebase:

**Ventajas:**
- Muy fácil de usar
- Real-time automático
- Buena documentación

**Desventajas:**
- NoSQL (menos estructura)
- Más costoso a largo plazo
- Menos flexible que PostgreSQL

### Opción 3: MongoDB Atlas

**Ventajas:**
- NoSQL flexible
- Plan gratuito generoso

**Desventajas:**
- Requiere más código
- No incluye autenticación
- Más complejo de configurar

## 🎯 Recomendación Final

**Usa Supabase** porque:
1. ✅ Es la mejor opción para tu caso (aplicación estática)
2. ✅ PostgreSQL es más potente que NoSQL para datos estructurados
3. ✅ API REST automática = menos código
4. ✅ Real-time incluido
5. ✅ Plan gratuito generoso
6. ✅ Fácil migración desde localStorage

## 📝 Próximos Pasos

1. Crear cuenta en Supabase
2. Crear las tablas con el SQL proporcionado
3. Obtener las credenciales de API
4. Integrar el cliente de Supabase en tu dashboard
5. Migrar datos de localStorage a Supabase
6. Actualizar todas las funciones para usar Supabase en lugar de localStorage

¿Quieres que te ayude a implementar esto paso a paso?

