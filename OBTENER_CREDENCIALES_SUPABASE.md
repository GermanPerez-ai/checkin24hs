# 🔑 Cómo Obtener las Credenciales de Supabase

## 📍 Ubicación de las Credenciales

En el dashboard de Supabase que estás viendo:

### Paso 1: Ir a Settings (Configuración)

1. **Busca el ícono de ⚙️ (Engranaje)** en el menú lateral izquierdo
   - Está en la parte inferior del menú lateral
   - Dice "Settings" o "Configuración"

2. **Haz clic en ⚙️ Settings**

### Paso 2: Ir a API

Una vez en Settings, verás varias opciones en un submenú:

- General
- API ← **HAZ CLIC AQUÍ**
- Database
- Auth
- Storage
- etc.

### Paso 3: Copiar las Credenciales

En la página de API verás:

#### 1️⃣ Project URL
- Sección: **Project URL**
- Es una URL que se ve así: `https://xxxxxxxxxxxxx.supabase.co`
- **Acción**: Haz clic en el botón de copiar (📋) o selecciona y copia toda la URL

#### 2️⃣ Project API keys
- Sección: **Project API keys**
- Busca la clave que dice **"anon public"** o **"anon"**
- Es una clave muy larga que empieza con `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- **Acción**: Haz clic en el botón de copiar (📋) o selecciona y copia toda la clave

### ⚠️ Importante

- ✅ Usa la clave **"anon public"** (la clave pública)
- ❌ NO uses la clave **"service_role"** (es privada y no debe usarse en el frontend)

## 📝 Resumen Visual

```
Supabase Dashboard
│
├── Menú Lateral (Izquierda)
│   └── ⚙️ Settings (abajo del menú)
│       └── API
│           ├── Project URL ← Copia esto
│           └── Project API keys
│               └── anon public ← Copia esto
```

## 🎯 Siguiente Paso

Una vez que tengas las credenciales:
1. Ábrelas en `supabase-config.js` (que ya tienes abierto)
2. Reemplaza los valores `TU_SUPABASE_URL_AQUI` y `TU_SUPABASE_ANON_KEY_AQUI`
3. Guarda el archivo

¿Ya las tienes? ¡Perfecto! Pégamelas aquí y las configuro por ti, o puedes hacerlo tú mismo en el archivo `supabase-config.js`.

