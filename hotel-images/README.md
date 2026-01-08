# Sistema de Gestión de Imágenes de Hoteles

## 📁 Estructura de Carpetas

Cada hotel tiene su propia carpeta con el siguiente formato:
```
hotel-images/
├── hotel-1-puyehue/          # Hotel Terma de Puyehue
├── hotel-2-huilo-huilo/      # Hotel Huilo-Huilo
├── hotel-3-corralco/         # Hotel Corralco Resort
├── hotel-4-futangue/         # Hotel Futangue
└── hotel-5-aguas-calientes/  # Termas de Aguas Calientes
```

## 🖼️ Organización de Imágenes

### Imagen Principal
- **Archivo**: `main.jpg` (o `main.png`)
- **Uso**: Imagen principal que aparece en las tarjetas de hoteles
- **Recomendación**: Imagen de alta calidad, formato horizontal

### Galería de Fotos
- **Archivos**: `gallery-1.jpg`, `gallery-2.jpg`, `gallery-3.jpg`, etc.
- **Uso**: Imágenes adicionales que se muestran en el detalle del hotel
- **Recomendación**: Variedad de ángulos y espacios del hotel

### Imágenes Específicas
- **`exterior.jpg`**: Vista exterior del hotel
- **`interior.jpg`**: Áreas comunes interiores
- **`room.jpg`**: Habitaciones típicas
- **`pool.jpg`**: Piscina o áreas de recreación
- **`spa.jpg`**: Áreas de spa o bienestar
- **`restaurant.jpg`**: Restaurante del hotel

## 📋 Formatos Soportados

- **Formatos**: JPG, JPEG, PNG, WebP
- **Tamaño recomendado**: 800x600px mínimo
- **Peso máximo**: 2MB por imagen
- **Nomenclatura**: Usar nombres descriptivos en minúsculas con guiones

## 🚀 Cómo Usar

### 1. Agregar Imágenes Manualmente
1. Navega a la carpeta del hotel correspondiente
2. Copia las imágenes a la carpeta
3. Usa nombres descriptivos (ej: `main.jpg`, `pool-view.jpg`)

### 2. Usar el Gestor de Imágenes (Dashboard)
1. Abre el dashboard: `dashboard.html`
2. Ve a la sección "Hoteles"
3. Haz clic en "Editar" en el hotel deseado
4. Haz clic en "Seleccionar" junto a "Imagen Principal" o "Galería de Fotos"
5. Sube nuevas imágenes o selecciona las existentes

### 3. Sincronización Automática
- Los cambios se reflejan automáticamente en `index.html`
- Las imágenes se cargan desde las carpetas correspondientes
- El sistema mantiene la organización por hotel

## 🔧 Configuración Avanzada

### Agregar un Nuevo Hotel
1. Crear nueva carpeta: `hotel-images/hotel-X-nombre-hotel/`
2. Agregar imágenes con nombres estándar
3. Actualizar el array de hoteles en el código

### Personalizar Nombres de Archivos
- El sistema es flexible con los nombres de archivos
- Se recomienda usar nombres descriptivos
- Evitar espacios y caracteres especiales

## 📱 Compatibilidad

- **Navegadores**: Chrome, Firefox, Safari, Edge
- **Dispositivos**: Desktop, tablet, móvil
- **Sistemas**: Windows, macOS, Linux

## 🛠️ Solución de Problemas

### Imagen no se muestra
- Verificar que el archivo existe en la carpeta correcta
- Comprobar el formato de archivo (JPG, PNG, etc.)
- Verificar que el nombre del archivo no tenga caracteres especiales

### Error de carga
- Verificar permisos de carpeta
- Comprobar que el servidor web tenga acceso a las carpetas
- Revisar la consola del navegador para errores

## 📞 Soporte

Para problemas técnicos o preguntas sobre el sistema de imágenes, consulta la documentación del proyecto o contacta al equipo de desarrollo. 