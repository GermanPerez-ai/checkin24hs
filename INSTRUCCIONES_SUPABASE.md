# 🚀 Instrucciones de Configuración de Supabase

## Paso 1: Crear cuenta y proyecto en Supabase

1. **Ve a Supabase**
   - Abre tu navegador y ve a: https://supabase.com
   - Haz clic en **"Start your project"** o **"Sign up"**

2. **Inicia sesión**
   - Opción recomendada: Haz clic en **"Continue with GitHub"**
   - O usa email/Google según prefieras

3. **Crear nuevo proyecto**
   - Haz clic en **"New Project"**
   - Completa el formulario:
     - **Organization**: Crea una nueva o selecciona una existente
     - **Name**: `checkin24hs` (o el nombre que prefieras)
     - **Database Password**: ⚠️ **GUARDA ESTA CONTRASEÑA** - la necesitarás después
     - **Region**: Selecciona la más cercana:
       - **South America (São Paulo)** - Recomendado para Chile
       - O la región que prefieras
     - **Pricing Plan**: **Free** (plan gratuito)

4. **Esperar la creación**
   - El proyecto tarda 1-2 minutos en crearse
   - Verás una pantalla de "Setting up your project..."

## Paso 2: Obtener las credenciales de API

1. **Ir a Settings**
   - Una vez creado el proyecto, en el menú lateral izquierdo
   - Haz clic en el ícono de **⚙️ Settings** (configuración)
   - Luego en **API**

2. **Copiar las credenciales**
   - Verás dos secciones:
     - **Project URL**: Copia esta URL
       - Ejemplo: `https://xxxxxxxxxxxxx.supabase.co`
     - **Project API keys**: 
       - **anon public**: Copia esta clave (es la que usarás)
         - Ejemplo: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## Paso 3: Configurar el archivo supabase-config.js

1. **Abrir el archivo**
   - Abre `supabase-config.js` en tu editor

2. **Reemplazar las credenciales**
   ```javascript
   const SUPABASE_CONFIG = {
       url: 'https://TU_PROYECTO.supabase.co',  // ← Pega tu Project URL aquí
       anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'  // ← Pega tu anon key aquí
   };
   ```

3. **Guardar el archivo**
   - Guarda los cambios

## Paso 4: Crear las tablas en Supabase

1. **Ir al SQL Editor**
   - En el menú lateral izquierdo de Supabase
   - Haz clic en **SQL Editor**

2. **Crear nueva consulta**
   - Haz clic en **"New query"**
   - Copia y pega el SQL del archivo `create-tables.sql`
   - O copia el SQL que te proporcionaré a continuación

3. **Ejecutar el SQL**
   - Haz clic en **"Run"** o presiona `Ctrl+Enter`
   - Deberías ver un mensaje de éxito

## Paso 5: Verificar la instalación

1. **Abrir el dashboard**
   - Abre `dashboard.html` en tu navegador
   - Abre la consola (F12)

2. **Verificar conexión**
   - Deberías ver: `✅ Cliente de Supabase inicializado correctamente`
   - Si ves un error, revisa las credenciales en `supabase-config.js`

## ✅ ¡Listo!

Una vez completados estos pasos, tu dashboard estará conectado a Supabase y todos los datos se guardarán en la nube.

---

## 🔍 Solución de Problemas

### Error: "Supabase no está inicializado"
- **Solución**: Verifica que `supabase-config.js` tenga las credenciales correctas
- Verifica que el script de Supabase esté cargado antes de `supabase-client.js`

### Error: "relation does not exist"
- **Solución**: Asegúrate de haber ejecutado el SQL para crear las tablas
- Ve a **Table Editor** en Supabase para verificar que las tablas existan

### Error: "Invalid API key"
- **Solución**: Verifica que copiaste la clave correcta (anon key, no service_role)
- Asegúrate de no tener espacios extra al copiar

### Los datos no se guardan
- **Solución**: Abre la consola del navegador (F12) para ver errores
- Verifica que Supabase esté inicializado correctamente
- Si hay problemas, los datos se guardarán en localStorage como respaldo

---

## 📞 Soporte

Si tienes problemas:
1. Revisa la consola del navegador (F12) para ver errores
2. Verifica que todas las credenciales estén correctas
3. Asegúrate de haber creado las tablas en Supabase

