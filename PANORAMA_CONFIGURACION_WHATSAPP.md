# 📱 Panorama Completo: Configuración de WhatsApp

## 🎯 Resumen Ejecutivo

La configuración de WhatsApp está organizada en **DOS niveles principales**:

1. **Backend (Servidor)**: 4 servicios independientes que corren en el servidor
2. **Frontend (Dashboard)**: Interfaz web para conectar y gestionar los números de WhatsApp

---

## 🏗️ Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                    DASHBOARD (Frontend)                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Sección: Flor IA → Pestaña: WhatsApp                 │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │  │
│  │  │ WhatsApp │ │ WhatsApp │ │ WhatsApp │ │ WhatsApp │ │  │
│  │  │    1     │ │    2     │ │    3     │ │    4     │ │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ │  │
│  │     ↓            ↓            ↓            ↓           │  │
│  │  Conectar    Conectar     Conectar    Conectar        │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          ↓ HTTP Requests
┌─────────────────────────────────────────────────────────────┐
│                    SERVIDOR (Backend)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │ Servicio │ │ Servicio │ │ Servicio │ │ Servicio │     │
│  │whatsapp  │ │whatsapp2 │ │whatsapp3 │ │whatsapp4 │     │
│  │ Puerto   │ │ Puerto   │ │ Puerto   │ │ Puerto   │     │
│  │  3001    │ │  3002    │ │  3003    │ │  3004    │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
│     ↓            ↓            ↓            ↓               │
│  whatsapp-server.js (mismo código, diferentes instancias)   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Nivel 1: Backend (Servidor) - EasyPanel

### 🎯 ¿Qué es?

Son **4 servicios independientes** que corren en el servidor. Cada uno maneja una conexión de WhatsApp diferente.

### 📁 Archivos Involucrados

- **`whatsapp-server/whatsapp-server.js`**: Código del servidor (compartido por los 4 servicios)
- **EasyPanel**: Configuración de los 4 servicios

### ⚙️ Configuración de Cada Servicio

Cada servicio necesita estas **variables de entorno**:

```bash
INSTANCE_NUMBER=1        # 1, 2, 3 o 4 (según el servicio)
PORT=3001               # 3001, 3002, 3003 o 3004
SUPABASE_URL=...        # URL de tu proyecto Supabase
SUPABASE_ANON_KEY=...   # Clave anónima de Supabase
GEMINI_API_KEY=...      # (Opcional) Para respuestas con IA
```

### 📊 Tabla de Servicios

| Servicio | INSTANCE_NUMBER | PORT | Puerto Interno | Estado Esperado |
|----------|----------------|------|----------------|-----------------|
| `whatsapp` | 1 | 3001 | 3001 | ✅ Verde (Running) |
| `whatsapp2` | 2 | 3002 | 3002 | ✅ Verde (Running) |
| `whatsapp3` | 3 | 3003 | 3003 | ✅ Verde (Running) |
| `whatsapp4` | 4 | 3004 | 3004 | ✅ Verde (Running) |

### 🔧 Comando de Inicio

Todos los servicios usan el mismo comando:
```bash
node whatsapp-server.js
```

### 📍 Ubicación del Código

- **Ruta en servidor**: `/root/checkin24hs/whatsapp-server/whatsapp-server.js`
- **Ruta local**: `whatsapp-server/whatsapp-server.js`

---

## 🖥️ Nivel 2: Frontend (Dashboard) - Interfaz Web

### 🎯 ¿Qué es?

La interfaz web donde conectas los números de WhatsApp escaneando códigos QR.

### 📍 Ubicación en el Dashboard

1. **Menú lateral** → **"Flor IA"**
2. **Pestaña** → **"📱 WhatsApp"** (verde)
3. **Sección**: "Conectar Múltiples WhatsApp con IA"

### 🎨 Estructura Visual

```
┌─────────────────────────────────────────────────────────┐
│  📱 Conectar Múltiples WhatsApp con IA                  │
│                                                          │
│  💡 Con IA Integrada: Cada número conectado utilizará  │
│     Flor IA para responder automáticamente...          │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │  WhatsApp 1  │  │  WhatsApp 2  │                    │
│  │              │  │              │                    │
│  │ Estado: ...  │  │ Estado: ...  │                    │
│  │ Número: -    │  │ Número: -    │                    │
│  │ Nombre: -    │  │ Nombre: -    │                    │
│  │              │  │              │                    │
│  │ [Conectar]   │  │ [Conectar]   │                    │
│  │ [Actualizar] │  │ [Actualizar] │                    │
│  └──────────────┘  └──────────────┘                    │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │  WhatsApp 3  │  │  WhatsApp 4  │                    │
│  │              │  │              │                    │
│  │ Estado: ...  │  │ Estado: ...  │                    │
│  │ Número: -    │  │ Número: -    │                    │
│  │ Nombre: -    │  │ Nombre: -    │                    │
│  │              │  │              │                    │
│  │ [Conectar]   │  │ [Conectar]   │                    │
│  │ [Actualizar] │  │ [Actualizar] │                    │
│  └──────────────┘  └──────────────┘                    │
└─────────────────────────────────────────────────────────┐
```

### 📁 Archivos Involucrados

- **`deploy/dashboard.html`**:
  - Líneas **3640-3863**: HTML de la pestaña WhatsApp (4 tarjetas)
  - Líneas **9018-9400**: Funciones JavaScript para WhatsApp
  - Líneas **21652-21696**: Función `showFlorTab()` que carga la pestaña

### 🔧 Funciones JavaScript Principales

#### 1. `loadWhatsAppCards()` (línea 9018)
- **Qué hace**: Carga el estado de las 4 tarjetas desde Supabase
- **Cuándo se ejecuta**: Al abrir la pestaña WhatsApp
- **Datos que lee**: Tabla `whatsapp_cards` en Supabase

#### 2. `updateWhatsAppCard(cardNumber, data)` (línea 9050)
- **Qué hace**: Actualiza visualmente una tarjeta con los datos recibidos
- **Parámetros**: 
  - `cardNumber`: 1, 2, 3 o 4
  - `data`: Objeto con estado, número, nombre, QR, etc.

#### 3. `connectWhatsApp(cardNumber)` (línea 9113)
- **Qué hace**: Inicia el proceso de conexión de un WhatsApp
- **Proceso**:
  1. Obtiene la URL del servidor desde localStorage
  2. Hace una petición HTTP a `{URL}:{PUERTO}/api/qr`
  3. Genera el código QR localmente
  4. Muestra el QR en la tarjeta
  5. Inicia polling para verificar el estado

#### 4. `generateLocalQR(cardNumber)` (línea 9174)
- **Qué hace**: Genera el código QR visualmente en la tarjeta
- **Librería usada**: `qrcode.js` (incluida en el HTML)

#### 5. `checkWhatsAppConnectionStatus(cardNumber)` (línea 9292)
- **Qué hace**: Verifica periódicamente el estado de la conexión
- **Frecuencia**: Cada 3 segundos mientras está conectando
- **Endpoints que consulta**:
  - `{URL}:{PUERTO}/api/status`
  - `{URL}:{PUERTO}/api/qr`

#### 6. `disconnectWhatsApp(cardNumber)` (línea 9344)
- **Qué hace**: Desconecta un WhatsApp
- **Endpoint**: `{URL}:{PUERTO}/api/disconnect`

#### 7. `updateWhatsApp(cardNumber)` (línea 3707, 3757, etc.)
- **Qué hace**: Actualiza manualmente el estado de una tarjeta
- **Acción**: Llama a `loadWhatsAppCards()` y luego `updateWhatsAppCard()`

### 🔗 Endpoints del Backend que Usa el Frontend

Cada tarjeta se conecta a un puerto diferente:

| Tarjeta | Puerto | Endpoints Usados |
|---------|--------|------------------|
| WhatsApp 1 | 3001 | `http://{URL}:3001/api/qr`, `/api/status`, `/api/disconnect` |
| WhatsApp 2 | 3002 | `http://{URL}:3002/api/qr`, `/api/status`, `/api/disconnect` |
| WhatsApp 3 | 3003 | `http://{URL}:3003/api/qr`, `/api/status`, `/api/disconnect` |
| WhatsApp 4 | 3004 | `http://{URL}:3004/api/qr`, `/api/status`, `/api/disconnect` |

### 💾 Almacenamiento de Datos

#### En el Frontend (localStorage)
- **`whatsapp_server_url`**: URL base del servidor (ej: `http://72.61.58.240`)
- **`whatsapp_cards`**: Estado local de las tarjetas (caché)

#### En el Backend (Supabase)
- **Tabla `whatsapp_cards`**: Estado persistente de cada conexión
  - Campos: `instance_number`, `status`, `phone`, `name`, `qr_code`, etc.

---

## 🔄 Flujo de Conexión Completo

### Paso 1: Configurar Backend (EasyPanel)
```
1. Crear servicio "whatsapp" en EasyPanel
2. Configurar variables de entorno:
   - INSTANCE_NUMBER=1
   - PORT=3001
   - SUPABASE_URL=...
   - SUPABASE_ANON_KEY=...
3. Configurar puerto interno: 3001
4. Configurar comando: node whatsapp-server.js
5. Guardar y verificar que esté en verde (Running)
6. Repetir para whatsapp2, whatsapp3, whatsapp4 (puertos 3002, 3003, 3004)
```

### Paso 2: Configurar Frontend (Dashboard)
```
1. Abrir Dashboard → Flor IA → WhatsApp
2. Configurar URL del servidor (si no está configurada):
   - Campo: "URL del Servidor WhatsApp"
   - Valor: http://72.61.58.240 (o tu IP/servidor)
3. Guardar configuración
```

### Paso 3: Conectar WhatsApp
```
1. Hacer clic en "Conectar" en la tarjeta WhatsApp 1
2. El sistema:
   - Hace petición a http://{URL}:3001/api/qr
   - Recibe el código QR del servidor
   - Genera el QR visualmente en la tarjeta
   - Inicia polling cada 3 segundos
3. Escanear el QR con WhatsApp desde el teléfono
4. El sistema detecta la conexión automáticamente
5. La tarjeta muestra: "Conectado" (verde) + número + nombre
```

---

## 🗄️ Base de Datos (Supabase)

### Tabla: `whatsapp_cards`

Estructura esperada:
```sql
CREATE TABLE whatsapp_cards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  instance_number INTEGER NOT NULL UNIQUE, -- 1, 2, 3 o 4
  status TEXT, -- 'disconnected', 'connecting', 'connected'
  phone TEXT,
  name TEXT,
  qr_code TEXT,
  last_update TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Sincronización

- **Backend → Supabase**: El servidor actualiza la tabla cuando cambia el estado
- **Frontend → Supabase**: El dashboard lee la tabla para mostrar el estado actual

---

## ⚠️ Problemas Comunes y Soluciones

### ❌ Problema 1: "No se puede conectar al servidor"
**Causa**: URL incorrecta o servicio no corriendo
**Solución**:
1. Verificar que el servicio esté en verde en EasyPanel
2. Verificar la URL en el dashboard (debe ser `http://72.61.58.240` o tu IP)
3. Verificar que el puerto esté accesible desde internet

### ❌ Problema 2: "QR no aparece"
**Causa**: Error al generar QR en el servidor
**Solución**:
1. Revisar logs del servicio en EasyPanel
2. Verificar que Chromium esté instalado en el contenedor
3. Verificar variables de entorno (SUPABASE_URL, etc.)

### ❌ Problema 3: "Estado no se actualiza"
**Causa**: Polling no funciona o servicio no responde
**Solución**:
1. Hacer clic en "Actualizar" manualmente
2. Verificar que el endpoint `/api/status` responda correctamente
3. Revisar consola del navegador para errores

### ❌ Problema 4: "WhatsApp se desconecta solo"
**Causa**: Sesión expirada o servicio reiniciado
**Solución**:
1. Verificar que el servicio no se reinicie constantemente
2. Verificar logs del servicio
3. Reconectar manualmente

---

## 📝 Checklist de Configuración

### Backend (EasyPanel)
- [ ] Servicio `whatsapp` creado y corriendo (puerto 3001)
- [ ] Servicio `whatsapp2` creado y corriendo (puerto 3002)
- [ ] Servicio `whatsapp3` creado y corriendo (puerto 3003)
- [ ] Servicio `whatsapp4` creado y corriendo (puerto 3004)
- [ ] Variables de entorno configuradas en cada servicio
- [ ] Archivo `whatsapp-server.js` existe en el servidor
- [ ] Todos los servicios están en verde (Running)

### Frontend (Dashboard)
- [ ] URL del servidor configurada en el dashboard
- [ ] Pestaña WhatsApp visible y accesible
- [ ] Las 4 tarjetas se muestran correctamente
- [ ] Botones "Conectar" y "Actualizar" funcionan

### Base de Datos (Supabase)
- [ ] Tabla `whatsapp_cards` existe
- [ ] Permisos RLS configurados correctamente
- [ ] El backend puede escribir en la tabla
- [ ] El frontend puede leer la tabla

---

## 🎯 Resumen Final

**La configuración de WhatsApp tiene DOS partes:**

1. **Backend (Servidor)**: 4 servicios independientes que manejan las conexiones reales de WhatsApp
2. **Frontend (Dashboard)**: Interfaz web para gestionar y conectar los números

**El flujo es:**
1. Configuras los servicios en EasyPanel
2. Abres el dashboard y configuras la URL del servidor
3. Haces clic en "Conectar" en cada tarjeta
4. Escaneas el QR con WhatsApp
5. El sistema detecta la conexión automáticamente

**Los datos se sincronizan** entre el backend (servidor) y el frontend (dashboard) a través de Supabase.










