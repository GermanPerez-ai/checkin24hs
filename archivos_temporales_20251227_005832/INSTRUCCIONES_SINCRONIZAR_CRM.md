# Instrucciones para Sincronizar CRM con Dashboard

## Estado Actual

✅ **Sección de Usuarios**: Actualizada con estructura del Dashboard

## Pendiente

Las siguientes secciones necesitan ser copiadas del Dashboard al CRM:

1. **Reservas** - Copiar desde línea 1799 del dashboard.html
2. **Cotizaciones** - Copiar desde línea 3493 del dashboard.html  
3. **Interacciones** - Copiar desde línea 2716 del dashboard.html
4. **Chats** - Copiar desde línea 2826 del dashboard.html
5. **Agentes** - Copiar desde línea 2639 del dashboard.html
6. **Flor IA** - Copiar desde línea 2873 del dashboard.html

## Funciones JavaScript Necesarias

Todas las funciones del Dashboard deben estar disponibles en el CRM. Las funciones principales son:

- `loadUsersTable()` - Cargar tabla de usuarios
- `loadReservationsTable()` - Cargar tabla de reservas
- `loadQuotesTable()` - Cargar tabla de cotizaciones
- `loadInteractions()` - Cargar interacciones
- `loadChats()` - Cargar chats
- `loadAgentsTable()` - Cargar tabla de agentes
- `initRealtimeSubscriptions()` - Inicializar sincronización en tiempo real
- `setupRealtimeSubscriptions()` - Configurar suscripciones específicas

## Sincronización en Tiempo Real

El CRM debe tener las mismas suscripciones en tiempo real que el Dashboard:

```javascript
// Suscripciones necesarias:
- WhatsApp Chats
- WhatsApp Messages  
- Flor Interactions
- Reservations (si está disponible)
- Users (si está disponible)
- Quotes (si está disponible)
```

## Próximos Pasos

1. Copiar cada sección HTML del Dashboard al CRM
2. Asegurar que los IDs coincidan o adaptarlos
3. Incluir todas las funciones JavaScript necesarias
4. Verificar que la sincronización en tiempo real funcione
5. Probar cada sección individualmente

## Nota Importante

El Dashboard tiene más de 23,000 líneas de código. La mejor estrategia es:
1. Extraer cada sección específica
2. Copiarla al CRM manteniendo la estructura
3. Asegurar que las funciones JavaScript estén disponibles globalmente






