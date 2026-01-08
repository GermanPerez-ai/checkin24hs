# 🚀 Guía de Instalación del Dashboard en Hosting

## 📋 Información General

El dashboard de Checkin24hs es una **aplicación web estática** que funciona principalmente con HTML, CSS y JavaScript. Los datos se almacenan en el navegador usando `localStorage`, por lo que **NO requiere base de datos** ni servidor backend para funcionar básicamente.

## 🎯 Opciones de Hosting

### Opción 1: Hosting Estático (Recomendado - Más Simple)
**Ideal para:** Funcionalidad básica del dashboard
- **Netlify** (gratis)
- **Vercel** (gratis)
- **GitHub Pages** (gratis)
- **Firebase Hosting** (gratis)
- Cualquier hosting compartido con soporte para archivos estáticos

### Opción 2: Hosting con Node.js (Opcional)
**Ideal para:** Funcionalidades avanzadas (API, WhatsApp, etc.)
- **Heroku**
- **DigitalOcean**
- **AWS**
- **Hosting con Node.js** (cPanel, etc.)

---

## 📦 Archivos Necesarios para el Dashboard

### Archivos Principales (OBLIGATORIOS):
```
✅ dashboard.html          - Panel principal de administración
✅ crm.html               - Sistema CRM
✅ index.html             - Página principal para clientes
✅ cotizador-cliente.html - Sistema de cotizaciones
```

### Archivos JavaScript (OBLIGATORIOS):
```
✅ crm.js                        - Lógica del CRM
✅ dashboard-integration.js      - Integración con dashboard
✅ flor-agent.js                 - Motor de Flor (chatbot)
✅ flor-ai-service.js            - Servicio de IA
✅ flor-knowledge-base.js        - Base de conocimiento
✅ flor-learning-system.js       - Sistema de aprendizaje
✅ flor-multimodal-service.js    - Procesamiento multimedia
✅ flor-widget.js                - Widget del chatbot
```

### Archivos HTML Adicionales:
```
✅ flor-chatbot.html             - Interfaz del chatbot
```

### Carpetas y Recursos:
```
✅ hotel-images/                 - Imágenes de hoteles (OBLIGATORIA)
   ├── hotel-1-puyehue/
   ├── hotel-2-huilo-huilo/
   └── ...
✅ logo*.svg / logo.png          - Logos de la empresa
```

---

## 🚀 Instalación en Hosting Estático (Netlify/Vercel/GitHub Pages)

### Paso 1: Preparar los Archivos

1. **Crea una carpeta** con todos los archivos necesarios:
   ```
   checkin24hs-web/
   ├── dashboard.html
   ├── crm.html
   ├── index.html
   ├── cotizador-cliente.html
   ├── flor-chatbot.html
   ├── crm.js
   ├── dashboard-integration.js
   ├── flor-agent.js
   ├── flor-ai-service.js
   ├── flor-knowledge-base.js
   ├── flor-learning-system.js
   ├── flor-multimodal-service.js
   ├── flor-widget.js
   ├── hotel-images/
   └── logo*.svg
   ```

2. **Asegúrate de que las rutas en los HTML sean correctas:**
   - Si los archivos están en la raíz: `./flor-agent.js`
   - Si están en una subcarpeta: `./js/flor-agent.js`

### Paso 2: Subir a Netlify (Ejemplo)

1. **Ve a [netlify.com](https://www.netlify.com)** y crea una cuenta
2. **Arrastra y suelta** la carpeta con los archivos
3. **Netlify desplegará automáticamente** tu sitio
4. **Obtendrás una URL** como: `https://tu-proyecto.netlify.app`

### Paso 3: Configurar Dominio Personalizado (Opcional)

1. En Netlify, ve a **Site settings** → **Domain management**
2. Agrega tu dominio personalizado
3. Configura los DNS según las instrucciones

---

## 🌐 Instalación en Hosting Compartido (cPanel/FTP)

### Paso 1: Acceder al Hosting

1. **Conéctate por FTP** usando:
   - FileZilla
   - WinSCP
   - O el administrador de archivos de cPanel

2. **Navega a la carpeta pública:**
   - `public_html/` (cPanel)
   - `www/` (algunos hostings)
   - `htdocs/` (otros hostings)

### Paso 2: Subir Archivos

1. **Sube todos los archivos** manteniendo la estructura:
   ```
   public_html/
   ├── dashboard.html
   ├── crm.html
   ├── index.html
   ├── cotizador-cliente.html
   ├── flor-chatbot.html
   ├── crm.js
   ├── dashboard-integration.js
   ├── flor-agent.js
   ├── flor-ai-service.js
   ├── flor-knowledge-base.js
   ├── flor-learning-system.js
   ├── flor-multimodal-service.js
   ├── flor-widget.js
   ├── hotel-images/
   └── logo*.svg
   ```

2. **Asegúrate de que los permisos sean correctos:**
   - Archivos: `644`
   - Carpetas: `755`

### Paso 3: Verificar Funcionamiento

1. **Abre tu navegador** y ve a: `https://tudominio.com/dashboard.html`
2. **Verifica que todos los archivos se carguen** (F12 → Network)
3. **Revisa la consola** por errores (F12 → Console)

---

## 🎛️ Instalación en EasyPanel con Git (Recomendado para Actualizaciones Automáticas)

EasyPanel es un panel de control moderno que permite integrar Git y hacer **despliegues automáticos**. Esto significa que cada vez que corrijas código y hagas `git push`, el servidor se actualizará automáticamente.

### Paso 1: Configurar el Repositorio Git en EasyPanel

1. **Accede a tu cuenta de EasyPanel** y selecciona la aplicación que deseas actualizar
2. **Ve a la sección "Source" (Fuente)** en la configuración de tu aplicación
3. **Selecciona la opción "Git"** como fuente de código
4. **Proporciona la URL de tu repositorio:**
   - GitHub: `https://github.com/tu-usuario/tu-repositorio.git`
   - GitLab: `https://gitlab.com/tu-usuario/tu-repositorio.git`
   - Bitbucket: `https://bitbucket.org/tu-usuario/tu-repositorio.git`

### Paso 2: Configurar Acceso SSH (Si el Repositorio es Privado)

Si tu repositorio es privado, EasyPanel generará una clave SSH específica:

1. **EasyPanel mostrará una clave SSH pública**
2. **Copia esta clave SSH**
3. **Agrégala a tu proveedor de Git:**
   - **GitHub:** Settings → SSH and GPG keys → New SSH key
   - **GitLab:** Settings → SSH Keys → Add SSH Key
   - **Bitbucket:** Personal settings → SSH keys → Add key

### Paso 3: Habilitar Despliegue Automático (Auto Deploy)

1. **Dentro de la configuración de la aplicación**, busca la opción **"Auto Deploy"**
2. **Activa el despliegue automático**
3. **Selecciona la rama que quieres desplegar** (normalmente `main` o `master`)

### Paso 4: Flujo de Trabajo para Actualizar el Servidor

Ahora, cada vez que corrijas código, solo necesitas:

```bash
# 1. Agregar los archivos modificados
git add .

# 2. Confirmar los cambios con un mensaje descriptivo
git commit -m "Corregí el bug en dashboard.html"

# 3. Enviar los cambios al repositorio
git push
```

**¡Eso es todo!** EasyPanel detectará automáticamente los cambios y desplegará la nueva versión en el servidor.

### Paso 5: Verificar el Despliegue

1. **En EasyPanel**, verás el estado del despliegue en tiempo real
2. **Revisa los logs** si hay algún error
3. **Verifica tu sitio web** para confirmar que los cambios se aplicaron

### Ventajas de Usar Git con EasyPanel:

✅ **Actualizaciones automáticas** - No necesitas subir archivos manualmente  
✅ **Historial completo** - Puedes ver todos los cambios y hacer rollback si es necesario  
✅ **Trabajo en equipo** - Varios desarrolladores pueden trabajar sin conflictos  
✅ **Despliegues seguros** - Solo se despliegan cambios confirmados en Git  
✅ **Notificaciones** - EasyPanel te notifica del estado de cada despliegue  

### Configuración Adicional (Opcional)

Si necesitas ejecutar comandos después del despliegue (por ejemplo, instalar dependencias):

1. **En la configuración de EasyPanel**, busca **"Build Commands"** o **"Post Deploy"**
2. **Agrega comandos personalizados** si es necesario:
   ```bash
   npm install
   npm run build
   ```

---

## 🔧 Instalación con Node.js (Funcionalidades Avanzadas)

Si necesitas funcionalidades del servidor (API, WhatsApp, etc.):

### Paso 1: Preparar el Servidor

1. **Sube todos los archivos** al servidor
2. **Asegúrate de tener Node.js instalado** en el servidor

### Paso 2: Instalar Dependencias

```bash
npm install
```

### Paso 3: Configurar Variables de Entorno

Crea un archivo `.env` (si es necesario):
```env
PORT=3000
NODE_ENV=production
```

### Paso 4: Iniciar el Servidor

```bash
# Opción 1: Directamente
node server.js

# Opción 2: Con PM2 (recomendado para producción)
pm2 start server.js --name checkin24hs
pm2 save
pm2 startup
```

### Paso 5: Configurar Proxy Reverso (Nginx/Apache)

**Nginx:**
```nginx
server {
    listen 80;
    server_name tudominio.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## ⚙️ Configuración Post-Instalación

### 1. Configurar HTTPS (SSL)

**Importante:** El dashboard necesita HTTPS para algunas funcionalidades (cámara, micrófono, etc.)

- **Netlify/Vercel:** SSL automático
- **cPanel:** Usa Let's Encrypt (gratis)
- **Otros:** Configura certificado SSL

### 2. Verificar Rutas de Archivos

Abre `dashboard.html` y verifica que las rutas de los scripts sean correctas:

```html
<!-- Ejemplo correcto si están en la misma carpeta -->
<script src="./flor-agent.js"></script>
<script src="./flor-ai-service.js"></script>

<!-- Ejemplo si están en subcarpeta -->
<script src="./js/flor-agent.js"></script>
```

### 3. Configurar CORS (si es necesario)

Si tienes problemas de CORS, agrega headers en el servidor o configura en `.htaccess`:

```apache
# .htaccess
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
```

---

## 🔍 Verificación y Troubleshooting

### Checklist de Verificación:

- [ ] Todos los archivos HTML se cargan correctamente
- [ ] Los archivos JavaScript se cargan sin errores
- [ ] Las imágenes de hoteles se muestran
- [ ] El dashboard funciona (puedes ver estadísticas)
- [ ] El CRM funciona (puedes ver clientes, reservas)
- [ ] Flor (chatbot) funciona correctamente
- [ ] HTTPS está configurado

### Problemas Comunes:

**1. Archivos JavaScript no se cargan:**
- Verifica las rutas en los HTML
- Revisa la consola del navegador (F12)
- Asegúrate de que los permisos de archivos sean correctos

**2. Imágenes no se muestran:**
- Verifica que la carpeta `hotel-images/` esté subida
- Revisa las rutas en el código
- Verifica permisos de carpetas (755)

**3. localStorage no funciona:**
- Asegúrate de usar HTTPS
- Algunos navegadores bloquean localStorage en HTTP

**4. Errores de CORS:**
- Configura headers CORS en el servidor
- O usa un proxy

---

## 📝 Notas Importantes

### ⚠️ Limitaciones con localStorage:

- **Los datos se guardan en el navegador del usuario**
- **No se sincronizan entre dispositivos** automáticamente
- **Se pueden perder** si el usuario limpia el navegador

### 💡 Recomendaciones:

1. **Para producción:** Considera migrar a una base de datos real
2. **Backups:** Implementa sistema de respaldo de datos
3. **Seguridad:** Usa HTTPS siempre
4. **Performance:** Optimiza imágenes antes de subir

---

## 🆘 Soporte

Si tienes problemas durante la instalación:

1. **Revisa la consola del navegador** (F12 → Console)
2. **Verifica los logs del servidor** (si usas Node.js)
3. **Revisa los permisos de archivos**
4. **Verifica las rutas de los archivos**

---

## ✅ Listo!

Una vez completados estos pasos, tu dashboard estará funcionando en el hosting. 

**URLs típicas:**
- Dashboard: `https://tudominio.com/dashboard.html`
- CRM: `https://tudominio.com/crm.html`
- Clientes: `https://tudominio.com/index.html`

¡Éxito con tu instalación! 🎉

