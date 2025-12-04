# Sistema de Cotización Automática - Termas de Puyehue

## 🎯 Descripción

Sistema automatizado de cotización para **Termas de Puyehue** que conecta directamente con el portal oficial de reservas para obtener precios y disponibilidad en tiempo real.

## ✨ Características

- **Conexión Real**: Se conecta automáticamente al portal oficial de Puyehue
- **Autenticación Automática**: Usa credenciales de agencia para acceso privilegiado
- **Extracción de Precios**: Obtiene precios reales y dinámicos del portal
- **Interfaz Web**: Frontend moderno para solicitar cotizaciones
- **API REST**: Backend con Puppeteer para automatización web
- **Manejo de Errores**: Sistema robusto con reintentos y fallbacks

## 🏗️ Arquitectura

```
Frontend (HTML/JS) ←→ API REST ←→ Puppeteer ←→ Portal Puyehue
```

### Componentes:

1. **Frontend**: `test-cotizacion.html` - Interfaz de usuario
2. **Backend**: `server.js` - Servidor Express con API REST
3. **Automatización**: `puppeteer-real-cotizacion.js` - Script de Puppeteer
4. **Configuración**: `package.json` - Dependencias y scripts

## 🚀 Instalación

### Prerrequisitos

- Node.js (versión 14 o superior)
- npm

### Pasos de Instalación

1. **Clonar/Descargar el proyecto**
   ```bash
   cd Checkin24hs
   ```

2. **Instalar dependencias**
   ```bash
   npm install
   ```

3. **Verificar instalación**
   ```bash
   npm test
   ```

## 🎮 Uso

### Iniciar el Servidor

   ```bash
   npm start
   ```

El servidor se iniciará en `http://localhost:3000`

### Acceder a la Aplicación

1. Abrir navegador en `http://localhost:3000`
2. Completar formulario de cotización
3. Hacer clic en "Cotizar"
4. Ver resultados en tiempo real

### Endpoints de la API

- `GET /` - Página principal
- `POST /api/puyehue-quote` - Cotización automática
- `GET /health` - Estado del servidor

## 🔧 Configuración

### Credenciales de Portal

Las credenciales están configuradas en `puppeteer-real-cotizacion.js`:

```javascript
username: 'canopypromo'
password: 'canopypromo'
```

### Variables de Entorno

- `PORT` - Puerto del servidor (default: 3000)

## 📊 Flujo de Trabajo

1. **Usuario ingresa datos** en el frontend
2. **Frontend envía solicitud** a la API REST
3. **Backend inicia Puppeteer** y navega al portal
4. **Puppeteer hace login** con credenciales de agencia
5. **Se llenan formularios** con datos del usuario
6. **Se extraen precios** de la página de respuesta
7. **Se devuelven datos** al frontend
8. **Frontend muestra resultados** al usuario

## 🛠️ Desarrollo

### Estructura de Archivos

```
├── test-cotizacion.html      # Frontend principal
├── server.js                 # Servidor Express
├── puppeteer-real-cotizacion.js  # Script de automatización
├── package.json              # Configuración del proyecto
└── README.md                # Documentación
```

### Scripts Disponibles

- `npm start` - Iniciar servidor de producción
- `npm dev` - Iniciar servidor de desarrollo
- `npm test` - Ejecutar script de Puppeteer directamente

## 🔍 Debugging

### Logs del Servidor

El servidor muestra logs detallados:
- ✅ Conexión exitosa
- ❌ Errores de conexión
- 📋 Datos de cotización
- 💰 Precios extraídos

### Modo Debug

Para ver el navegador durante la automatización:
```javascript
headless: false  // En puppeteer-real-cotizacion.js
```

## 🚨 Manejo de Errores

### Errores Comunes

1. **Timeout de navegación**: El portal tarda en responder
2. **Elementos no encontrados**: Cambios en la estructura del portal
3. **Credenciales inválidas**: Problemas de autenticación

### Estrategias de Recuperación

- Reintentos automáticos
- Fallback a contacto manual
- Mensajes informativos al usuario

## 🔒 Seguridad

- Credenciales hardcodeadas (solo para desarrollo)
- CORS habilitado para desarrollo local
- Validación de datos de entrada

## 📈 Monitoreo

### Métricas Disponibles

- Tiempo de respuesta del portal
- Tasa de éxito de extracción
- Errores por tipo

## 🔄 Actualizaciones

### Mantenimiento

- Revisar selectores CSS regularmente
- Actualizar credenciales si es necesario
- Monitorear cambios en el portal

## 📞 Soporte

Para problemas técnicos:
- Revisar logs del servidor
- Verificar conectividad al portal
- Comprobar credenciales

## 📄 Licencia

MIT License - Checkin24hs

---

**Nota**: Este sistema está diseñado para uso interno y requiere credenciales válidas del portal de Puyehue. 