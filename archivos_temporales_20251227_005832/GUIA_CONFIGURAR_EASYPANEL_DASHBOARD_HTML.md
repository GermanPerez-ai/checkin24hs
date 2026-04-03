# 🚀 Guía: Configurar Dashboard HTML en EasyPanel

## 🎯 Objetivo

Configurar EasyPanel para servir `dashboard.html` (que ahora es `muleto.html`) como un archivo HTML estático.

---

## 📋 Opción 1: Servir como Archivo Estático con Nginx (Recomendado)

Esta es la opción más simple si EasyPanel tiene soporte para archivos estáticos.

### Paso 1: Acceder a EasyPanel

1. Abre tu navegador y ve a EasyPanel
2. Inicia sesión con tus credenciales
3. Busca el proyecto **"checkin24hs"**
4. Ve al servicio **"dashboard"** (o créalo si no existe)

### Paso 2: Configurar la Fuente

1. Ve a la sección **"Fuente"** o **"Source"**
2. Configura:
   - **Propietario**: `GermanPerez-ai`
   - **Repositorio**: `checkin24hs`
   - **Rama**: `main`
   - **Ruta de compilación**: `/` (raíz del proyecto)

3. **Guarda** los cambios

### Paso 3: Configurar como Servicio Estático

1. Ve a **"Compilación"** o **"Build"**
2. Configura:
   - **Tipo de servicio**: **"Static"** o **"Nginx"** (si está disponible)
   - **Carpeta raíz**: `/` (raíz del proyecto)
   - **Archivo principal**: `dashboard.html`
   - **Comando de inicio**: (déjalo vacío o usa un servidor estático)

### Paso 4: Configurar el Dominio

1. Ve a **"Dominios"**
2. Configura:
   - **Dominio**: `dashboard.checkin24hs.com`
   - **Puerto**: `80` (HTTP) o `443` (HTTPS)
   - **Ruta**: `/dashboard.html` o `/` (según configuración)

3. **Guarda** los cambios

### Paso 5: Implementar

1. Haz clic en **"Implementar"** o **"Deploy"**
2. Espera 1-2 minutos
3. Verifica que el servicio esté en verde

---

## 📋 Opción 2: Servir con Node.js y Express (Alternativa)

Si EasyPanel no tiene soporte directo para archivos estáticos, puedes usar un servidor Express simple.

### Paso 1: Crear servidor Express

Crea un archivo `serve-dashboard.js` en la raíz del proyecto:

```javascript
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Servir archivos estáticos desde la raíz
app.use(express.static(__dirname));

// Servir dashboard.html como página principal
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// También servir dashboard.html directamente
app.get('/dashboard.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Dashboard corriendo en http://0.0.0.0:${PORT}`);
});
```

### Paso 2: Crear package.json para el servidor

Crea o actualiza `package.json` en la raíz del proyecto:

```json
{
  "name": "checkin24hs-dashboard",
  "version": "1.0.0",
  "description": "Dashboard HTML para Checkin24hs",
  "main": "serve-dashboard.js",
  "scripts": {
    "start": "node serve-dashboard.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### Paso 3: Configurar en EasyPanel

1. **Fuente**: GitHub `GermanPerez-ai/checkin24hs` (rama `main`)
2. **Ruta de compilación**: `/` (raíz)
3. **Comando de build**: `npm install`
4. **Comando de inicio**: `node serve-dashboard.js`
5. **Puerto interno**: `3000`
6. **Variables de entorno**: `PORT=3000`
7. **Dominio**: `dashboard.checkin24hs.com` (puerto `3000`)

### Paso 4: Implementar

1. Haz clic en **"Implementar"**
2. Espera 2-3 minutos mientras instala dependencias
3. Verifica que el servicio esté en verde

---

## 📋 Opción 3: Usar un Servidor HTTP Simple (Más Simple)

Si prefieres algo más simple, puedes usar `http-server` o `serve`:

### Paso 1: Configurar en EasyPanel

1. **Fuente**: GitHub `GermanPerez-ai/checkin24hs` (rama `main`)
2. **Ruta de compilación**: `/` (raíz)
3. **Comando de build**: `npm install -g serve`
4. **Comando de inicio**: `serve -s . -l 3000 --single dashboard.html`
5. **Puerto interno**: `3000`
6. **Dominio**: `dashboard.checkin24hs.com` (puerto `3000`)

**Nota**: El flag `--single dashboard.html` hace que todas las rutas sirvan `dashboard.html` (útil para SPA).

---

## 🔍 Verificación

Después de configurar:

1. **Revisa los logs** en EasyPanel
   - Debe mostrar que el servidor está corriendo
   - No debe haber errores

2. **Accede al dashboard**:
   - URL: `https://dashboard.checkin24hs.com` o `http://dashboard.checkin24hs.com`
   - Debe cargar `dashboard.html`

3. **Prueba las funcionalidades**:
   - Login
   - Navegación
   - Funciones principales

---

## 🆘 Solución de Problemas

### Problema: Error 404 Not Found

**Solución**:
- Verifica que `dashboard.html` esté en la raíz del proyecto en GitHub
- Verifica que la ruta de compilación sea `/` (raíz)
- Verifica que el archivo principal esté configurado como `dashboard.html`

### Problema: Error 502 Bad Gateway

**Solución**:
- Verifica que el puerto en **"Dominios"** coincida con el puerto interno
- Verifica que el servicio esté en verde (Running)
- Espera 1-2 minutos después del despliegue
- Revisa los logs para ver errores

### Problema: El dashboard carga pero no funcionan las funciones

**Solución**:
- Abre la consola del navegador (F12)
- Revisa errores de JavaScript
- Verifica que los archivos `supabase-config.js` y `supabase-client.js` estén en la raíz
- Verifica que `logo.png` esté en la raíz

### Problema: Los archivos JavaScript no se cargan

**Solución**:
- Verifica que los archivos estén en GitHub
- Verifica que las rutas en `dashboard.html` sean relativas (no absolutas)
- Si usas Express, verifica que `express.static` esté configurado correctamente

---

## ✅ Checklist Final

Antes de considerar que está listo:

- [ ] `dashboard.html` está en la raíz del proyecto en GitHub
- [ ] Los archivos de configuración están en la raíz (`supabase-config.js`, `supabase-client.js`, `logo.png`)
- [ ] La configuración en EasyPanel está correcta (fuente, puerto, dominio)
- [ ] El servicio está en verde (Running) en EasyPanel
- [ ] Los logs muestran que el servidor está corriendo
- [ ] Puedes acceder a `dashboard.checkin24hs.com` y ver el dashboard
- [ ] Las funcionalidades principales funcionan (login, navegación, etc.)

---

## 💡 Recomendación

**Te recomiendo usar la Opción 2 (Express)** porque:
- ✅ Es más flexible
- ✅ Puedes agregar funcionalidades adicionales después
- ✅ Funciona bien con EasyPanel
- ✅ Fácil de mantener

---

## 📝 Resumen Rápido (Opción Recomendada - Express)

1. **Crea** `serve-dashboard.js` en la raíz del proyecto
2. **Crea/actualiza** `package.json` con dependencia de Express
3. **Sube** a GitHub: `git add . && git commit -m "..." && git push`
4. **Configura** EasyPanel:
   - Fuente: GitHub `GermanPerez-ai/checkin24hs` (rama `main`)
   - Ruta: `/` (raíz)
   - Build: `npm install`
   - Start: `node serve-dashboard.js`
   - Puerto: `3000`
5. **Implementa** el servicio
6. **Verifica** en `dashboard.checkin24hs.com`

---

¿Necesitas ayuda con algún paso específico? ¡Solo pregunta!

