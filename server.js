const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { getRealPuyehueQuote } = require('./puppeteer-real-cotizacion.js');

// Cargar variables de entorno desde .env
require('dotenv').config();

// Auto-instalar @supabase/supabase-js si no está disponible
try {
    require.resolve('@supabase/supabase-js');
} catch (e) {
    console.log('📦 @supabase/supabase-js no encontrado. Intentando instalar...');
    const { execSync } = require('child_process');
    try {
        execSync('npm install @supabase/supabase-js --silent --no-save', { 
            stdio: 'inherit',
            timeout: 30000,
            cwd: '/app'
        });
        console.log('✅ @supabase/supabase-js instalado automáticamente');
        // Limpiar caché de módulos y reintentar
        Object.keys(require.cache).forEach(key => {
            if (key.includes('supabase')) delete require.cache[key];
        });
    } catch (installError) {
        console.warn('⚠️ No se pudo instalar @supabase/supabase-js automáticamente:', installError.message);
        console.warn('⚠️ Los endpoints de Supabase no estarán disponibles.');
    }
}



// Intentar cargar Supabase (puede no estar instalado)
let supabase = null;
try {
    const { createClient } = require('@supabase/supabase-js');
    const SUPABASE_URL = process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co';
    const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || '';
    
    if (SUPABASE_SERVICE_KEY) {
        supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
            auth: {
                autoRefreshToken: false,
                persistSession: false
            }
        });
        console.log('✅ Cliente de Supabase inicializado en el servidor');
    } else {
        console.warn('⚠️ SUPABASE_SERVICE_KEY no configurada. Endpoints de Supabase deshabilitados.');
    }
} catch (error) {
    console.warn('⚠️ @supabase/supabase-js no está instalado. Instala con: npm install @supabase/supabase-js');
    console.warn('⚠️ Endpoints de Supabase deshabilitados.');
}

// Variables de configuración de Gemini (desde .env)
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-3.1-flash-lite-preview';


// Función helper para inicializar Supabase si no está disponible (carga tardía)
function initializeSupabaseIfAvailable() {
    console.log('🔍 initializeSupabaseIfAvailable() llamada. supabase actual:', !!supabase);
    
    if (!supabase) {
        try {
            console.log('🔍 Intentando cargar @supabase/supabase-js...');
            // Limpiar completamente el caché de módulos relacionados con supabase
            Object.keys(require.cache).forEach(key => {
                if (key.includes('supabase') || key.includes('node_modules/@supabase')) {
                    delete require.cache[key];
                }
            });
            
            // Intentar verificar si el módulo está disponible ahora
            const modulePath = require.resolve('@supabase/supabase-js');
            console.log('✅ require.resolve exitoso. Path:', modulePath);
            delete require.cache[modulePath]; // Limpiar caché del módulo específico
            
            const { createClient } = require('@supabase/supabase-js');
            const SUPABASE_URL = process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co';
            const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || '';
            
            console.log('🔑 SUPABASE_SERVICE_KEY configurada:', !!SUPABASE_SERVICE_KEY);
            
            if (SUPABASE_SERVICE_KEY) {
                supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
                    auth: {
                        autoRefreshToken: false,
                        persistSession: false
                    }
                });
                console.log('✅ Cliente de Supabase inicializado (helper function - carga tardía exitosa)');
                return true;
            } else {
                console.warn('⚠️ SUPABASE_SERVICE_KEY no configurada en helper function');
                return false;
            }
        } catch (e) {
            console.log('⚠️ require.resolve falló:', e.message);
            console.log('🔍 Intentando carga desde path físico...');
            
            // Módulo no disponible aún - pero intentar verificar si se instaló recientemente
            const fs2 = require('fs');
            const path2 = require('path');
            const modulePath = path2.join(__dirname, 'node_modules', '@supabase', 'supabase-js');
            
            console.log('🔍 Verificando existencia en:', modulePath);
            
            if (fs2.existsSync(modulePath)) {
                console.log('✅ Módulo existe físicamente, intentando carga forzada...');
                // El módulo existe físicamente, intentar cargar forzando
                try {
                    // Limpiar todos los caches
                    Object.keys(require.cache).forEach(key => delete require.cache[key]);
                    
                    // Cargar directamente desde el path
                    const mainModulePath = path2.join(modulePath, 'dist', 'main', 'index.js');
                    const altModulePath = path2.join(modulePath, 'index.js');
                    
                    let loadedModule;
                    if (fs2.existsSync(mainModulePath)) {
                        console.log('🔍 Cargando desde dist/main/index.js');
                        loadedModule = require(mainModulePath);
                    } else if (fs2.existsSync(altModulePath)) {
                        console.log('🔍 Cargando desde index.js');
                        loadedModule = require(altModulePath);
                    } else {
                        console.log('🔍 Cargando directamente desde directorio');
                        loadedModule = require(modulePath);
                    }
                    
                    const { createClient } = loadedModule;
                    const SUPABASE_URL = process.env.SUPABASE_URL || 'https://lmoeuyasuvoqhtvhkyia.supabase.co';
                    const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || '';
                    
                    console.log('🔑 SUPABASE_SERVICE_KEY configurada:', !!SUPABASE_SERVICE_KEY);
                    
                    if (SUPABASE_SERVICE_KEY) {
                        supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
                            auth: {
                                autoRefreshToken: false,
                                persistSession: false
                            }
                        });
                        console.log('✅ Cliente de Supabase inicializado (helper function - carga forzada desde path)');
                        return true;
                    } else {
                        console.warn('⚠️ SUPABASE_SERVICE_KEY no configurada durante carga forzada');
                    }
                } catch (forceError) {
                    console.error('❌ Error al cargar desde path:', forceError.message);
                    console.error('❌ Stack:', forceError.stack);
                }
            } else {
                console.warn('⚠️ Módulo no existe físicamente en:', modulePath);
            }
            return false;
        }
    }
    return !!supabase;
}

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Middleware para prevenir caché en todos los archivos HTML y la ruta principal (AGRESIVO)
app.use((req, res, next) => {
    // Aplicar headers anti-caché a TODAS las rutas
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate, proxy-revalidate, max-age=0');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.setHeader('Surrogate-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('ETag', ''); // Eliminar ETag para evitar validación condicional
    res.setHeader('Last-Modified', ''); // Eliminar Last-Modified
    
    // Headers adicionales para forzar recarga
    res.setHeader('Vary', '*');
    res.setHeader('X-Accel-Expires', '0');
    
    next();
});

// Favicon e iconos PRIMERO (evitar 404) - 200 + body para evitar problemas con proxies/CDN
const FAVICON_SVG = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" fill="#1976d2" rx="4"/><text x="16" y="22" font-size="18" text-anchor="middle" fill="white" font-family="system-ui,sans-serif" font-weight="bold">C</text></svg>';
app.get('/favicon.ico', (req, res) => {
    res.setHeader('Content-Type', 'image/svg+xml');
    res.status(200).send(FAVICON_SVG);
});
app.get('/favicon.png', (req, res) => {
    res.setHeader('Content-Type', 'image/svg+xml');
    res.status(200).send(FAVICON_SVG);
});
app.get('/apple-touch-icon.png', (req, res) => {
    res.setHeader('Content-Type', 'image/svg+xml');
    res.status(200).send(FAVICON_SVG);
});

// ENDPOINTS PARA SUPABASE API (SEGUROS)
// ============================================

// Endpoint genérico para consultar una tabla
app.get('/api/supabase/test', async (req, res) => {
app.get('/api/supabase/:table', async (req, res) => {
    if (!supabase) {
        // Intentar inicializar si no está disponible
        if (!initializeSupabaseIfAvailable()) {
            return res.status(500).json({ 
                error: 'Supabase no está configurado en el servidor',
                configured: false
            });
        }
    }

    try {
        const { table } = req.params;
        const { select = '*', filter, order, limit } = req.query;

        // Validar nombre de tabla (seguridad)
        const allowedTables = ['hotels', 'reservations', 'quotes', 'expenses', 'checkin24hs_users', 'clientesDB', 'users'];
        if (!allowedTables.includes(table)) {
            return res.status(400).json({ 
                error: `Tabla '${table}' no permitida` 
            });
        }

        let query = supabase.from(table).select(select);

        // Aplicar filtros si existen
        if (filter) {
            try {
                const filterObj = JSON.parse(filter);
                Object.entries(filterObj).forEach(([key, value]) => {
                    query = query.eq(key, value);
                });
            } catch (e) {
                return res.status(400).json({ error: 'Filtro inválido' });
            }
        }

        // Aplicar ordenamiento
        if (order) {
            try {
                const [column, direction = 'asc'] = order.split(':');
                query = query.order(column, { ascending: direction.toLowerCase() !== 'desc' });
            } catch (e) {
                // Ignorar error de ordenamiento
            }
        }

        // Aplicar límite
        if (limit) {
            const limitNum = parseInt(limit);
            if (!isNaN(limitNum) && limitNum > 0) {
                query = query.limit(Math.min(limitNum, 1000)); // Máximo 1000
            }
        }

        const { data, error } = await query;

        if (error) {
            console.error(`❌ Error consultando ${table}:`, error);
            return res.status(400).json({ 
                error: error.message,
                details: error 
            });
        }

        res.json(data || []);
    } catch (error) {
        console.error('❌ Error en endpoint Supabase:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint genérico para insertar en una tabla
app.post('/api/supabase/:table', async (req, res) => {
    if (!supabase) {
        // Intentar inicializar si no está disponible
        if (!initializeSupabaseIfAvailable()) {
            return res.status(500).json({ 
                error: 'Supabase no está configurado en el servidor',
                configured: false
            });
        }
    }

    try {
        const { table } = req.params;
        const data = req.body;

        // Validar nombre de tabla
        const allowedTables = ['hotels', 'reservations', 'quotes', 'expenses', 'checkin24hs_users', 'clientesDB', 'users'];
        if (!allowedTables.includes(table)) {
            return res.status(400).json({ 
                error: `Tabla '${table}' no permitida` 
            });
        }

        // Insertar datos
        const { data: result, error } = await supabase
            .from(table)
            .insert(Array.isArray(data) ? data : [data])
            .select();

        if (error) {
            console.error(`❌ Error insertando en ${table}:`, error);
            return res.status(400).json({ 
                error: error.message,
                details: error 
            });
        }

        res.json(Array.isArray(data) ? result : (result[0] || result));
    } catch (error) {
        console.error('❌ Error en endpoint Supabase:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint genérico para actualizar en una tabla
app.put('/api/supabase/:table/:id', async (req, res) => {
    if (!supabase) {
        // Intentar inicializar si no está disponible
        if (!initializeSupabaseIfAvailable()) {
            return res.status(500).json({ 
                error: 'Supabase no está configurado en el servidor',
                configured: false
            });
        }
    }

    try {
        const { table, id } = req.params;
        const updates = req.body;

        // Validar nombre de tabla
        const allowedTables = ['hotels', 'reservations', 'quotes', 'expenses', 'checkin24hs_users', 'clientesDB', 'users'];
        if (!allowedTables.includes(table)) {
            return res.status(400).json({ 
                error: `Tabla '${table}' no permitida` 
            });
        }

        // Agregar updated_at
        updates.updated_at = new Date().toISOString();

        // Actualizar datos
        const { data, error } = await supabase
            .from(table)
            .update(updates)
            .eq('id', id)
            .select()
            .single();

        if (error) {
            console.error(`❌ Error actualizando ${table}:`, error);
            return res.status(400).json({ 
                error: error.message,
                details: error 
            });
        }

        res.json(data);
    } catch (error) {
        console.error('❌ Error en endpoint Supabase:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint genérico para eliminar de una tabla
app.delete('/api/supabase/:table/:id', async (req, res) => {
    if (!supabase) {
        // Intentar inicializar si no está disponible
        if (!initializeSupabaseIfAvailable()) {
            return res.status(500).json({ 
                error: 'Supabase no está configurado en el servidor',
                configured: false
            });
        }
    }

    try {
        const { table, id } = req.params;

        // Validar nombre de tabla
        const allowedTables = ['hotels', 'reservations', 'quotes', 'expenses', 'checkin24hs_users', 'clientesDB', 'users'];
        if (!allowedTables.includes(table)) {
            return res.status(400).json({ 
                error: `Tabla '${table}' no permitida` 
            });
        }

        // Eliminar datos
        const { error } = await supabase
            .from(table)
            .delete()
            .eq('id', id);

        if (error) {
            console.error(`❌ Error eliminando de ${table}:`, error);
            return res.status(400).json({ 
                error: error.message,
                details: error 
            });
        }

        res.json({ success: true, message: `Registro ${id} eliminado de ${table}` });
    } catch (error) {
        console.error('❌ Error en endpoint Supabase:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para probar conexión con Supabase
    if (!supabase) {
        // Intentar inicializar si no está disponible
        if (!initializeSupabaseIfAvailable()) {
            return res.status(500).json({ 
                error: 'Supabase no está configurado en el servidor',
                configured: false
            });
        }
    }

    try {
        // Probar con una consulta simple
        const { data, error } = await supabase
            .from('hotels')
            .select('id')
            .limit(1);

        if (error) {
            return res.status(400).json({ 
                error: error.message,
                configured: true,
                connected: false
            });
        }

        res.json({ 
            success: true,
            configured: true,
            connected: true,
            message: 'Conexión exitosa con Supabase'
        });
    } catch (error) {
        res.status(500).json({ 
            error: error.message,
            configured: true,
            connected: false
        });
    }
});

// Rutas específicas ANTES de express.static para tener prioridad
// (favicon ya está definido arriba, justo después del middleware)

// Endpoint para verificación de versión (cache busting)
app.get('/api/version', (req, res) => {
    try {
        const dashboardContent = fs.readFileSync(path.join(__dirname, 'dashboard.html'), { encoding: 'utf8' });
        const buildTimestampMatch = dashboardContent.match(/window\.BUILD_TIMESTAMP = ['"]([^'"]+)['"]/);
        const versionMatch = dashboardContent.match(/window\.DASHBOARD_VERSION = ['"]([^'"]+)['"]/);
        
        res.json({
            version: versionMatch ? versionMatch[1] : '2.1.0',
            buildTimestamp: buildTimestampMatch ? buildTimestampMatch[1] : null,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.json({
            version: '2.1.0',
            buildTimestamp: null,
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

// ============================================
// ENDPOINTS PARA GEMINI API (SEGUROS)
// ============================================

// Endpoint para generar contenido con Gemini
app.post('/api/gemini/generate', async (req, res) => {
    try {
        const { prompt, model, maxTokens } = req.body;
        
        if (!GEMINI_API_KEY) {
            return res.status(500).json({ 
                error: 'GEMINI_API_KEY no configurada en el servidor' 
            });
        }
        
        const modelToUse = model || GEMINI_MODEL;
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelToUse}:generateContent?key=${GEMINI_API_KEY}`;
        
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: { 
                    maxOutputTokens: maxTokens || 500 
                }
            })
        });
        
        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error('❌ Error llamando a Gemini:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para listar modelos disponibles
app.get('/api/gemini/models', async (req, res) => {
    try {
        if (!GEMINI_API_KEY) {
            return res.status(500).json({ 
                error: 'GEMINI_API_KEY no configurada' 
            });
        }
        
        const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_API_KEY}`;
        const response = await fetch(url);
        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error('❌ Error listando modelos:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint para probar la API Key (sin exponer la clave)
app.post('/api/gemini/test', async (req, res) => {
    try {
        if (!GEMINI_API_KEY) {
            return res.status(500).json({ 
                error: 'GEMINI_API_KEY no configurada',
                configured: false
            });
        }
        
        // Probar con un mensaje simple
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: 'Responde solo con: OK' }] }],
                generationConfig: { maxOutputTokens: 10 }
            })
        });
        
        const data = await response.json();
        
        if (data.error) {
            return res.status(400).json({ 
                error: data.error.message,
                configured: true,
                valid: false
            });
        }
        
        res.json({ 
            success: true,
            configured: true,
            valid: true,
            model: GEMINI_MODEL
        });
    } catch (error) {
        res.status(500).json({ 
            error: error.message,
            configured: true,
            valid: false
        });
    }
});

// GET /api/gemini/test: abrir la URL en el navegador hace GET; el test real usa POST desde "Probar Conexión"
app.get('/api/gemini/test', (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.status(405).json({
        error: 'Use POST to test Gemini. This endpoint does not support GET.',
        hint: 'Use "Probar Conexión" in Flor IA → IA tab (dashboard).'
    });
});

// Ruta principal - Dashboard de administración (DEBE estar ANTES de express.static)
app.get('/', (req, res) => {
    // Headers anti-caché ULTRA AGRESIVOS
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate, proxy-revalidate, max-age=0, private');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.setHeader('Surrogate-Control', 'no-store');
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Content-Encoding', 'utf-8');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('ETag', ''); // Eliminar ETag
    res.setHeader('Last-Modified', ''); // Eliminar Last-Modified
    res.setHeader('Vary', '*');
    res.setHeader('X-Accel-Expires', '0');
    // Agregar timestamp único en la respuesta para forzar recarga
    res.setHeader('X-Build-Timestamp', new Date().toISOString());
    res.setHeader('X-Request-ID', Date.now().toString());
    
    // Leer el archivo como UTF-8 y enviarlo con codificación correcta
    const dashboardPath = path.join(__dirname, 'dashboard.html');
    fs.readFile(dashboardPath, { encoding: 'utf8' }, (err, data) => {
        if (err) {
            console.error('Error al leer dashboard.html:', err);
            res.status(500).send('Error al cargar el dashboard');
            return;
        }
        // Asegurar que el contenido se envíe como UTF-8
        // Convertir a Buffer con codificación UTF-8 explícita
        const utf8Buffer = Buffer.from(data, 'utf8');
        res.setHeader('Content-Length', utf8Buffer.length);
        res.send(utf8Buffer.toString('utf8'));
    });
});

// Servir dashboard cuando se solicite /index (evitar 404 "(index):1")
app.get('/index', (req, res) => {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Content-Encoding', 'utf-8');
    const dashboardPath = path.join(__dirname, 'dashboard.html');
    fs.readFile(dashboardPath, { encoding: 'utf8' }, (err, data) => {
        if (err) {
            console.error('Error al leer dashboard.html:', err);
            return res.status(500).send('Error al cargar el dashboard');
        }
        res.send(Buffer.from(data, 'utf8').toString('utf8'));
    });
});

// Servir dashboard.html cuando se solicite index.html (sin redirección)
app.get('/index.html', (req, res) => {
    // Headers UTF-8
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Content-Encoding', 'utf-8');
    
    // Leer y enviar como UTF-8
    const dashboardPath = path.join(__dirname, 'dashboard.html');
    fs.readFile(dashboardPath, { encoding: 'utf8' }, (err, data) => {
        if (err) {
            console.error('Error al leer dashboard.html:', err);
            res.status(500).send('Error al cargar el dashboard');
            return;
        }
        // Asegurar codificación UTF-8
        const utf8Buffer = Buffer.from(data, 'utf8');
        res.setHeader('Content-Length', utf8Buffer.length);
        res.send(utf8Buffer.toString('utf8'));
    });
});

// También servir dashboard.html directamente
app.get('/dashboard.html', (req, res) => {
    // Headers UTF-8
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Content-Encoding', 'utf-8');
    
    // Leer y enviar como UTF-8
    const dashboardPath = path.join(__dirname, 'dashboard.html');
    fs.readFile(dashboardPath, { encoding: 'utf8' }, (err, data) => {
        if (err) {
            console.error('Error al leer dashboard.html:', err);
            res.status(500).send('Error al cargar el dashboard');
            return;
        }
        // Asegurar codificación UTF-8
        const utf8Buffer = Buffer.from(data, 'utf8');
        res.setHeader('Content-Length', utf8Buffer.length);
        res.send(utf8Buffer.toString('utf8'));
    });
});

// Servir archivos estáticos (después de las rutas específicas, sin index automático)
app.use(express.static('.', { index: false })); // index: false evita que sirva index.html automáticamente

// Ruta para imagen de preview del cotizador (Open Graph / WhatsApp)
app.get('/og-cotizar.jpg', (req, res) => {
    try {
        // Intentar servir una imagen de hotel como preview
        // Prioridad: hotel-1-puyehue/main.jpg, luego otros hoteles
        const possibleImages = [
            path.join(__dirname, 'hotel-images', 'hotel-1-puyehue', 'main.jpg'),
            path.join(__dirname, 'hotel-images', 'hotel-2-huilo-huilo', 'main.jpg'),
            path.join(__dirname, 'hotel-images', 'hotel-3-corralco', 'main.jpg'),
            path.join(__dirname, 'hotel-images', 'hotel-4-futangue', 'main.jpg'),
            path.join(__dirname, 'hotel-images', 'hotel-5-aguas-calientes', 'main.jpg')
        ];
        
        let imagePath = null;
        for (const imgPath of possibleImages) {
            if (fs.existsSync(imgPath)) {
                imagePath = imgPath;
                break;
            }
        }
        
        if (!imagePath) {
            // Si no hay imágenes de hoteles, devolver 404 o una imagen por defecto
            return res.status(404).json({ error: 'Imagen de preview no encontrada' });
        }
        
        // Enviar la imagen con headers apropiados
        res.setHeader('Content-Type', 'image/jpeg');
        res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache por 1 día
        res.sendFile(imagePath);
    } catch (error) {
        console.error('❌ Error sirviendo imagen de preview:', error);
        res.status(500).json({ error: 'Error al servir imagen' });
    }
});

// Ruta para test-cotizacion
app.get('/test', (req, res) => {
    res.sendFile(__dirname + '/test-cotizacion.html');
});

// API para cotización de Puyehue
app.post('/api/puyehue-quote', async (req, res) => {
    try {
        console.log('📋 Recibida solicitud de cotización:', req.body);
        
        const quoteData = {
            checkIn: req.body.checkIn,
            checkOut: req.body.checkOut,
            adults: parseInt(req.body.adults) || 2,
            children: parseInt(req.body.children) || 0,
            nights: parseInt(req.body.nights) || 1,
            selectedProgram: req.body.selectedProgram || 'EXPERIENCIA'
        };
        
        console.log('🚀 Iniciando cotización con Puppeteer...');
        const result = await getRealPuyehueQuote(quoteData);
        
        console.log('✅ Resultado de la cotización:', result);
        res.json(result);
        
    } catch (error) {
        console.error('❌ Error en la API:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            message: 'Error interno del servidor'
        });
    }
});

// Función auxiliar para obtener slug del hotel
function getHotelSlug(hotelName) {
    // Remover la palabra "Hotel" del inicio si existe
    let cleanName = hotelName.replace(/^hotel\s+/i, '');
    
    return cleanName.toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .trim();
}

// Función auxiliar para buscar hotel por nombre
function findHotelByName(hotelName) {
    // Mapeo de nombres de hoteles a sus IDs y slugs
    const hotelMap = {
        'hotel terma de puyehue': { id: 1, slug: 'puyehue', name: 'Hotel Terma de Puyehue' },
        'termas de puyehue': { id: 1, slug: 'puyehue', name: 'Hotel Terma de Puyehue' },
        'puyehue': { id: 1, slug: 'puyehue', name: 'Hotel Terma de Puyehue' },
        'hotel huilo-huilo': { id: 2, slug: 'huilo-huilo', name: 'Hotel Huilo-Huilo' },
        'huilo huilo': { id: 2, slug: 'huilo-huilo', name: 'Hotel Huilo-Huilo' },
        'huilo-huilo': { id: 2, slug: 'huilo-huilo', name: 'Hotel Huilo-Huilo' },
        'hotel corralco': { id: 3, slug: 'corralco', name: 'Hotel Corralco Resort' },
        'corralco resort': { id: 3, slug: 'corralco', name: 'Hotel Corralco Resort' },
        'corralco': { id: 3, slug: 'corralco', name: 'Hotel Corralco Resort' },
        'hotel futangue': { id: 4, slug: 'futangue', name: 'Hotel Futangue' },
        'futangue': { id: 4, slug: 'futangue', name: 'Hotel Futangue' },
        'termas de aguas calientes': { id: 5, slug: 'aguas-calientes', name: 'Termas de Aguas Calientes' },
        'aguas calientes': { id: 5, slug: 'aguas-calientes', name: 'Termas de Aguas Calientes' },
        'aguas-calientes': { id: 5, slug: 'aguas-calientes', name: 'Termas de Aguas Calientes' }
    };

    const searchTerm = hotelName.toLowerCase().trim();
    
    // Buscar coincidencia exacta primero
    if (hotelMap[searchTerm]) {
        return hotelMap[searchTerm];
    }
    
    // Buscar coincidencia parcial
    for (const [key, value] of Object.entries(hotelMap)) {
        if (key.includes(searchTerm) || searchTerm.includes(key)) {
            return value;
        }
    }
    
    return null;
}

// Endpoint para obtener imagen de hotel
app.get('/api/hoteles/imagen/:nombre_hotel', (req, res) => {
    try {
        const nombreHotel = decodeURIComponent(req.params.nombre_hotel);
        const imageType = req.query.type || 'main'; // 'main', 'gallery-1', 'gallery-2', etc.
        
        console.log(`📸 Solicitud de imagen para: ${nombreHotel} (tipo: ${imageType})`);
        
        // Buscar el hotel
        const hotel = findHotelByName(nombreHotel);
        
        if (!hotel) {
            return res.status(404).json({
                success: false,
                error: 'Hotel no encontrado',
                message: `No se encontró el hotel "${nombreHotel}"`
            });
        }
        
        // Construir ruta de la imagen
        const imageDir = path.join(__dirname, 'hotel-images', `hotel-${hotel.id}-${hotel.slug}`);
        let imagePath;
        
        if (imageType === 'main') {
            imagePath = path.join(imageDir, 'main.jpg');
        } else if (imageType.startsWith('gallery-')) {
            const galleryNum = imageType.replace('gallery-', '');
            imagePath = path.join(imageDir, `gallery-${galleryNum}.jpg`);
        } else {
            imagePath = path.join(imageDir, `${imageType}.jpg`);
        }
        
        // Verificar si el archivo existe
        if (!fs.existsSync(imagePath)) {
            // Intentar con main.jpg como fallback
            const fallbackPath = path.join(imageDir, 'main.jpg');
            if (fs.existsSync(fallbackPath)) {
                imagePath = fallbackPath;
                console.log(`⚠️ Imagen ${imageType} no encontrada, usando main.jpg como fallback`);
            } else {
                return res.status(404).json({
                    success: false,
                    error: 'Imagen no encontrada',
                    message: `No se encontró la imagen para ${hotel.name}`
                });
            }
        }
        
        // Enviar la imagen
        const imageUrl = `/hotel-images/hotel-${hotel.id}-${hotel.slug}/${path.basename(imagePath)}`;
        
        console.log(`✅ Imagen encontrada: ${imageUrl}`);
        
        res.json({
            success: true,
            hotel: hotel.name,
            imageUrl: imageUrl,
            imagePath: imagePath,
            type: imageType
        });
        
    } catch (error) {
// ============================================
        console.error('❌ Error al obtener imagen de hotel:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            message: 'Error interno del servidor'
        });
    }
});

// Ruta de salud
app.get('/health', (req, res) => {
    res.json({ status: 'OK', message: 'Servidor funcionando correctamente' });
});

// Manejo de errores
app.use((err, req, res, next) => {
    console.error('❌ Error no manejado:', err);
    res.status(500).json({
        success: false,
        error: 'Error interno del servidor',
        message: err.message
    });
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor iniciado en http://0.0.0.0:${PORT}`);
    console.log(`📊 API disponible en http://0.0.0.0:${PORT}/api/puyehue-quote`);
    console.log(`🌐 Frontend disponible en http://0.0.0.0:${PORT}`);
    console.log(`🔑 GEMINI_API_KEY: ${GEMINI_API_KEY ? '✅ Configurada' : '❌ NO configurada'}`);
    if (GEMINI_API_KEY) {
        console.log(`🤖 Modelo Gemini: ${GEMINI_MODEL}`);
    }
});

module.exports = app; 