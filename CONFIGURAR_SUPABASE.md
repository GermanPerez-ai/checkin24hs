# 🚀 Guía Rápida: Configurar Supabase

## ✅ Paso 1: Obtener Credenciales

1. **En Supabase**, ve a tu proyecto
2. En el menú lateral izquierdo, haz clic en **⚙️ Settings** (Configuración)
3. Luego haz clic en **API** (en el submenú)

Verás dos secciones importantes:

### 📋 Project URL
Copia la URL que dice **Project URL**
- Ejemplo: `https://xxxxxxxxxxxxx.supabase.co`
- Esta es tu URL única

### 🔑 Project API keys
En la sección **Project API keys**, copia la clave **anon public** (la clave pública)
- Ejemplo: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhz...`
- ⚠️ NO uses la clave "service_role" (es privada)

## ✅ Paso 2: Configurar supabase-config.js

Una vez que tengas las credenciales, te ayudo a configurarlas en el archivo.

## ✅ Paso 3: Crear las Tablas

Después de configurar, crearemos las tablas en Supabase usando el SQL que ya preparé.

---

## 📝 Instrucciones Detalladas

### ¿Dónde encontrar las credenciales?

```
Supabase Dashboard
├── Tu Proyecto (checkin24hs)
│   ├── Settings (⚙️)
│   │   ├── API
│   │   │   ├── Project URL ← Copia esto
│   │   │   └── Project API keys
│   │   │       └── anon public ← Copia esto
```

### ¿Qué son estas credenciales?

- **Project URL**: Es la dirección de tu base de datos en la nube
- **anon public key**: Es una clave pública segura para usar en el frontend (no es secreta)

### ⚠️ Importante

- Estas credenciales son **seguras** para usar en el frontend
- La clave "anon" es pública y está diseñada para eso
- NO compartas la clave "service_role" (privada)

