# 🎓 Guía Completa: Cómo Entrenar a Flor

Esta guía te explica paso a paso cómo agregar información a Flor para que pueda responder mejor a las consultas de tus clientes.

---

## 📍 Paso 1: Acceder a la Configuración de Flor

1. **Abre el CRM**: Abre `crm.html` en tu navegador
2. **Ve a Configurar Flor**: 
   - En el menú lateral, haz clic en **"Configurar Flor"** (icono de configuración ⚙️)
   - O accede directamente desde: `crm.html#flor-config`

---

## 🏨 Paso 2: Entrenar a Flor con Información de Hoteles

### **2.1 Agregar Información Básica de un Hotel**

1. En la pestaña **"Base de Conocimiento"**, verás una lista de todos tus hoteles
2. Para cada hotel, encontrarás los siguientes campos:

#### **Descripción Detallada del Hotel**
```
Ejemplo para Hotel Terma de Puyehue:
"Hotel ubicado en el corazón de la región de Los Lagos, con acceso directo a termas naturales. 
Ambiente relajante y sofisticado, ideal para descanso y bienestar. Cuenta con arquitectura 
contemporánea integrada al paisaje natural, con vista a los bosques y termas."
```

#### **Dirección Completa**
```
Ejemplo:
"Ruta 215 Km 76, Puyehue, Osorno, Región de Los Lagos, Chile"
```

#### **Rango de Precios**
- **Precio Mínimo**: Precio por noche más bajo (ej: `250`)
- **Precio Máximo**: Precio por noche más alto (ej: `800`)
- **Moneda**: USD o CLP (se configura automáticamente)

#### **Tipos de Habitaciones**
```
Suite Presidencial
Habitación Doble Premium
Junior Suite
Habitación Estándar
Suite Familiar
```

---

### **2.2 Agregar Servicios del Hotel**

1. Haz clic en **"Agregar Servicio"** para cada hotel
2. Para cada servicio, completa:
   - **Nombre del Servicio**: Ej: "Spa Termal", "Restaurante Gourmet"
   - **Descripción**: Qué incluye el servicio
   - **Costo**: Si es gratuito o tiene costo adicional
   - **Incluido**: Si está incluido en el precio base o es adicional

#### **Ejemplos de Servicios:**

**Spa Termal:**
- Nombre: `Spa Termal`
- Descripción: `Acceso a termas naturales, masajes terapéuticos, sauna y baños turcos`
- Costo: `Incluido`
- Incluido: `Sí`

**Traslado Aeropuerto:**
- Nombre: `Traslado Aeropuerto`
- Descripción: `Servicio de traslado privado desde y hacia el aeropuerto`
- Costo: `$50 USD`
- Incluido: `No`

---

### **2.3 Agregar Políticas Específicas del Hotel**

Puedes agregar políticas especiales que difieren de las políticas generales de la agencia:

```json
{
  "checkin": "Desde las 14:00 horas",
  "checkout": "Hasta las 12:00 horas",
  "mascotas": "No permitidas",
  "cancelacion": "Cancelación gratuita hasta 7 días antes del check-in",
  "restricciones": "No se permiten eventos sin autorización previa"
}
```

O simplemente texto libre:
```
Check-in: Desde las 14:00 horas
Check-out: Hasta las 12:00 horas
Mascotas: No permitidas
Cancelación gratuita: 7 días antes del check-in
```

---

### **2.4 Información Adicional del Hotel**

Aquí puedes agregar información extra que Flor debe conocer:

```json
{
  "puntos_interes": [
    "Termas de Puyehue a 5 minutos",
    "Parque Nacional Puyehue a 15 minutos",
    "Volcán Osorno a 45 minutos"
  ],
  "transporte": "Aeropuerto más cercano: Osorno (45 minutos). Servicio de traslado disponible.",
  "recomendaciones": "Mejor época para visitar: Primavera y Verano. Traer traje de baño para termas.",
  "clima": "Templado lluvioso. Temperaturas promedio: 8-20°C"
}
```

O texto libre:
```
Puntos de interés cercanos:
- Termas de Puyehue (5 minutos)
- Parque Nacional Puyehue (15 minutos)
- Volcán Osorno (45 minutos)

Transporte: Aeropuerto más cercano es Osorno (45 minutos). Servicio de traslado disponible.

Recomendaciones: Mejor época para visitar es primavera y verano. Traer traje de baño.
```

---

### **2.5 Guardar la Información**

1. Después de completar todos los campos, haz clic en **"Guardar Información del Hotel"**
2. Verás un mensaje de confirmación: ✅ "Información del hotel guardada correctamente"
3. La información se guarda automáticamente y Flor la usará inmediatamente

---

## ⚙️ Paso 3: Configurar Políticas Generales de la Agencia

En la pestaña **"Políticas"**, puedes configurar las políticas generales que aplican a todos los hoteles:

### **Política de Reserva:**
- **Depósito Requerido**: Ej: `30% del total`
- **Métodos de Pago**: Ej: `Tarjeta de crédito, Transferencia bancaria, PayPal`
- **Plazo de Confirmación**: Ej: `24 horas`

### **Política de Cancelación:**
- **Cancelación Gratuita Hasta**: Ej: `72 horas antes del check-in`
- **Penalizaciones**: Ej: `50% entre 48-72 horas, 100% con menos de 48 horas`

### **Check-in / Check-out:**
- **Horario Check-in**: Ej: `Desde las 15:00 horas`
- **Horario Check-out**: Ej: `Hasta las 11:00 horas`

---

## 💬 Paso 4: Personalizar Respuestas de Flor

En la pestaña **"Respuestas Predefinidas"**, puedes personalizar cómo responde Flor:

### **No Entendido:**
```
"Disculpa, no entendí completamente tu consulta. ¿Podrías ser más específico? 
Si prefieres, puedo conectarte inmediatamente con un agente humano que te ayudará mejor."
```

### **Transferir a Humano:**
```
"Perfecto, voy a conectarte inmediatamente con uno de nuestros agentes que podrá asistirte mejor. 
Un momento por favor..."
```

### **Despedida:**
```
"¡Fue un placer ayudarte! Si necesitas algo más, no dudes en consultarme. 
¡Que tengas un excelente día!"
```

---

## 🔑 Paso 5: Configurar Palabras Clave (Intenciones)

En la pestaña **"Palabras Clave"**, puedes agregar palabras que Flor debe reconocer para entender qué quiere el usuario:

### **Consulta de Hotel:**
`hotel, hoteles, qué hoteles, catálogo, opciones, lugares, sitios`

### **Ubicación:**
`dónde, ubicación, dirección, ubicado, localización, donde queda`

### **Servicios:**
`servicios, amenidades, comodidades, qué incluye, facilidades, tiene, cuenta con`

### **Precios:**
`precio, precios, cuánto, costo, tarifa, tarifas, valor, cuanto cuesta`

### **Reserva:**
`reservar, reserva, quiero reservar, hacer reserva, confirmar, agendar`

---

## 🧪 Paso 6: Probar que Flor Aprende Correctamente

### **Pruebas Recomendadas:**

1. **Prueba de Información Básica:**
   - Pregunta: "¿Qué me puedes contar del Hotel Puyehue?"
   - Flor debería responder con la descripción que agregaste

2. **Prueba de Ubicación:**
   - Pregunta: "¿Dónde queda el Hotel Puyehue?"
   - Flor debería responder con la dirección completa

3. **Prueba de Servicios:**
   - Pregunta: "¿Qué servicios tiene el Hotel Puyehue?"
   - Flor debería listar todos los servicios que agregaste

4. **Prueba de Precios:**
   - Pregunta: "¿Cuánto cuesta el Hotel Puyehue?"
   - Flor debería responder con el rango de precios configurado

5. **Prueba de Habitaciones:**
   - Pregunta: "¿Qué tipos de habitaciones tiene el Hotel Puyehue?"
   - Flor debería listar los tipos de habitaciones configurados

---

## ✅ Checklist: ¿Está Flor Completamente Entrenada?

Marca cada ítem cuando completes:

- [ ] ✅ **Información Básica**: Descripción, dirección y rango de precios de todos los hoteles
- [ ] ✅ **Servicios**: Lista completa de servicios para cada hotel
- [ ] ✅ **Habitaciones**: Tipos de habitaciones disponibles
- [ ] ✅ **Políticas Específicas**: Políticas particulares de cada hotel (si aplican)
- [ ] ✅ **Información Adicional**: Puntos de interés, transporte, recomendaciones
- [ ] ✅ **Políticas Generales**: Políticas de reserva, cancelación, check-in/out
- [ ] ✅ **Respuestas Personalizadas**: Respuestas de Flor configuradas
- [ ] ✅ **Palabras Clave**: Intenciones reconocidas correctamente
- [ ] ✅ **Pruebas**: Flor responde correctamente a consultas de prueba

---

## 🎯 Consejos para Entrenar a Flor Efectivamente

### **1. Sé Específico y Detallado**
- Mientras más detallada sea la información, mejor podrá responder Flor
- Incluye información práctica: horarios, costos, restricciones

### **2. Usa Lenguaje Natural**
- Escribe como hablarías con un cliente
- Flor entiende mejor cuando la información está en lenguaje conversacional

### **3. Actualiza Regularmente**
- Si cambian precios, servicios o políticas, actualiza la información inmediatamente
- Flor siempre usa la información más reciente

### **4. Agrega Contexto**
- No solo nombres de servicios, sino qué incluyen y por qué son importantes
- Ej: No solo "Spa", sino "Spa Termal con acceso a aguas naturales ricas en minerales"

### **5. Testea Regularmente**
- Haz preguntas a Flor después de agregar información nueva
- Verifica que responde correctamente antes de que los clientes la usen

---

## 🆘 Solución de Problemas

### **Flor no encuentra información de un hotel:**
1. Verifica que el hotel existe en `hotelsDB` (Dashboard → Hoteles)
2. Verifica que agregaste información en la pestaña "Base de Conocimiento"
3. Verifica que hiciste clic en "Guardar Información del Hotel"

### **Flor responde con información genérica:**
1. Asegúrate de haber agregado información específica del hotel
2. Verifica que la información está guardada correctamente (revisa la consola del navegador F12)

### **Flor no reconoce ciertas palabras:**
1. Agrega esas palabras en la pestaña "Palabras Clave"
2. Agrupa palabras relacionadas en la misma intención

---

## 📚 Información Adicional

- **Base de Conocimiento Técnica**: `flor-knowledge-base.js`
- **Lógica del Agente**: `flor-agent.js`
- **Servicio de IA**: `flor-ai-service.js`

---

¡Con esta guía, Flor estará completamente entrenada y lista para atender a tus clientes! 🎉

