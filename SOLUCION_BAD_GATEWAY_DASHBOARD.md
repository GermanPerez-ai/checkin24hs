# 🔧 Solución: Error 502 Bad Gateway en Dashboard

## 🎯 Problema

El dashboard (`dashboard.checkin24hs.com`) muestra **502 Bad Gateway**, lo que significa que el proxy/gateway (Traefik/Nginx) no puede comunicarse con el servicio backend del dashboard.

## 🔍 Diagnóstico Paso a Paso

### Paso 1: Verificar el Servicio en EasyPanel

1. **Abre EasyPanel** y ve a tu proyecto
2. **Busca el servicio del dashboard** (puede llamarse `dashboard`, `crm`, `checkin24hs-dashboard`, etc.)
3. **Verifica el estado**:
   - 🟢 **Verde** = Servicio corriendo (pero puede haber problema de puerto/configuración)
   - 🟡 **Amarillo** = Servicio iniciando (espera 2-3 minutos)
   - 🔴 **Rojo** = Servicio detenido o con error

### Paso 2: Revisar los Logs del Servicio

1. Haz clic en el servicio del dashboard
2. Ve a la pestaña **"Logs"** o **"Registros"**
3. Busca mensajes como:
   - `🚀 Servidor iniciado en http://0.0.0.0:3000` → ✅ Servicio funcionando
   - `Error: Port already in use` → ❌ Puerto ocupado
   - `Cannot find module` → ❌ Dependencias faltantes
   - `Killed` → ❌ Sin memoria suficiente
   - `EADDRINUSE` → ❌ Puerto ya en uso

### Paso 3: Verificar la Configuración del Puerto

1. En el servicio del dashboard, ve a **"Puertos"** o **"Ports"**
2. Verifica:
   - **Puerto interno**: Debe ser `3000` (o el que usa `server.js`)
   - **Protocolo**: `HTTP` o `TCP`
   - **Dominio**: `dashboard.checkin24hs.com` debe estar configurado

### Paso 4: Verificar Variables de Entorno

1. Ve a **"Variables de Entorno"** o **"Environment Variables"**
2. Verifica que exista:
   ```
   PORT=3000
   ```
   Si no existe, agrégalo.

## ✅ Soluciones

### Solución 1: El Servicio No Está Corriendo

**Síntomas**: Punto rojo en EasyPanel o servicio detenido

**Pasos**:
1. Ve a **"Registros"** y copia los últimos mensajes
2. Si ves errores de dependencias:
   - Verifica que la **ruta de compilación** sea correcta (debe apuntar a la raíz del proyecto)
   - El servicio debería instalar dependencias automáticamente
3. Si ves "Port already in use":
   - Cambia el puerto interno a `3001` o `3002`
   - Agrega variable de entorno: `PORT=3001`
   - Actualiza la configuración del dominio
4. **Reinicia el servicio** (botón refresh o "Restart")

### Solución 2: El Puerto No Coincide

**Síntomas**: Servicio verde pero sigue 502

**Pasos**:
1. Verifica qué puerto usa `server.js`:
   - Por defecto es `3000`
   - O el definido en `PORT` (variable de entorno)
2. En EasyPanel, verifica que el **puerto interno** coincida con el puerto del servicio
3. Si no coincide:
   - Cambia el puerto interno en EasyPanel al puerto correcto (3000)
   - O agrega variable de entorno: `PORT=3000`
4. **Guarda** y **reinicia** el servicio
5. **Espera 2-3 minutos** para que el servicio termine de iniciar

### Solución 3: El Servicio Está Iniciando

**Síntomas**: Punto amarillo, logs muestran "Starting..." o "Building..."

**Pasos**:
1. **Espera 2-3 minutos** para que el servicio termine de iniciar
2. **Actualiza la página** del dashboard
3. Si después de 3 minutos sigue 502, ve a Solución 1 o 2

### Solución 4: Falta Memoria

**Síntomas**: Logs muestran "Killed" o el servicio se reinicia constantemente

**Pasos**:
1. Ve a **"Recursos"** o **"Resources"** del servicio
2. **Aumenta la memoria** a `1024 MB` (1 GB) o `2048 MB` (2 GB)
3. **Guarda** y **reinicia** el servicio

### Solución 5: Archivos Faltantes o Ruta Incorrecta

**Síntomas**: Logs muestran "Cannot find module" o "File not found"

**Pasos**:
1. Verifica que el **comando de inicio** sea correcto:
   ```bash
   node server.js
   ```
2. Verifica que la **ruta de compilación** sea correcta:
   - Debe apuntar a la carpeta raíz del proyecto (donde está `server.js`)
   - Si está en GitHub, verifica que la **ruta de compilación** sea `/` o vacía
3. Si usas GitHub, verifica que el **repositorio** y **rama** sean correctos:
   - **Propietario**: `GermanPerez-ai`
   - **Repositorio**: `checkin24hs`
   - **Rama**: `main`
   - **Ruta de compilación**: `/` (raíz)

### Solución 6: Problema con el Proxy (Traefik/Nginx)

**Síntomas**: Servicio verde, puerto correcto, pero sigue 502

**Pasos**:
1. Verifica que el **dominio** esté configurado correctamente:
   - En EasyPanel, ve a **"Dominios"** o **"Domains"**
   - Verifica que `dashboard.checkin24hs.com` esté configurado
   - Verifica que apunte al puerto correcto (3000)
2. Si el dominio no está configurado:
   - Agrega el dominio `dashboard.checkin24hs.com`
   - Configura el puerto interno: `3000`
   - Guarda y espera 2-3 minutos

## 🔧 Configuración Correcta del Dashboard

### Variables de Entorno

```env
PORT=3000
NODE_ENV=production
```

### Puerto Interno

- **Puerto interno**: `3000`
- **Protocolo**: `HTTP` o `TCP`

### Comando de Inicio

```bash
node server.js
```

### Ruta de Compilación

- Si `server.js` está en la raíz: `/` o dejar vacío
- Si está en una subcarpeta: `/ruta/a/la/carpeta`

### Configuración de Fuente (GitHub)

- **Propietario**: `GermanPerez-ai`
- **Repositorio**: `checkin24hs`
- **Rama**: `main`
- **Ruta de compilación**: `/` (raíz)

## 📋 Checklist de Verificación

Antes de reportar el problema, verifica:

- [ ] El servicio está en verde (Running) en EasyPanel
- [ ] Los logs muestran "🚀 Servidor iniciado en http://0.0.0.0:3000" (o el puerto configurado)
- [ ] El puerto interno en EasyPanel coincide con el puerto del servicio (3000)
- [ ] El dominio `dashboard.checkin24hs.com` está configurado correctamente
- [ ] No hay errores en los logs
- [ ] El servicio tiene suficiente memoria (mínimo 512 MB, recomendado 1024 MB)
- [ ] La variable de entorno `PORT=3000` está configurada
- [ ] El comando de inicio es `node server.js`
- [ ] La ruta de compilación es correcta (`/` si `server.js` está en la raíz)

## 🚀 Pasos de Solución Rápida

1. **Abre EasyPanel** → Proyecto → Servicio del dashboard
2. **Verifica el estado** (verde/amarillo/rojo)
3. **Revisa los logs** (últimas 50 líneas)
4. **Verifica el puerto interno** (debe ser 3000)
5. **Verifica las variables de entorno** (debe tener `PORT=3000`)
6. **Verifica el dominio** (`dashboard.checkin24hs.com` debe estar configurado)
7. **Reinicia el servicio** si es necesario
8. **Espera 2-3 minutos** si está iniciando
9. **Intenta acceder** a `dashboard.checkin24hs.com` de nuevo

## 🆘 Si Nada Funciona

### Opción 1: Probar Acceso Directo al Puerto

1. Prueba acceder directamente al puerto:
   - `http://72.61.58.240:3000` (si el puerto está expuesto)
   - Si funciona, el problema es la configuración del dominio/proxy
   - Si no funciona, el problema es el servicio

### Opción 2: Recrear el Servicio

1. **Copia la configuración actual** (variables, puertos, comando)
2. **Elimina el servicio** del dashboard
3. **Crea un nuevo servicio** con el mismo nombre
4. **Configura todo de nuevo**:
   - Fuente (GitHub)
   - Variables de entorno (`PORT=3000`)
   - Puerto interno (3000)
   - Comando de inicio (`node server.js`)
   - Dominio (`dashboard.checkin24hs.com`)
5. **Implementa** el servicio
6. **Espera 2-3 minutos** para que inicie

### Opción 3: Verificar DNS

1. Verifica que el DNS apunte correctamente:
   ```bash
   nslookup dashboard.checkin24hs.com
   ```
2. Debe apuntar a la IP del servidor (72.61.58.240)

## 💡 Notas Importantes

- El dashboard puede servir archivos estáticos (`dashboard.html`) o usar un servidor Node.js (`server.js`)
- Si usas `server.js`, necesitas el servicio corriendo en EasyPanel
- Si solo sirves `dashboard.html`, puedes usar un servicio estático o Nginx directamente
- El error 502 generalmente significa que el proxy no puede comunicarse con el backend
- Si el servicio está en amarillo, espera 2-3 minutos antes de preocuparte

## 📞 Información para Soporte

Si necesitas ayuda adicional, proporciona:

1. **Estado del servicio** en EasyPanel (verde/amarillo/rojo)
2. **Últimas 50 líneas de logs** del servicio
3. **Configuración de puertos** (puerto interno, protocolo)
4. **Variables de entorno** configuradas
5. **Configuración del dominio** (si está configurado)
6. **Resultado de acceso directo** al puerto (si es posible)

