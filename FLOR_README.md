# 🌸 Flor - Agente de Conversación Inteligente

## 📋 Descripción

**Flor** es un agente de conversación (chatbot) inteligente diseñado específicamente para **Checkin24hs**, una agencia de hoteles de lujo. Flor actúa como el primer punto de contacto con los clientes, proporcionando atención inmediata y eficiente las 24 horas del día.

## 🎯 Características Principales

### ✨ Personalidad y Tono
- **Amable y amigable**: Flor tiene un tono cálido y servicial
- **Profesional y eficiente**: Responde de forma directa y concisa
- **Enfoque en inmediatez**: Prioriza la velocidad de respuesta

### 🧠 Capacidades Inteligentes

1. **Consulta de Hoteles**
   - Lista de hoteles disponibles
   - Información sobre ubicaciones
   - Detalles de servicios y amenidades

2. **Información de Servicios**
   - Servicios incluidos en cada hotel
   - Servicios adicionales con costo
   - Descripciones detalladas

3. **Consultas de Precios**
   - Rangos de precios generales
   - Información sobre tarifas

4. **Gestión de Reservas**
   - Detección automática de intención de reserva
   - Escalación inmediata a agente humano

5. **Escalación Inteligente**
   - Transfiere a humano cuando es necesario
   - Detecta problemas o consultas complejas
   - Respeta solicitudes explícitas del cliente

## 📁 Estructura de Archivos

```
flor-chatbot.html          # Interfaz principal del chatbot
flor-agent.js              # Motor principal del agente
flor-knowledge-base.js     # Base de conocimiento estructurada
flor-widget.js             # Widget flotante para integración
FLOR_README.md             # Esta documentación
```

## 🚀 Instalación y Uso

### Uso Independiente

Abre directamente el archivo `flor-chatbot.html` en tu navegador para probar el chatbot de forma independiente.

### Integración como Widget

El chatbot ya está integrado en:
- `dashboard.html` - Para uso administrativo
- `index.html` - Para uso de clientes

Para integrar en otras páginas, agrega antes del cierre de `</body>`:

```html
<script src="flor-widget.js"></script>
```

El widget aparecerá automáticamente como un botón flotante en la esquina inferior derecha.

## 🔧 Configuración

### Base de Conocimiento

Edita `flor-knowledge-base.js` para:
- Actualizar información de hoteles
- Modificar políticas de la agencia
- Agregar nuevos servicios
- Personalizar respuestas

### Personalidad del Agente

En `flor-knowledge-base.js`, sección `agent`:

```javascript
agent: {
    name: "Flor",
    role: "Asistente Virtual",
    greeting: "¡Hola! Mi nombre es Flor...",
    personality: "Amable, eficiente y profesional"
}
```

### Reglas de Escalación

En `flor-agent.js`, función `shouldEscalateToHuman()`:

El agente escalará automáticamente cuando:
1. El cliente solicite explícitamente hablar con un humano
2. El cliente quiera hacer una reserva
3. El cliente tenga un problema
4. El agente no entienda la consulta

## 📊 Integración con Base de Datos

Flor se integra automáticamente con la base de datos de hoteles almacenada en `localStorage` con la clave `hotelsDB`. El formato esperado es:

```javascript
[
    {
        id: 1,
        name: "Hotel Terma de Puyehue",
        location: "Puyehue",
        address: "Ruta 215 Km 76, Puyehue, Chile",
        amenities: ["spa", "restaurant", "gym"],
        is_active: true
    }
]
```

## 🎨 Personalización del Widget

En `flor-widget.js`, ajusta `widgetConfig`:

```javascript
const widgetConfig = {
    position: 'bottom-right',  // Posición del botón
    buttonColor: 'linear-gradient(...)',
    chatHeight: '600px',
    chatWidth: '450px',
    zIndex: 9999
};
```

## 🔄 Flujo de Conversación

1. **Saludo**: Flor presenta su nombre y ofrece ayuda
2. **Consulta**: El usuario hace una pregunta
3. **Procesamiento**: Flor detecta la intención y busca información
4. **Respuesta**: Flor proporciona información relevante
5. **Seguimiento**: Flor pregunta si necesita algo más
6. **Escalación** (si aplica): Transfiere a humano cuando es necesario

## 📝 Ejemplos de Consultas

### Consulta de Hotel
- "¿Qué hoteles tienen disponibles?"
- "¿Trabajan con Hotel Puyehue?"
- "Dame información sobre Huilo-Huilo"

### Consulta de Ubicación
- "¿Dónde está el Hotel Puyehue?"
- "Ubicación de Huilo-Huilo"
- "¿Dónde queda ese hotel?"

### Consulta de Servicios
- "¿Qué servicios tiene el Hotel Puyehue?"
- "¿Tiene spa?"
- "¿Incluye desayuno?"

### Consulta de Precios
- "¿Cuánto cuesta el Hotel Puyehue?"
- "Precios del hotel"
- "¿Qué rango de precios tienen?"

## 🛡️ Seguridad y Privacidad

- **No comparte información personal** de otros clientes
- **No comparte datos financieros** internos
- **Protege la privacidad** de las reservas
- Todas las conversaciones se procesan localmente en el navegador

## 🔮 Mejoras Futuras

- Integración con WhatsApp Business API
- Integración con Facebook/Instagram Messenger
- Historial de conversaciones persistente
- Analytics y métricas de uso
- Aprendizaje automático para mejorar respuestas
- Soporte multi-idioma
- Integración con sistema de reservas en tiempo real

## 📞 Soporte

Para preguntas o problemas con Flor:
- Revisa los archivos de configuración
- Verifica la integración con la base de datos
- Consulta la consola del navegador para errores

## 📄 Licencia

Este módulo es parte del proyecto Checkin24hs y sigue la misma licencia del proyecto principal.

---

**Desarrollado para Checkin24hs** - Agencia de Hoteles de Lujo 🌟

