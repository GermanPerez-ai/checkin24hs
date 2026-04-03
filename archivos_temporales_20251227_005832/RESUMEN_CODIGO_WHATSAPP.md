# 📋 Resumen de Código Relacionado con WhatsApp

## 🔍 Archivos Principales de Código

### 1. **Servidor de WhatsApp (Backend)**

#### `whatsapp-server/whatsapp-server.js`
- **Tipo:** Servidor Node.js principal
- **Funcionalidad:**
  - Servidor Express que maneja conexiones WhatsApp
  - Integración con whatsapp-web.js
  - API REST para estado, QR, mensajes
  - Integración con Supabase
  - Flor IA (asistente virtual)
  - Manejo de sesiones y autenticación
- **Puertos:** 3001-3004 o 4001-4004 (según configuración)
- **Líneas:** ~1650 líneas
- **Estado:** Código principal activo

#### `whatsapp-server/ecosystem.config.js`
- **Tipo:** Configuración PM2
- **Funcionalidad:** Configuración para 4 instancias de WhatsApp
- **Puertos:** 4001, 4002, 4003, 4004

#### `whatsapp-server/package.json`
- **Tipo:** Dependencias Node.js
- **Dependencias principales:**
  - whatsapp-web.js
  - express
  - puppeteer
  - @supabase/supabase-js

---

### 2. **Dashboard (Frontend)**

#### `dashboard.html`
- **Tipo:** Interfaz web principal
- **Funcionalidad WhatsApp:**
  - 449 referencias a WhatsApp
  - Gestión de 4 tarjetas de conexión WhatsApp
  - Visualización de códigos QR
  - Estado de conexión (conectado/desconectado)
  - Funciones: `connectWhatsApp()`, `disconnectWhatsApp()`, `updateWhatsAppCard()`
  - Integración con Supabase (`whatsapp_cards`)
  - Generación local de QR para pruebas
- **Ubicación código:** Líneas ~8750-9500 aproximadamente

#### `deploy/dashboard.html`
- **Tipo:** Versión deployada del dashboard
- **Funcionalidad:** Similar a `dashboard.html`

---

### 3. **CRM (Sistema de Gestión)**

#### `deploy/crm.js`
- **Tipo:** JavaScript del CRM
- **Funcionalidad WhatsApp:**
  - 99 referencias a WhatsApp
  - Visualización de interacciones de WhatsApp
  - Integración con mensajes y chats
  - Funciones relacionadas con Flor IA

#### `deploy/crm.html`
- **Tipo:** HTML del CRM
- **Funcionalidad:** Interfaz del CRM con sección WhatsApp

---

### 4. **Scripts de Fix/Integración**

#### `deploy/whatsapp-fix.js`
- **Tipo:** Script de corrección
- **Funcionalidad:**
  - Sobrescribe funciones de WhatsApp
  - Fix para conexiones
  - Manejo de URLs del servidor WhatsApp

#### `deploy/whatsapp-test.html`
- **Tipo:** Página de prueba
- **Funcionalidad:** Testing de conexiones WhatsApp

---

### 5. **Alternativa Baileys**

#### `whatsapp-server-baileys/whatsapp-server-baileys.js`
- **Tipo:** Servidor alternativo usando Baileys
- **Funcionalidad:** Versión alternativa más ligera (sin Puppeteer)
- **Estado:** Alternativa no activa actualmente

---

### 6. **Base de Datos (Supabase)**

#### `supabase-migrations/001_whatsapp_tables.sql`
- **Tipo:** Migración SQL
- **Tablas creadas:**
  - `whatsapp_chats` - Conversaciones
  - `whatsapp_messages` - Mensajes
  - `flor_interactions` - Interacciones con Flor IA

#### `CREAR_TABLA_WHATSAPP_CARDS.sql`
- **Tipo:** SQL para crear tabla
- **Tabla:** `whatsapp_cards` - Estado de conexiones (1-4)

---

### 7. **Scripts de Diagnóstico**

#### `DIAGNOSTICO_QR_WHATSAPP.js`
- **Tipo:** Script de diagnóstico
- **Funcionalidad:** Verificar generación de QR

#### `DIAGNOSTICO_VINCULACION_WHATSAPP.js`
- **Tipo:** Script de diagnóstico
- **Funcionalidad:** Verificar vinculación de WhatsApp

#### `LIMPIAR_ESTADO_WHATSAPP.js`
- **Tipo:** Script de limpieza
- **Funcionalidad:** Limpiar estado de conexiones

---

## 📊 Estadísticas

| Archivo | Tipo | Referencias WhatsApp | Estado |
|---------|------|---------------------|--------|
| `whatsapp-server/whatsapp-server.js` | Backend | ~200+ | ✅ Activo |
| `dashboard.html` | Frontend | 449 | ✅ Activo |
| `deploy/crm.js` | Frontend | 99 | ✅ Activo |
| `deploy/whatsapp-fix.js` | Fix | ~50 | ✅ Activo |
| `whatsapp-server-baileys/whatsapp-server-baileys.js` | Alternativa | ~100 | ⚠️ No activo |

---

## 🎯 Funcionalidades Principales Implementadas

### 1. **Gestión de Conexiones**
- ✅ 4 instancias de WhatsApp (tarjetas 1-4)
- ✅ Estado de conexión (conectado/desconectado/conectando)
- ✅ Generación y visualización de códigos QR
- ✅ Desconexión de conexiones

### 2. **Integración con Supabase**
- ✅ Tabla `whatsapp_cards` para estado
- ✅ Tabla `whatsapp_chats` para conversaciones
- ✅ Tabla `whatsapp_messages` para mensajes
- ✅ Sincronización de estado

### 3. **API REST**
- ✅ `/api/status` - Estado de conexión
- ✅ `/api/qr` - Obtener código QR
- ✅ `/api/logout` - Desconectar
- ✅ `/api/stats` - Estadísticas

### 4. **Flor IA**
- ✅ Asistente virtual integrado
- ✅ Respuestas automáticas
- ✅ Integración con Gemini AI
- ✅ Base de conocimiento de hoteles

---

## 🔧 Archivos de Configuración

- `whatsapp-server/ecosystem.config.js` - PM2
- `whatsapp-server/Dockerfile` - Docker
- `whatsapp-server/package.json` - Dependencias
- `whatsapp-server/verificar_puertos.sh` - Verificación

---

## 📝 Notas Importantes

1. **Código principal activo:**
   - `whatsapp-server/whatsapp-server.js` - Backend
   - `dashboard.html` - Frontend principal
   - `deploy/crm.js` - CRM

2. **Código alternativo (no activo):**
   - `whatsapp-server-baileys/` - Versión Baileys

3. **Scripts de utilidad:**
   - Diagnósticos, fixes, limpieza
   - ~100+ archivos de documentación/configuración

4. **Base de datos:**
   - 4 tablas principales en Supabase
   - Migraciones SQL disponibles

---

## 🗑️ Si Quieres Eliminar Código de WhatsApp

### Archivos críticos a revisar:
1. `whatsapp-server/whatsapp-server.js` - Eliminar o comentar
2. `dashboard.html` - Sección WhatsApp (líneas ~8750-9500)
3. `deploy/crm.js` - Funciones relacionadas con WhatsApp
4. `deploy/whatsapp-fix.js` - Eliminar
5. Tablas Supabase - Ejecutar SQL de eliminación

### Scripts de eliminación disponibles:
- `ELIMINAR_CONEXIONES_WHATSAPP.sh` - Elimina procesos y archivos
- `ELIMINAR_WHATSAPP_SUPABASE.sql` - Limpia base de datos




