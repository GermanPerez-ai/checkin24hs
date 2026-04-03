# 🔑 Cómo Obtener la Clave Service Role de Supabase

## 📋 Pasos para Obtener la Clave Service Role

### Paso 1: Ir al Dashboard de Supabase

1. Ve a: https://supabase.com/dashboard
2. Inicia sesión con tu cuenta
3. Selecciona tu proyecto: `checkin24hs` (o el nombre que le diste)

### Paso 2: Ir a Settings → API

1. En el menú lateral izquierdo, busca **⚙️ Settings** (Configuración)
2. Haz clic en **Settings**
3. Luego haz clic en **API** (o "Claves API" si está en español)

### Paso 3: Encontrar la Clave Service Role

En la página de API verás dos secciones:

#### 1️⃣ Project URL
- Ya la tienes: `https://lmoeuyasuvoqhtvhkyia.supabase.co`

#### 2️⃣ Project API keys

Aquí verás **DOS claves**:

1. **anon public** (ya la tienes en `supabase-config.js`)
   - Esta es la que ya estás usando en el frontend
   - Es pública y segura para exponer

2. **service_role** ← **ESTA ES LA QUE NECESITAS**
   - Es una clave **PRIVADA**
   - **NO se debe exponer** en el frontend
   - Solo para usar en el backend
   - Tiene permisos completos (bypass RLS)

### Paso 4: Copiar la Clave Service Role

1. Busca la sección donde dice **"service_role"**
2. Haz clic en el botón **"Reveal"** o **"Mostrar"** (para ver la clave completa)
3. Haz clic en el botón **"Copiar"** (📋) que está al lado
4. **⚠️ IMPORTANTE:** Guarda esta clave en un lugar seguro, no la compartas

---

## 📝 Ejemplo Visual

```
Supabase Dashboard
│
├── Tu Proyecto (lmoeuyasuvoqhtvhkyia)
│   │
│   ├── ⚙️ Settings
│   │   │
│   │   └── API (o "Claves API")
│   │       │
│   │       ├── Project URL
│   │       │   └── https://lmoeuyasuvoqhtvhkyia.supabase.co ✅ (ya la tienes)
│   │       │
│   │       └── Project API keys
│   │           │
│   │           ├── anon public
│   │           │   └── eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... ✅ (ya la tienes)
│   │           │
│   │           └── service_role ← 🎯 ESTA ES LA QUE NECESITAS
│   │               └── eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... ❌ (copia esta)
│   │
```

---

## 🔒 Una Vez que Tengas la Clave

Agregarla al archivo `.env` del servidor:

```env
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (pega la clave aquí)
```

---

## ⚠️ Importante

### Diferencia entre las Dos Claves:

| Clave | Dónde se usa | Permisos | Seguridad |
|-------|--------------|----------|-----------|
| **anon public** | Frontend (browser) | Limitados por RLS | ✅ Puede exponerse |
| **service_role** | Backend (servidor) | Completos | ❌ **NUNCA** exponer |

### ¿Por qué necesitamos service_role en el backend?

- **Más control:** El backend puede hacer operaciones sin restricciones de RLS
- **Más seguridad:** La clave nunca se expone al cliente
- **Mejor para APIs:** Permite validaciones y lógica de negocio antes de guardar

---

## ✅ Verificar que Funciona

Una vez que agregues la clave al `.env` y reinicies el servidor, prueba:

```bash
curl http://localhost:3000/api/supabase/test
```

Deberías recibir:
```json
{
  "success": true,
  "configured": true,
  "connected": true,
  "message": "Conexión exitosa con Supabase"
}
```

---

## 🆘 ¿No encuentras la clave service_role?

1. **Verifica que estás en el proyecto correcto**
2. **Asegúrate de hacer clic en "Reveal" o "Mostrar"** - algunas veces está oculta por seguridad
3. **Si no la ves:** Puede que necesites permisos de administrador en el proyecto

---

**Una vez que tengas la clave, pégala en el `.env` del servidor y reinicia el servidor.**
