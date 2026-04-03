# Solución Definitiva: app is not defined

## Problema
Algunos contenedores tienen el archivo correcto y otros no. Esto causa que algunos funcionen y otros fallen.

## Solución: Verificar y Corregir en GitHub

### Paso 1: Verificar el archivo en GitHub

1. Ve a: `https://github.com/GermanPerez-ai/checkin24hs/blob/main/serve-crm.js`
2. Verifica que las **primeras 3 líneas** sean exactamente:

```javascript
const express = require('express');
const path = require('path');
const app = express();
```

**IMPORTANTE**: La línea 3 `const app = express();` DEBE estar presente.

### Paso 2: Si falta, reemplazar completamente

Si la línea 3 falta, reemplaza TODO el archivo con este contenido:

```javascript
const express = require('express');
const path = require('path');
const app = express();
// Forzar puerto 3005 para evitar conflicto con webmail (puerto 80)
// Si EasyPanel pasa PORT=80, lo cambiamos a 3005
const ENV_PORT = process.env.PORT || 3005;
const PORT = ENV_PORT === 80 || ENV_PORT === '80' ? 3005 : ENV_PORT;

// Prevenir caché para crm.html y archivos principales
app.use((req, res, next) => {
    if (req.path === '/' || req.path === '/crm.html' || req.path.endsWith('.html')) {
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
    }
    next();
});

// Servir crm.html como página principal
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'crm.html'));
});

// Redirigir index.html a crm.html
app.get('/index.html', (req, res) => {
    res.redirect('/crm.html');
});

// Servir archivos estáticos desde la raíz del proyecto
app.use(express.static(__dirname, { index: false }));

// También servir crm.html directamente
app.get('/crm.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'crm.html'));
});

// Manejar rutas de React Router (si es necesario en el futuro)
app.get('*', (req, res) => {
    // Si la ruta no es un archivo estático, servir crm.html
    res.sendFile(path.join(__dirname, 'crm.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`CRM corriendo en http://0.0.0.0:${PORT}`);
    console.log(`Sirviendo archivos desde: ${__dirname}`);
});
```

### Paso 3: Forzar Reconstrucción Completa

1. Ve a EasyPanel → Servicio `crm`
2. Haz click en "Rebuild" o "Reconstruir"
3. **O mejor aún**: Elimina el servicio y créalo de nuevo para asegurar una construcción limpia
4. Espera 3-5 minutos

### Paso 4: Verificar

```bash
# Ver logs
docker service logs checkin24hs_crm --tail 30

# Deberías ver SOLO: "CRM corriendo en http://0.0.0.0:3005"
# NO deberías ver errores de "app is not defined"
```

## Nota sobre Acceso

**NO intentes acceder a `0.0.0.0:3005` desde el navegador**. `0.0.0.0` es solo para que el servidor escuche en todas las interfaces.

**Para acceder al CRM:**
- Usa el dominio: `http://crm.checkin24hs.com` (después de configurar DNS)
- O usa la IP del servidor: `http://[IP_DEL_SERVIDOR]:[PUERTO_EXTERNO]`

## Verificar Archivo en Contenedor

Para ver qué hay realmente en el contenedor:

```bash
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID head -10 /app/serve-crm.js
```

Deberías ver las primeras 3 líneas con `const app = express();` presente.






