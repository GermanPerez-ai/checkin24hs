# 🔑 Dónde Encontrar la "anon public" Key

## 📍 Ubicación Correcta

Estás en la página de **"API de datos"**, pero la clave "anon public" está en otra sección.

### Paso 1: Ir a "Claves API" (API Keys)

En el menú lateral izquierdo, donde estás viendo:

```
CONFIGURACIÓN DEL PROYECTO
├── General
├── Computación y disco
├── Infraestructura
├── Integraciones
├── API de datos ← Estás aquí
├── Claves API ← ¡HAZ CLIC AQUÍ!
├── Claves JWT
└── ...
```

**Haz clic en "Claves API"** (está justo debajo de "API de datos")

### Paso 2: Encontrar la Clave "anon public"

Una vez en "Claves API", verás una sección que dice:

**"Project API keys"** o **"Claves API del proyecto"**

Ahí verás dos claves:

1. **anon public** ← Esta es la que necesitas
   - Es una clave muy larga
   - Empieza con `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - Tiene un botón de copiar (📋) al lado

2. **service_role** ← NO uses esta (es privada)

### Paso 3: Copiar la Clave

Haz clic en el botón **"Copiar"** (📋) que está al lado de la clave **"anon public"**

## 🎯 Resumen

1. En el menú lateral, haz clic en **"Claves API"** (está debajo de "API de datos")
2. Busca la sección **"Project API keys"**
3. Copia la clave **"anon public"** (no la "service_role")

## 📝 Lo que Necesitas

1. **Project URL**: Ya la tienes → `https://lmoeuyasuvoqhtvhkyia.supabase.co`
2. **anon public key**: Está en "Claves API" → Copia esa clave larga

¿Ya la encontraste? Si quieres, pégala aquí y la configuro por ti.

