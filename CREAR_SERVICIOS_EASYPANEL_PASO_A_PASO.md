# 🚀 Crear Servicios WhatsApp en EasyPanel - Paso a Paso

## 🎯 Tipo de Servicio

**Usa: "Aplicación"** (Application) - Es el tipo que ves en la pantalla.

---

## 📋 Servicio 1: `whatsapp` (Puerto 3001)

### Paso 1: Crear el Servicio

1. En la pantalla de "Servicios", haz clic en **"Aplicación"** (Application)
2. Se abrirá un formulario de creación

### Paso 2: Configurar Source (Fuente)

1. **Source Type**: Selecciona **"GitHub"**
2. **Owner/Propietario**: `GermanPerez-ai`
3. **Repository/Repositorio**: `checkin24hs`
4. **Branch/Rama**: `main`
5. **Build Path/Ruta de compilación**: `/whatsapp-server` ⚠️ **IMPORTANTE**: Con barra inicial, sin barra final

### Paso 3: Configurar Variables de Entorno

Ve a la sección **"Environment Variables"** o **"Variables de Entorno"** y agrega:

```
INSTANCE_NUMBER=1
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

### Paso 4: Configurar Puerto

En la sección **"Ports"** o **"Puertos"**:

- **Protocolo**: `TCP`
- **Publicado/Published**: `3001`
- **Destino/Target**: `3001`

### Paso 5: Configurar Comando de Inicio

En la sección **"Start Command"** o **"Comando de Inicio"**:

```
node whatsapp-server.js
```

### Paso 6: Configurar Auto-Deploy (Opcional pero Recomendado)

- ✅ **Habilitar Auto-Deploy**
- **Branch/Rama**: `main`

### Paso 7: Guardar y Crear

1. Haz clic en **"Create"** o **"Crear"**
2. Espera a que se despliegue (puede tomar 2-5 minutos)
3. Verifica que el servicio esté en **VERDE** (Running)

---

## 📋 Servicio 2: `whatsapp2` (Puerto 3002)

**Repite los mismos pasos**, pero con estos cambios:

### Cambios para whatsapp2:

- **Nombre del servicio**: `whatsapp2`
- **INSTANCE_NUMBER**: `2` (en lugar de 1)
- **PORT**: `3002` (en lugar de 3001)
- **Puerto Publicado**: `3002`
- **Puerto Destino**: `3002`

**Todo lo demás es igual** (mismo GitHub, mismas variables de Supabase, mismo comando).

---

## 📋 Servicio 3: `whatsapp3` (Puerto 3003)

**Repite los mismos pasos**, pero con estos cambios:

### Cambios para whatsapp3:

- **Nombre del servicio**: `whatsapp3`
- **INSTANCE_NUMBER**: `3`
- **PORT**: `3003`
- **Puerto Publicado**: `3003`
- **Puerto Destino**: `3003`

---

## 📋 Servicio 4: `whatsapp4` (Puerto 3004)

**Repite los mismos pasos**, pero con estos cambios:

### Cambios para whatsapp4:

- **Nombre del servicio**: `whatsapp4`
- **INSTANCE_NUMBER**: `4`
- **PORT**: `3004`
- **Puerto Publicado**: `3004`
- **Puerto Destino**: `3004`

---

## ✅ Resumen Rápido

| Servicio | INSTANCE_NUMBER | PORT | Puerto Publicado | Puerto Destino |
|----------|----------------|------|------------------|----------------|
| whatsapp | 1 | 3001 | 3001 | 3001 |
| whatsapp2 | 2 | 3002 | 3002 | 3002 |
| whatsapp3 | 3 | 3003 | 3003 | 3003 |
| whatsapp4 | 4 | 3004 | 3004 | 3004 |

**Todo lo demás es IDÉNTICO** para los 4 servicios:
- ✅ Mismo GitHub: `GermanPerez-ai/checkin24hs`
- ✅ Misma rama: `main`
- ✅ Misma ruta: `/whatsapp-server`
- ✅ Mismas variables de Supabase
- ✅ Mismo comando: `node whatsapp-server.js`

---

## 🔍 Verificar que Funciona

Después de crear cada servicio:

1. **Verifica que esté en VERDE** (Running)
2. **Revisa los logs** - Deberías ver:
   ```
   WhatsApp server iniciado en puerto 3001
   ```
   (o 3002, 3003, 3004 según el servicio)

---

## 🌐 Después de Crear los Servicios: Configurar HTTPS

Una vez que los 4 servicios estén creados y funcionando:

1. **Haz clic en cada servicio**
2. **Ve a "Dominios"** o **"Domains"**
3. **Agrega dominio**:
   - `whatsapp` → `api1.checkin24hs.com`, Puerto: `3001`, SSL: ✅
   - `whatsapp2` → `api2.checkin24hs.com`, Puerto: `3002`, SSL: ✅
   - `whatsapp3` → `api3.checkin24hs.com`, Puerto: `3003`, SSL: ✅
   - `whatsapp4` → `api4.checkin24hs.com`, Puerto: `3004`, SSL: ✅

---

## ❓ ¿Necesitas Ayuda?

Si tienes dudas en algún paso, avísame y te guío específicamente.

**¿Empezamos con el primer servicio (`whatsapp`)?**









