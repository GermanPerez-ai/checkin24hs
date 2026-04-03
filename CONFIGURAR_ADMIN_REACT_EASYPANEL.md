# 🔧 Configurar checkin24hs-admin (React) en EasyPanel

## 🎯 Problema

El servicio está mostrando logs de **Nginx** pero necesitas servir la aplicación **React** (`checkin24hs-admin`). La aplicación React necesita ser construida y servida correctamente.

## ✅ Solución: Configurar el Servicio Correctamente

### Opción 1: Servir como Aplicación Estática (Recomendado)

Esta opción construye la aplicación React y la sirve con Nginx.

#### Paso 1: Configurar la Fuente

1. En EasyPanel, ve al servicio del dashboard
2. Ve a **"Fuente"** o **"Source"**
3. Configura:
   - **Propietario**: `GermanPerez-ai`
   - **Repositorio**: `checkin24hs`
   - **Rama**: `main`
   - **Ruta de compilación**: `/checkin24hs-admin` (carpeta donde está el proyecto React)
4. **Guarda** los cambios

#### Paso 2: Configurar el Build

1. Ve a **"Compilación"** o **"Build"**
2. Configura:
   - **Comando de build**: `npm install && npm run build`
   - **Carpeta de salida**: `build` (donde React genera los archivos estáticos)
   - **Comando de inicio**: (déjalo vacío o usa un servidor estático)

#### Paso 3: Configurar Variables de Entorno

1. Ve a **"Variables de Entorno"**
2. Agrega (si es necesario):
   ```
   NODE_ENV=production
   REACT_APP_API_URL=http://72.61.58.240:3001/api
   ```
3. **Guarda** los cambios

#### Paso 4: Configurar el Dominio

1. Ve a **"Dominios"**
2. Configura:
   - **Dominio**: `dashboard.checkin24hs.com`
   - **Puerto**: `80` (para Nginx estático)
   - **Ruta**: `/build` (carpeta donde están los archivos construidos)
3. **Guarda** los cambios

### Opción 2: Servir con Node.js y serve (Alternativa)

Si EasyPanel no tiene soporte para servir archivos estáticos directamente:

#### Paso 1: Configurar la Fuente

1. **Propietario**: `GermanPerez-ai`
2. **Repositorio**: `checkin24hs`
3. **Rama**: `main`
4. **Ruta de compilación**: `/checkin24hs-admin`

#### Paso 2: Configurar Variables de Entorno

```
NODE_ENV=production
PORT=3000
REACT_APP_API_URL=http://72.61.58.240:3001/api
```

#### Paso 3: Configurar el Build y Start

1. **Comando de build**: `npm install && npm run build`
2. **Comando de inicio**: `npx serve -s build -l 3000`
   - Esto instala `serve` y sirve la carpeta `build` en el puerto 3000

#### Paso 4: Configurar Puerto

1. **Puerto interno**: `3000`
2. **Protocolo**: `HTTP`

#### Paso 5: Configurar Dominio

1. **Dominio**: `dashboard.checkin24hs.com`
2. **Puerto**: `3000`

### Opción 3: Usar un Servidor Express Simple

Si las opciones anteriores no funcionan, puedes crear un servidor Express simple:

#### Crear archivo `serve-admin.js` en la raíz del proyecto:

```javascript
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Servir archivos estáticos de la carpeta build
app.use(express.static(path.join(__dirname, 'checkin24hs-admin/build')));

// Todas las rutas van al index.html (para React Router)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'checkin24hs-admin/build/index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Admin panel corriendo en http://0.0.0.0:${PORT}`);
});
```

#### Configuración en EasyPanel:

1. **Fuente**: GitHub `GermanPerez-ai/checkin24hs` (rama `main`)
2. **Ruta de compilación**: `/` (raíz)
3. **Comando de build**: `cd checkin24hs-admin && npm install && npm run build`
4. **Comando de inicio**: `node serve-admin.js`
5. **Puerto interno**: `3000`
6. **Variables de entorno**: `PORT=3000`
7. **Dominio**: `dashboard.checkin24hs.com` (puerto `3000`)

## 📋 Checklist de Configuración

- [ ] Fuente configurada (GitHub: `GermanPerez-ai/checkin24hs`)
- [ ] Ruta de compilación: `/checkin24hs-admin`
- [ ] Comando de build: `npm install && npm run build`
- [ ] Carpeta de salida: `build`
- [ ] Variables de entorno configuradas (si es necesario)
- [ ] Puerto configurado correctamente
- [ ] Dominio `dashboard.checkin24hs.com` configurado
- [ ] Servicio implementado y en verde

## 🔍 Verificación

Después de configurar:

1. **Revisa los logs** del servicio
2. Deberías ver:
   - `npm install` ejecutándose
   - `npm run build` construyendo la aplicación
   - Servidor iniciando (dependiendo de la opción elegida)
3. **Accede a** `dashboard.checkin24hs.com`
4. Deberías ver la pantalla de login del panel de administración

## 🆘 Problemas Comunes

### Error: "Cannot find module"

**Solución**: Verifica que la ruta de compilación sea `/checkin24hs-admin` y que el `package.json` esté en esa carpeta.

### Error: "Build failed"

**Solución**: 
1. Revisa los logs para ver el error específico
2. Verifica que todas las dependencias estén en `package.json`
3. Puede que necesites aumentar la memoria del servicio

### La aplicación carga pero muestra página en blanco

**Solución**:
1. Abre la consola del navegador (F12)
2. Revisa errores de JavaScript
3. Verifica que las rutas de los archivos estáticos sean correctas
4. Puede que necesites configurar la ruta base en `package.json`:
   ```json
   "homepage": "."
   ```

### Los logs siguen mostrando Nginx

**Solución**: 
1. Elimina el servicio actual
2. Crea un nuevo servicio desde cero
3. Configura como **Node.js** o **Custom**, no como **Nginx** o **Static**

## 💡 Notas Importantes

- La aplicación React necesita ser **construida** antes de servirla
- El comando `npm run build` genera la carpeta `build/` con los archivos estáticos
- Si usas React Router, necesitas configurar el servidor para que todas las rutas apunten a `index.html`
- El panel de administración usa autenticación local (no requiere backend para login básico)

## 🚀 Pasos Rápidos (Opción Recomendada)

1. **Elimina** el servicio actual del dashboard
2. **Crea** un nuevo servicio llamado `dashboard` o `admin`
3. **Configura**:
   - Tipo: **Node.js** o **Custom**
   - Fuente: GitHub `GermanPerez-ai/checkin24hs` (rama `main`)
   - Ruta: `/checkin24hs-admin`
   - Build: `npm install && npm run build`
   - Start: `npx serve -s build -l 3000`
   - Puerto: `3000`
   - Dominio: `dashboard.checkin24hs.com` (puerto `3000`)
4. **Implementa** el servicio
5. **Espera 3-5 minutos** para que construya e inicie
6. **Verifica** accediendo a `dashboard.checkin24hs.com`

