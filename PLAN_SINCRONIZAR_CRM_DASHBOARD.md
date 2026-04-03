# Plan para Sincronizar CRM con Dashboard

## Objetivo
Hacer que todas las secciones del CRM tengan la misma estructura, funcionalidad y sincronización en tiempo real que el Dashboard.

## Secciones a Sincronizar

1. **Usuarios** (customers-section → users-section)
2. **Reservas** (reservations-section)
3. **Cotizaciones** (quotes-section)
4. **Interacciones** (interactions-section)
5. **Chats** (chats-section)
6. **Agentes** (agents-section)
7. **Flor IA** (flor-config-section)

## Componentes Necesarios

### 1. HTML Structure
- Copiar toda la estructura HTML de cada sección del Dashboard
- Incluir botones de acción, filtros, tablas, modales
- Mantener los mismos IDs y clases CSS

### 2. JavaScript Functions
- Funciones de carga de datos (`loadUsersTable`, `loadReservationsTable`, etc.)
- Funciones de sincronización en tiempo real
- Funciones de filtrado y búsqueda
- Funciones de modales y formularios

### 3. Sincronización en Tiempo Real
- `initRealtimeSubscriptions()` - Inicializar suscripciones
- `setupRealtimeSubscriptions()` - Configurar suscripciones específicas
- Suscripciones a:
  - WhatsApp Chats
  - WhatsApp Messages
  - Flor Interactions
  - Reservations
  - Users
  - Quotes
  - Agents

### 4. Funciones de Carga desde Supabase
- Todas las funciones deben cargar desde Supabase primero
- Usar localStorage como fallback
- Actualizar automáticamente cuando hay cambios en Supabase

## Estrategia de Implementación

1. **Extraer secciones del Dashboard** una por una
2. **Reemplazar secciones en CRM** manteniendo la estructura del sidebar
3. **Copiar funciones JavaScript** necesarias al archivo `crm.js` o incluir inline
4. **Verificar sincronización** en tiempo real
5. **Probar cada sección** individualmente

## Archivos a Modificar

- `deploy/crm.html` - Estructura HTML de las secciones
- `deploy/crm.js` - Funciones JavaScript (o incluir en dashboard.html si es necesario)

## Notas Importantes

- El CRM usa `customers-section` pero el Dashboard usa `users-section` - mantener compatibilidad
- Asegurar que los IDs de elementos sean únicos
- Verificar que las funciones globales estén disponibles (`window.`)
- Incluir todos los modales y formularios del Dashboard


















