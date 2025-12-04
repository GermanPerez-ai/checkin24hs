# Checkin24hs - Panel de Administración

Panel de administración independiente para la gestión de hoteles, usuarios y cotizaciones de Checkin24hs.

## 🚀 Características

- **Dashboard** con estadísticas en tiempo real
- **Gestión de Hoteles** - CRUD completo
- **Gestión de Usuarios** - Listado y estados
- **Gestión de Cotizaciones** - Seguimiento de reservas
- **Autenticación** segura
- **Interfaz Responsiva** - Funciona en desktop y móvil

## 🛠️ Tecnologías

- **React 18** - Biblioteca de UI
- **TypeScript** - Tipado estático
- **Material-UI (MUI)** - Componentes de UI
- **React Router** - Navegación
- **Context API** - Estado global

## 📦 Instalación

```bash
# Instalar dependencias
npm install

# Iniciar en modo desarrollo
npm start

# Construir para producción
npm run build
```

## 🔐 Acceso

**Credenciales de prueba:**
- **Email:** admin@checkin24hs.com
- **Contraseña:** admin123

## 📱 Uso

1. **Iniciar sesión** con las credenciales
2. **Dashboard** - Ver estadísticas generales
3. **Hoteles** - Gestionar catálogo de hoteles
4. **Usuarios** - Administrar usuarios registrados
5. **Cotizaciones** - Revisar y gestionar reservas

## 🏗️ Estructura del Proyecto

```
src/
├── components/     # Componentes reutilizables
├── contexts/       # Contextos de React
├── screens/        # Pantallas principales
└── types/          # Definiciones de tipos
```

## 🔧 Configuración

### Variables de Entorno

Crear archivo `.env`:

```env
REACT_APP_API_URL=http://localhost:3001/api
REACT_APP_ADMIN_EMAIL=admin@checkin24hs.com
```

## 🚀 Despliegue

### Vercel (Recomendado)

```bash
# Instalar Vercel CLI
npm i -g vercel

# Desplegar
vercel
```

### Netlify

```bash
# Construir
npm run build

# Subir carpeta build/
```

## 🔒 Seguridad

- **Autenticación** requerida para todas las rutas
- **Protección de rutas** con React Router
- **Validación** de formularios
- **Sanitización** de datos

## 📈 Próximas Funcionalidades

- [ ] **Gráficos** interactivos en Dashboard
- [ ] **Notificaciones** en tiempo real
- [ ] **Exportación** de datos a Excel/PDF
- [ ] **Filtros avanzados** en tablas
- [ ] **Búsqueda** global
- [ ] **Temas** personalizables

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 📞 Soporte

Para soporte técnico, contactar a:
- **Email:** soporte@checkin24hs.com
- **Documentación:** [docs.checkin24hs.com](https://docs.checkin24hs.com) 