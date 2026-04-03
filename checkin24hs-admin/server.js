const http = require('http');
const fs = require('fs');
const path = require('path');

const port = 3000;
const buildDir = path.join(__dirname, 'build');

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'application/font-woff',
  '.woff2': 'application/font-woff2',
  '.ttf': 'application/font-ttf',
  '.eot': 'application/vnd.ms-fontobject'
};

const server = http.createServer((req, res) => {
  // Ruta especial para imagen de preview del cotizador (Open Graph / WhatsApp)
  // Acepta parámetros de query string para forzar actualización de cache (ej: ?v=2)
  if (req.url.startsWith('/og-cotizar.jpg')) {
    try {
      // Configuración: Puedes cambiar la imagen de dos formas:
      // 1. Variable de entorno OG_COTIZAR_IMAGE (ej: "hotel-1-puyehue", "hotel-2-huilo-huilo", etc.)
      // 2. El sistema detecta automáticamente todos los hoteles disponibles
      
      const selectedHotel = process.env.OG_COTIZAR_IMAGE || null; // ej: "hotel-1-puyehue"
      const buildDir = path.join(__dirname, 'build');

      // Prioridad 0: Imagen incluida en el build (public/og-cotizar.jpg → build/og-cotizar.jpg). Siempre disponible en el contenedor.
      const buildPreviewPath = path.join(buildDir, 'og-cotizar.jpg');

      // Prioridad 1: Imagen personalizada en hotel-images/og-preview.jpg (solo pon tu imagen ahí)
      const customPreviewPaths = [
        path.join(__dirname, '..', 'hotel-images', 'og-preview.jpg'),
        path.join(__dirname, 'hotel-images', 'og-preview.jpg')
      ];
      
      // Función para buscar todos los hoteles disponibles dinámicamente
      const findAvailableHotels = (baseDir) => {
        const hotels = [];
        try {
          const hotelImagesDir = path.join(baseDir, 'hotel-images');
          if (fs.existsSync(hotelImagesDir)) {
            const entries = fs.readdirSync(hotelImagesDir, { withFileTypes: true });
            entries.forEach(entry => {
              if (entry.isDirectory() && entry.name.startsWith('hotel-')) {
                const mainImagePath = path.join(hotelImagesDir, entry.name, 'main.jpg');
                if (fs.existsSync(mainImagePath)) {
                  hotels.push(entry.name);
                }
              }
            });
          }
        } catch (error) {
          // Si hay error, continuar con lista vacía
        }
        return hotels.sort(); // Ordenar alfabéticamente para consistencia
      };
      
      // Buscar hoteles disponibles en ambas ubicaciones posibles
      const hotelsFromParent = findAvailableHotels(path.join(__dirname, '..'));
      const hotelsFromCurrent = findAvailableHotels(__dirname);
      
      // Combinar y eliminar duplicados
      const allHotels = [...new Set([...hotelsFromParent, ...hotelsFromCurrent])].sort();
      
      // Construir lista de rutas posibles (primero build, luego personalizada, luego hoteles)
      let possiblePaths = [buildPreviewPath, ...customPreviewPaths];
      
      if (selectedHotel) {
        // Si hay un hotel específico configurado, ponerlo primero
        possiblePaths.push(
          path.join(__dirname, '..', 'hotel-images', selectedHotel, 'main.jpg'),
          path.join(__dirname, 'hotel-images', selectedHotel, 'main.jpg')
        );
      }
      
      // Agregar todos los hoteles encontrados (el seleccionado ya está arriba)
      allHotels.forEach(hotel => {
        if (!selectedHotel || hotel !== selectedHotel) {
          possiblePaths.push(
            path.join(__dirname, '..', 'hotel-images', hotel, 'main.jpg'),
            path.join(__dirname, 'hotel-images', hotel, 'main.jpg')
          );
        }
      });
      
      let imagePath = null;
      for (const imgPath of possiblePaths) {
        if (fs.existsSync(imgPath)) {
          imagePath = imgPath;
          break;
        }
      }
      
      if (!imagePath) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Imagen de preview no encontrada' }));
        return;
      }
      
      // Leer y servir la imagen
      fs.readFile(imagePath, (error, content) => {
        if (error) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Error al leer imagen' }));
        } else {
          res.writeHead(200, {
            'Content-Type': 'image/jpeg',
            'Cache-Control': 'public, max-age=86400' // Cache por 1 día
          });
          res.end(content);
        }
      });
      return;
    } catch (error) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Error al servir imagen' }));
      return;
    }
  }
  
  // Limpiar la URL
  let filePath = req.url === '/' ? '/index.html' : req.url;
  filePath = path.join(buildDir, filePath);

  const ext = path.extname(filePath).toLowerCase();
  const contentType = mimeTypes[ext] || 'application/octet-stream';

  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        // Si el archivo no existe, servir index.html (para React Router)
        const indexPath = path.join(buildDir, 'index.html');
        fs.readFile(indexPath, (err, cont) => {
          if (err) {
            res.writeHead(500);
            res.end('Error loading index.html');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(cont, 'utf-8');
          }
        });
      } else {
        res.writeHead(500);
        res.end('Server Error: ' + error.code);
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://0.0.0.0:${port}/`);
});

