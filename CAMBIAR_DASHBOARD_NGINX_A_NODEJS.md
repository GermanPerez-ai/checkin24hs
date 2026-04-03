# 🔧 Solución: Cambiar Dashboard de Nginx a Node.js

## 🎯 Problema Identificado

Los logs muestran que el servicio del dashboard está ejecutando **Nginx** en lugar de **Node.js**. El dashboard necesita ejecutar `server.js` para funcionar correctamente.

**Logs actuales muestran:**
```
nginx/1.29.4
start worker processes
```

**Deberían mostrar:**
```
🚀 Servidor iniciado en http://0.0.0.0:3000
```

## ✅ Solución: Cambiar la Configuración del Servicio

### Paso 1: Verificar el Tipo de Servicio

1. En EasyPanel, haz clic en el servicio del dashboard
2. Ve a **"Fuente"** o **"Source"**
3. Verifica qué tipo de servicio está configurado:
   - Si dice "Nginx" o "Static" → Necesitas cambiarlo
   - Si dice "Node.js" o "Custom" → Verifica el comando de inicio

### Paso 2: Cambiar a Node.js (Si está como Nginx/Static)

#### Opción A: Si puedes cambiar el tipo de servicio

1. En EasyPanel, haz clic en el servicio del dashboard
2. Busca la opción **"Tipo de Servicio"** o **"Service Type"**
3. Cambia de **"Nginx"** o **"Static"** a **"Node.js"** o **"Custom"**
4. **Guarda** los cambios

#### Opción B: Si no puedes cambiar el tipo (más común)

1. **Elimina el servicio actual** del dashboard
2. **Crea un nuevo servicio** con el nombre `dashboard` (o el que tenías)
3. Configura el nuevo servicio como **Node.js**

### Paso 3: Configurar el Nuevo Servicio Node.js

#### 3.1. Configurar la Fuente (GitHub)

1. Ve a **"Fuente"** o **"Source"**
2. Configura:
   - **Propietario**: `GermanPerez-ai`
   - **Repositorio**: `checkin24hs`
   - **Rama**: `main`
   - **Ruta de compilación**: `/` (raíz, donde está `server.js`)
3. **Guarda** los cambios

#### 3.2. Configurar Variables de Entorno

1. Ve a **"Variables de Entorno"** o **"Environment Variables"**
2. Agrega:
   ```
   PORT=3000
   NODE_ENV=production
   ```
3. **Guarda** los cambios

#### 3.3. Configurar Puerto Interno

1. Ve a **"Puertos"** o **"Ports"**
2. Configura:
   - **Puerto interno**: `3000`
   - **Protocolo**: `HTTP` o `TCP`
3. **Guarda** los cambios

#### 3.4. Configurar Comando de Inicio

1. Ve a **"Compilación"** o **"Build"**
2. En **"Comando de Inicio"** o **"Start Command"**, ingresa:
   ```bash
   node server.js
   ```
3. **Guarda** los cambios

#### 3.5. Configurar el Dominio

1. Ve a **"Dominios"** o **"Domains"**
2. Agrega el dominio: `dashboard.checkin24hs.com`
3. Configura el puerto: `3000` (debe coincidir con el puerto interno)
4. **Guarda** los cambios

### Paso 4: Implementar el Servicio

1. Ve a **"Implementaciones"** o busca el botón **"Implementar"**
2. Haz clic en **"Implementar"** o **"Deploy"**
3. **Espera 2-3 minutos** para que el servicio se implemente
4. El servicio debe ponerse en **verde (Running)**

### Paso 5: Verificar los Logs

1. Haz clic en el servicio del dashboard
2. Ve a **"Logs"** o **"Registros"**
3. Deberías ver:
   ```
   🚀 Servidor iniciado en http://0.0.0.0:3000
   📊 API disponible en http://0.0.0.0:3000/api/puyehue-quote
   🌐 Frontend disponible en http://0.0.0.0:3000
   ```
4. Si ves estos mensajes, el servicio está funcionando correctamente

## 📋 Configuración Completa del Servicio

### Resumen de Configuración:

| Sección | Configuración |
|---------|---------------|
| **Tipo de Servicio** | Node.js o Custom |
| **Fuente** | GitHub: `GermanPerez-ai/checkin24hs` (rama: `main`) |
| **Ruta de Compilación** | `/` (raíz) |
| **Variables de Entorno** | `PORT=3000`, `NODE_ENV=production` |
| **Puerto Interno** | `3000` |
| **Comando de Inicio** | `node server.js` |
| **Dominio** | `dashboard.checkin24hs.com` (puerto: `3000`) |

## 🔍 Verificación Final

Después de configurar todo:

1. ✅ El servicio está en **verde (Running)**
2. ✅ Los logs muestran `🚀 Servidor iniciado en http://0.0.0.0:3000`
3. ✅ El puerto interno es `3000`
4. ✅ El dominio `dashboard.checkin24hs.com` está configurado con puerto `3000`
5. ✅ Puedes acceder a `dashboard.checkin24hs.com` sin error 502

## 🆘 Si el Servicio No Inicia

### Error: "Cannot find module"

**Solución:**
1. Verifica que la **ruta de compilación** sea `/` (raíz)
2. Verifica que el archivo `server.js` esté en la raíz del repositorio
3. El servicio debería instalar dependencias automáticamente

### Error: "Port already in use"

**Solución:**
1. Verifica que no haya otro servicio usando el puerto 3000
2. O cambia el puerto a `3001` y actualiza todas las configuraciones

### El servicio sigue mostrando logs de Nginx

**Solución:**
1. Asegúrate de haber **eliminado el servicio anterior** completamente
2. Crea un **nuevo servicio** desde cero
3. Verifica que el **tipo de servicio** sea Node.js, no Nginx

## 💡 Notas Importantes

- El dashboard **debe** ejecutar Node.js con `server.js` para funcionar correctamente
- Nginx solo sirve archivos estáticos, pero el dashboard necesita el servidor Node.js para las APIs
- Después de cambiar la configuración, espera 2-3 minutos para que el servicio termine de iniciar
- Si el servicio está en amarillo, espera a que termine de iniciar antes de preocuparte

## 🚀 Pasos Rápidos

1. **Elimina** el servicio actual del dashboard (si está como Nginx)
2. **Crea** un nuevo servicio Node.js llamado `dashboard`
3. **Configura**:
   - Fuente: GitHub `GermanPerez-ai/checkin24hs` (rama `main`)
   - Ruta: `/`
   - Variables: `PORT=3000`, `NODE_ENV=production`
   - Puerto: `3000`
   - Comando: `node server.js`
   - Dominio: `dashboard.checkin24hs.com` (puerto `3000`)
4. **Implementa** el servicio
5. **Espera 2-3 minutos**
6. **Verifica** los logs (deben mostrar Node.js, no Nginx)
7. **Prueba** acceder a `dashboard.checkin24hs.com`

