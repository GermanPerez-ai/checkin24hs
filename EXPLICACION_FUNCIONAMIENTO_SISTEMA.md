# 🔍 Explicación: Cómo Funciona el Sistema de Imágenes de Preview

## 📊 Flujo Completo del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│  1. Usuario envía enlace en WhatsApp                        │
│     https://cotizar.checkin24hs.com/                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  2. WhatsApp busca metadata (Open Graph)                    │
│     - Título: <meta property="og:title">                    │
│     - Imagen: <meta property="og:image">                    │
│       content="https://dashboard.checkin24hs.com/og-cotizar.jpg"
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  3. WhatsApp hace petición HTTP GET                         │
│     GET https://dashboard.checkin24hs.com/og-cotizar.jpg    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Traefik (reverse proxy)                                 │
│     - Recibe la petición                                    │
│     - Rutea a: checkin24hs_dashboard (puerto 3000)          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Node.js server (server.js)                              │
│     - Detecta: req.url === '/og-cotizar.jpg'               │
│     - Ejecuta lógica de búsqueda de imagen                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  6. Búsqueda Dinámica de Hoteles                            │
│                                                              │
│   a) ¿Existe variable OG_COTIZAR_IMAGE?                      │
│      ✅ SÍ → Usar ese hotel específico                     │
│      ❌ NO → Continuar con búsqueda automática              │
│                                                              │
│   b) Buscar en directorios:                                 │
│      - ../hotel-images/  (desde raíz del proyecto)         │
│      - ./hotel-images/   (dentro del contenedor)            │
│                                                              │
│   c) Para cada directorio que empiece con "hotel-":         │
│      - Verificar que existe                                 │
│      - Verificar que tiene main.jpg                         │
│      - Agregar a lista de hoteles disponibles               │
│                                                              │
│   d) Ordenar alfabéticamente                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  7. Construir Lista de Rutas Posibles                       │
│                                                              │
│   Si hay hotel seleccionado:                                │
│   [1] ../hotel-images/hotel-X/main.jpg  ← Prioridad        │
│   [2] ./hotel-images/hotel-X/main.jpg                      │
│                                                              │
│   Luego todos los demás hoteles:                           │
│   [3] ../hotel-images/hotel-1/main.jpg                      │
│   [4] ./hotel-images/hotel-1/main.jpg                      │
│   [5] ../hotel-images/hotel-2/main.jpg                      │
│   [6] ./hotel-images/hotel-2/main.jpg                      │
│   ... (y así sucesivamente)                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  8. Buscar Primera Imagen que Exista                        │
│                                                              │
│   for (cada ruta en possiblePaths) {                        │
│     if (fs.existsSync(ruta)) {                             │
│       imagePath = ruta;  ← ¡Encontrada!                    │
│       break;  ← Detener búsqueda                             │
│     }                                                        │
│   }                                                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  9. Servir la Imagen                                         │
│                                                              │
│   - Leer archivo: fs.readFile(imagePath)                    │
│   - Responder con:                                          │
│     * HTTP 200 OK                                            │
│     * Content-Type: image/jpeg                               │
│     * Cache-Control: public, max-age=86400 (1 día)         │
│     * Body: contenido binario de la imagen                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  10. WhatsApp muestra el Preview                            │
│      - Título del cotizador                                 │
│      - Descripción                                          │
│      - Imagen del hotel seleccionada                        │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Componentes del Sistema

### 1. **server.js** (Node.js)
```javascript
// Detecta la petición
if (req.url === '/og-cotizar.jpg') {
  // Busca hoteles dinámicamente
  // Encuentra la imagen
  // La sirve
}
```

**Funciones clave:**
- `findAvailableHotels()`: Busca todos los hoteles disponibles
- Construye lista de rutas posibles
- Encuentra la primera imagen que existe
- Sirve la imagen con headers correctos

### 2. **hotel-images/** (Directorio)
```
hotel-images/
  ├── hotel-1-puyehue/
  │   └── main.jpg  ← Imagen principal
  ├── hotel-2-huilo-huilo/
  │   └── main.jpg
  └── hotel-X-nuevo/  ← ¡Nuevo hotel automáticamente detectado!
      └── main.jpg
```

**Reglas:**
- Directorio debe empezar con `hotel-`
- Debe tener `main.jpg` dentro
- El sistema lo detecta automáticamente

### 3. **Variable de Entorno** (Opcional)
```
OG_COTIZAR_IMAGE=hotel-2-huilo-huilo
```

**Efecto:**
- Fuerza el uso de ese hotel específico
- Tiene prioridad sobre la búsqueda automática
- Se configura en EasyPanel

## 🎯 Ejemplo Práctico Paso a Paso

### Escenario: Usuario envía enlace en WhatsApp

**Paso 1:** Usuario escribe en WhatsApp:
```
https://cotizar.checkin24hs.com/
```

**Paso 2:** WhatsApp lee el HTML de `cotizador-cliente.html`:
```html
<meta property="og:image" 
      content="https://dashboard.checkin24hs.com/og-cotizar.jpg">
```

**Paso 3:** WhatsApp hace petición:
```
GET https://dashboard.checkin24hs.com/og-cotizar.jpg
```

**Paso 4:** `server.js` ejecuta:
```javascript
// 1. ¿Hay variable OG_COTIZAR_IMAGE?
selectedHotel = process.env.OG_COTIZAR_IMAGE || null;
// Resultado: null (no hay variable)

// 2. Buscar hoteles disponibles
allHotels = ['hotel-1-puyehue', 'hotel-2-huilo-huilo', ...]
// Ordenados alfabéticamente

// 3. Construir rutas
possiblePaths = [
  '../hotel-images/hotel-1-puyehue/main.jpg',  ← Primera
  './hotel-images/hotel-1-puyehue/main.jpg',
  '../hotel-images/hotel-2-huilo-huilo/main.jpg',
  ...
]

// 4. Buscar primera que existe
imagePath = '../hotel-images/hotel-1-puyehue/main.jpg'  ← ¡Encontrada!

// 5. Servir imagen
res.writeHead(200, { 'Content-Type': 'image/jpeg' });
res.end(imagenBinaria);
```

**Paso 5:** WhatsApp muestra preview con la imagen de `hotel-1-puyehue`

## 🔄 Casos Especiales

### Caso 1: Variable de Entorno Configurada
```bash
OG_COTIZAR_IMAGE=hotel-3-corralco
```

**Resultado:**
- Siempre usa `hotel-3-corralco`
- Ignora el orden alfabético
- Útil para forzar un hotel específico

### Caso 2: Nuevo Hotel Agregado
```bash
mkdir hotel-images/hotel-6-villarrica
cp imagen.jpg hotel-images/hotel-6-villarrica/main.jpg
```

**Resultado:**
- Sistema lo detecta automáticamente
- Aparece en la lista de hoteles disponibles
- No requiere modificar código

### Caso 3: Hotel sin main.jpg
```
hotel-images/
  └── hotel-7-sin-imagen/  ← Sin main.jpg
      └── foto.jpg
```

**Resultado:**
- No se detecta (requiere `main.jpg`)
- No aparece en la lista
- Se ignora en la búsqueda

## 📝 Ventajas del Sistema Dinámico

1. **✅ Automático**: No necesitas modificar código
2. **✅ Escalable**: Agregar hoteles es solo crear directorio
3. **✅ Flexible**: Puedes forzar un hotel con variable de entorno
4. **✅ Mantenible**: Un solo lugar para la lógica
5. **✅ Robusto**: Busca en múltiples ubicaciones

## 🛠️ Cómo Cambiar la Imagen

### Opción A: Temporal (Servidor)
```bash
./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh hotel-2-huilo-huilo
```
- Cambia el código en el contenedor
- Se pierde al reiniciar

### Opción B: Permanente (Variable de Entorno)
En EasyPanel:
```
OG_COTIZAR_IMAGE=hotel-2-huilo-huilo
```
- Persistente
- No requiere rebuild

### Opción C: Script Guiado
```bash
./GUIAR_CAMBIO_IMAGEN_DINAMICO.sh
```
- Detecta todos los hoteles
- Te guía paso a paso
- Aplica el cambio que elijas

## 🎓 Resumen

**El sistema funciona así:**

1. **Detecta** todos los hoteles en `hotel-images/`
2. **Ordena** alfabéticamente
3. **Prioriza** variable de entorno si existe
4. **Busca** la primera imagen que existe
5. **Sirve** la imagen con headers correctos

**Para agregar un nuevo hotel:**
- Solo crea: `hotel-images/hotel-X-nombre/main.jpg`
- El sistema lo detecta automáticamente
- ¡No necesitas tocar código!
