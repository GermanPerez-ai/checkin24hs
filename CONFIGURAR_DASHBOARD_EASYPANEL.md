# Configurar Dashboard en EasyPanel

## ✅ EasyPanel Instalado Correctamente

EasyPanel está disponible en: **http://72.61.58.240:3000**

## Pasos para Configurar el Dashboard

### 1. Acceder a EasyPanel

1. Abre tu navegador
2. Ve a: `http://72.61.58.240:3000`
3. Crea una cuenta de administrador (primera vez)

### 2. Crear Nuevo Servicio para el Dashboard

#### Opción A: Static Site (Recomendado)

1. En EasyPanel, haz clic en **"New Project"** o **"Nuevo Proyecto"**
2. Selecciona **"Static Site"** o **"Sitio Estático"**
3. Configura:
   - **Name**: `dashboard` o `checkin24hs-dashboard`
   - **Source**: 
     - Si usas GitHub: Selecciona tu repositorio `checkin24hs`
     - Si no usas GitHub: Selecciona "Upload Files" y sube los archivos
   - **Build Command**: (dejar vacío para sitio estático)
   - **Output Directory**: `/` o dejar vacío
   - **Port**: `3001` (o el que prefieras, ya que 3000 es para EasyPanel)
   - **Domain**: `dashboard.checkin24hs.com` (opcional)

#### Opción B: Node.js (Si prefieres usar serve-dashboard.js)

1. Selecciona **"Node.js"**
2. Configura:
   - **Name**: `dashboard`
   - **Source**: Tu repositorio GitHub o archivos locales
   - **Build Command**: (dejar vacío)
   - **Start Command**: `node serve-dashboard.js`
   - **Port**: `3001`
   - **Environment Variables**: (dejar vacío o agregar `PORT=3001`)

### 3. Configurar Archivos Necesarios

Asegúrate de que estos archivos estén en el repositorio o los subas:

- `dashboard.html` (el archivo muleto.html renombrado)
- `serve-dashboard.js` (si usas Node.js)
- `supabase-client.js` (opcional)
- `supabase-config.js` (opcional)
- `logo.png` (opcional)
- Cualquier otro archivo estático necesario

### 4. Configurar para que No Requiera Login

El archivo `dashboard.html` ya tiene el código para ocultar el login. Solo asegúrate de:

1. Subir el `dashboard.html` actualizado (sin login)
2. EasyPanel lo servirá automáticamente
3. El dashboard debería aparecer directamente sin login

### 5. Configurar Dominio (Opcional)

Si quieres usar un dominio:

1. En EasyPanel, ve a la configuración del servicio
2. Agrega un dominio: `dashboard.checkin24hs.com`
3. Configura el DNS para que apunte a `72.61.58.240`

## Ventajas de EasyPanel

- ✅ Interfaz web fácil de usar
- ✅ Auto-deploy desde GitHub (si lo configuras)
- ✅ Gestión de contenedores Docker automática
- ✅ SSL/HTTPS automático (si configuras dominio)
- ✅ Logs y monitoreo integrados
- ✅ Fácil de actualizar y mantener

## Comandos Útiles

```bash
# Ver servicios de EasyPanel
docker ps | grep easypanel

# Ver logs de EasyPanel
docker logs easypanel --tail 50

# Ver servicios creados en EasyPanel
# (desde la interfaz web de EasyPanel)
```

## Notas Importantes

- El puerto 3000 ahora es para EasyPanel
- El dashboard debería correr en otro puerto (3001, 3002, etc.)
- O usar un dominio y dejar que EasyPanel maneje el routing
- Los cambios se aplican automáticamente si configuras auto-deploy desde GitHub


