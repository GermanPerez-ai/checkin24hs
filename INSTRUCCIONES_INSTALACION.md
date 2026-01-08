# 🚀 Instrucciones de Instalación - Checkin24hs Web

## 📋 Prerrequisitos

Antes de ejecutar la aplicación web, necesitas instalar:

### 1. Node.js y npm
- **Descargar**: Ve a [nodejs.org](https://nodejs.org/)
- **Instalar**: Descarga la versión LTS (recomendada)
- **Verificar**: Abre una terminal y ejecuta:
  ```bash
  node --version
  npm --version
  ```

### 2. Editor de código (opcional pero recomendado)
- **Visual Studio Code**: [code.visualstudio.com](https://code.visualstudio.com/)
- **WebStorm**: [jetbrains.com/webstorm](https://www.jetbrains.com/webstorm/)

## 🛠️ Instalación de la Aplicación

### Paso 1: Instalar dependencias
```bash
npm install
```

### Paso 2: Ejecutar en modo desarrollo
```bash
npm start
```

### Paso 3: Abrir en el navegador
La aplicación se abrirá automáticamente en `http://localhost:3000`

## 📱 Funcionalidades Disponibles

### 🏠 Pantalla de Inicio
- Banner promocional con imagen de fondo
- Hoteles destacados en cards interactivas
- Navegación a búsqueda y detalles

### 🔍 Búsqueda de Hoteles
- Barra de búsqueda con filtrado en tiempo real
- Lista de hoteles con imágenes y calificaciones
- Navegación a detalles del hotel

### 🏨 Detalles del Hotel
- Imagen principal del hotel
- Información completa (descripción, ubicación, rating)
- Botón para solicitar cotización

### 💰 Sistema de Cotizaciones
- Formulario para fechas de check-in/check-out
- Selección de número de adultos y niños
- Envío de cotización (simulado)

### 👤 Perfil de Usuario
- Información personal del usuario
- Historial de búsquedas
- Opciones de edición

### ⚙️ Panel de Administración
- Gestión de hoteles
- Vista de cotizaciones pendientes
- Estadísticas básicas

## 🎨 Características de Diseño

- **Responsive**: Se adapta a móviles, tablets y desktop
- **Material Design**: Componentes modernos de Material-UI
- **Navegación inferior**: Similar a aplicaciones móviles
- **Animaciones**: Efectos hover y transiciones suaves
- **Tipografía**: Fuentes legibles y jerarquía clara

## 🔧 Scripts Disponibles

```bash
# Desarrollo
npm start          # Ejecuta en modo desarrollo
npm run build      # Construye para producción
npm test           # Ejecuta pruebas
npm run eject      # Expone configuración de webpack
```

## 🌐 Despliegue en Producción

### Opción 1: Netlify (Recomendado)
1. Sube el código a GitHub
2. Conecta tu repositorio a Netlify
3. Configura el comando de build: `npm run build`
4. Configura el directorio de publicación: `build`

### Opción 2: Vercel
1. Instala Vercel CLI: `npm i -g vercel`
2. Ejecuta: `vercel`
3. Sigue las instrucciones

### Opción 3: GitHub Pages
1. Ejecuta: `npm run build`
2. Sube la carpeta `build` a tu repositorio
3. Configura GitHub Pages

## 🐛 Solución de Problemas

### Error: "npm no se reconoce"
- **Solución**: Instala Node.js desde [nodejs.org](https://nodejs.org/)

### Error: "Cannot find module"
- **Solución**: Ejecuta `npm install` para instalar dependencias

### Error: "Port 3000 is already in use"
- **Solución**: Cambia el puerto o cierra otras aplicaciones

### Error: "Module not found"
- **Solución**: Verifica que todas las dependencias estén instaladas

## 📁 Estructura de Archivos

```
Checkin24hs/
├── public/
│   └── index.html          # HTML principal
├── src/
│   ├── data/
│   │   └── sampleData.ts   # Datos de muestra
│   ├── screens/            # Pantallas principales
│   │   ├── HomeScreen.tsx
│   │   ├── SearchScreen.tsx
│   │   ├── ProfileScreen.tsx
│   │   ├── HotelDetailScreen.tsx
│   │   ├── QuoteScreen.tsx
│   │   ├── LoginScreen.tsx
│   │   └── AdminScreen.tsx
│   ├── types/
│   │   └── index.ts        # Tipos TypeScript
│   ├── App.tsx             # Componente principal
│   └── index.tsx           # Punto de entrada
├── package.json            # Dependencias y scripts
├── tsconfig.json           # Configuración TypeScript
└── README.md               # Documentación
```

## 🔄 Comparación con la App Android

| Característica | Android (Kotlin) | Web (React) |
|----------------|------------------|-------------|
| **Lenguaje** | Kotlin | TypeScript |
| **UI Framework** | Jetpack Compose | Material-UI |
| **Navegación** | Navigation Component | React Router |
| **Estado** | State/ViewModel | React Hooks |
| **Datos** | Data Classes | TypeScript Interfaces |
| **Imágenes** | Drawable Resources | URLs externas |
| **Plataforma** | Android nativo | Web (cross-platform) |

## 🚀 Próximos Pasos

1. **Instalar Node.js** si no lo tienes
2. **Ejecutar `npm install`** para instalar dependencias
3. **Ejecutar `npm start`** para iniciar la aplicación
4. **Explorar las funcionalidades** en el navegador
5. **Personalizar** según tus necesidades

## 📞 Soporte

Si tienes problemas:
1. Verifica que Node.js esté instalado correctamente
2. Asegúrate de estar en el directorio correcto
3. Ejecuta `npm install` antes de `npm start`
4. Revisa la consola del navegador para errores

¡Disfruta explorando tu aplicación web de Checkin24hs! 🎉 