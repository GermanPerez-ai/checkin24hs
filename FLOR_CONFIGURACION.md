# 🌸 Configuración de Flor - Guía Completa

## 📚 Información que Flor Maneja de Forma Autónoma

Flor ahora está configurada para ser **completamente autónoma** y responder a consultas sobre:

### ✅ **1. Catálogo de Hoteles**
- **Lista completa** de hoteles disponibles
- **Información detallada** de cada hotel (nombre, ubicación, descripción, rating)
- **Búsqueda por nombre** o ubicación
- **Información completa** cuando menciona un hotel específico

**Fuente de datos**: `localStorage.getItem('hotelsDB')`

### ✅ **2. Ubicaciones y Direcciones**
- **Dirección exacta** de cada hotel
- **Ubicación general** (ciudad/región)
- **Información contextual** sobre la ubicación
- **Lista completa** de ubicaciones cuando no especifica hotel

### ✅ **3. Servicios y Amenidades**
- **Lista completa** de servicios por hotel
- **Servicios incluidos** vs **servicios con costo adicional**
- **Búsqueda por servicio** (qué hoteles tienen spa, piscina, etc.)
- **Descripciones detalladas** de cada servicio

**Servicios disponibles:**
- Aguas Termales, Spa, Restaurante, Gimnasio
- Piscina (Natural/Climatizada), Bar
- Actividades de Montaña, Vistas Panorámicas
- Wi-Fi, Estacionamiento, Desayuno
- Traslado Aeropuerto, Guía de Tours
- Y más según configuración de cada hotel

### ✅ **4. Precios y Tarifas**
- **Rangos de precios** por categoría (económico, medio, alto, premium)
- **Precios estimados** según rating del hotel
- **Información de métodos de pago**
- **Política de depósito** (30% requerido)

**Rangos disponibles:**
- Económico: $150 - $300 USD/noche
- Medio: $300 - $600 USD/noche
- Alto: $600 - $1,500 USD/noche
- Premium: $1,500 - $3,000+ USD/noche

### ✅ **5. Políticas de la Agencia**
Flor conoce automáticamente:

**Políticas de Reserva:**
- Depósito requerido: 30%
- Métodos de pago: Tarjeta de crédito, Transferencia bancaria, PayPal
- Plazo de confirmación: 24 horas

**Políticas de Cancelación:**
- Cancelación gratuita: Hasta 72 horas antes del check-in
- Penalizaciones: 50% entre 48-72h, 100% con menos de 48h
- Excepciones: Casos de fuerza mayor

**Check-in / Check-out:**
- Check-in: Desde las 15:00 horas
- Check-out: Hasta las 11:00 horas
- Early check-in / Late check-out: Disponible según disponibilidad

**Política de Mascotas:**
- Generalmente no permitidas
- Excepciones disponibles según hotel

## 🔄 **Cómo Flor Obtiene la Información**

### **Automatizado desde localStorage:**
```javascript
// Flor obtiene automáticamente:
const hotels = localStorage.getItem('hotelsDB'); // Todos los hoteles
```

### **Datos que Flor Lee de Cada Hotel:**
- `name` - Nombre del hotel
- `location` - Ubicación (ciudad/región)
- `address` - Dirección completa
- `description` - Descripción detallada
- `rating` - Calificación (0-5)
- `amenities` - Lista de servicios/amenidades
- `price` / `priceRange` / `price_range` - Información de precios (opcional)
- `is_active` - Si está activo o no

### **Información Estática en Base de Conocimiento:**
- Políticas de la agencia
- Descripciones de servicios comunes
- Rangos de precios generales
- Palabras clave para detectar intenciones
- Respuestas predefinidas

## 📝 **Ejemplos de Consultas que Flor Puede Responder**

### **Consultas de Hoteles:**
- "¿Qué hoteles tienen disponibles?"
- "¿Trabajan con Hotel Puyehue?"
- "Dame información sobre Huilo-Huilo"
- "¿Qué hoteles tienen en la zona de montaña?"

**Respuesta**: Flor lista todos los hoteles con información básica (nombre, ubicación, rating)

### **Consultas de Ubicación:**
- "¿Dónde está el Hotel Puyehue?"
- "Ubicación de Huilo-Huilo"
- "¿Dónde queda ese hotel?"

**Respuesta**: Flor proporciona dirección exacta y ubicación del hotel

### **Consultas de Servicios:**
- "¿Qué servicios tiene el Hotel Puyehue?"
- "¿Tiene spa el hotel?"
- "¿Qué hoteles tienen piscina?"
- "¿Incluye desayuno?"

**Respuesta**: Flor lista servicios incluidos y servicios adicionales del hotel específico

### **Consultas de Precios:**
- "¿Cuánto cuesta el Hotel Puyehue?"
- "Precios del hotel"
- "¿Qué rango de precios tienen?"

**Respuesta**: Flor proporciona rangos de precios y métodos de pago

### **Consultas sobre Políticas:**
- "¿Cómo funciona la cancelación?"
- "¿Cuándo es el check-in?"
- "¿Aceptan mascotas?"
- "¿Qué métodos de pago aceptan?"

**Respuesta**: Flor explica las políticas de la agencia

## 🔧 **Cómo Actualizar la Información de Flor**

### **1. Actualizar Información de Hoteles:**
La información de hoteles se actualiza automáticamente desde `localStorage.getItem('hotelsDB')`.

**Para actualizar hoteles:**
1. Usa el dashboard de Checkin24hs para agregar/modificar hoteles
2. Los cambios se guardan automáticamente en `localStorage`
3. Flor accederá a la información actualizada automáticamente

### **2. Actualizar Políticas:**
Edita `flor-knowledge-base.js` en las secciones:
- **Líneas 58-79**: `policies` - Políticas de reserva, cancelación, check-in/out
- **Líneas 82-87**: `priceRanges` - Rangos de precios

### **3. Actualizar Servicios:**
Edita `flor-knowledge-base.js`:
- **Líneas 14-55**: `services` - Servicios comunes y sus descripciones
- **Líneas 141-156**: `amenitiesMap` - Mapeo de amenities de hoteles

### **4. Agregar Nuevas Respuestas:**
Edita `flor-knowledge-base.js`:
- **Líneas 105-112**: `responses` - Respuestas predefinidas
- **Líneas 89-102**: `intents` - Palabras clave para detectar intenciones

## 🚀 **Respuestas Autónomas vs Escalación a Humano**

### **Flor Responde de Forma Autónoma:**
✅ Consultas sobre hoteles disponibles
✅ Información de ubicaciones y direcciones
✅ Lista de servicios y amenidades
✅ Rangos de precios generales
✅ Políticas de reserva y cancelación
✅ Información general sobre la agencia

### **Flor Escala a Humano:**
🔄 Solicitudes explícitas de hablar con humano
🔄 Intención de hacer una reserva
🔄 Consultas sobre disponibilidad específica (necesita verificar en tiempo real)
🔄 Cancelaciones de reservas existentes
🔄 Problemas o quejas
🔄 Consultas que no entiende completamente

## 📊 **Estructura de Datos que Flor Espera**

### **Formato de Hotel en localStorage:**
```javascript
{
    id: 1,
    name: "Hotel Terma de Puyehue",
    location: "Puyehue",
    address: "Ruta 215 Km 76, Puyehue, Chile",
    description: "Hotel de lujo...",
    rating: 4.8,
    amenities: ["thermal_waters", "spa", "restaurant", "gym"],
    priceRange: { min: 600, max: 1500, currency: "USD" }, // Opcional
    is_active: true
}
```

## ✅ **Verificación de Autonomía**

Para verificar que Flor tiene toda la información necesaria:

1. **Abre el chatbot** (flor-chatbot.html o widget)
2. **Haz preguntas de prueba:**
   - "¿Qué hoteles tienen?"
   - "¿Dónde está Hotel Puyehue?"
   - "¿Qué servicios tiene Huilo-Huilo?"
   - "¿Cuánto cuesta?"

3. **Verifica las respuestas** - Deben ser completas y sin escalar a humano

## 🎯 **Próximos Pasos para Mejorar Autonomía**

1. **Agregar precios específicos** a cada hotel en la base de datos
2. **Expandir descripciones de servicios** con más detalles
3. **Agregar información de temporadas** (alta/baja temporada)
4. **Incluir información de tipos de habitación** disponibles
5. **Agregar fotos o enlaces** a galerías de imágenes

---

**Flor está configurada para ser completamente autónoma con la información actual.** 
Cualquier dato nuevo que agregues a `hotelsDB` en localStorage será automáticamente accesible por Flor.

