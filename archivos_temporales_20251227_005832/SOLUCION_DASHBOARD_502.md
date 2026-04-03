# 🔧 Solución: Error 502 Bad Gateway en Dashboard

## 🎯 Problema

El dashboard (`dashboard.checkin24hs.com`) muestra **502 Bad Gateway**, lo que significa que el proxy/gateway no puede comunicarse con el servicio backend del dashboard.

## 🔍 Diagnóstico Rápido

### Paso 1: Verificar el Servicio en EasyPanel

1. **Abre EasyPanel** y ve a tu proyecto
2. **Busca el servicio del dashboard** (puede llamarse `dashboard`, `crm`, `checkin24hs-dashboard`, etc.)
3. **Verifica el estado**:
   - 🟢 **Verde** = Servicio corriendo (pero puede haber problema de puerto)
   - 🟡 **Amarillo** = Servicio iniciando (espera 2-3 minutos)
   - 🔴 **Rojo** = Servicio detenido o con error

### Paso 2: Verificar los Logs

1. Haz clic en el servicio del dashboard
2. Ve a la pestaña **"Logs"** o **"Registros"**
3. Busca mensajes como:
   - `Server started on port 3000` → ✅ Servicio funcionando
   - `Error: Port already in use` → ❌ Puerto ocupado
   - `Cannot find module` → ❌ Dependencias faltantes
   - `Killed` → ❌ Sin memoria suficiente

### Paso 3: Verificar la Configuración del Puerto

1. En el servicio del dashboard, ve a **"Dominios"** o **"Ports"**
2. Verifica:
   - **Puerto interno**: Debe ser `3000` (o el que usa `server.js`)
   - **Protocolo**: `HTTP`
   - **Dominio**: `dashboard.checkin24hs.com`

## ✅ Soluciones

### Solución 1: El Servicio No Está Corriendo

**Síntomas**: Punto rojo en EasyPanel

**Pasos**:
1. Ve a **"Registros"** y copia los últimos mensajes
2. Si ves errores de dependencias:
   ```bash
   # En la terminal del servicio
   npm install
   ```
3. Si ves "Port already in use":
   - Cambia el puerto interno a `3001` o `3002`
   - Actualiza la configuración del dominio
4. **Reinicia el servicio** (botón refresh o "Restart")

### Solución 2: El Puerto No Coincide

**Síntomas**: Servicio verde pero sigue 502

**Pasos**:
1. Verifica qué puerto usa `server.js`:
   - Por defecto es `3000`
   - O el definido en `PORT` (variable de entorno)
2. En EasyPanel, verifica que el **puerto interno** coincida
3. Si no coincide:
   - Cambia el puerto interno en EasyPanel al puerto correcto
   - O agrega variable de entorno: `PORT=3000`
4. **Guarda** y **reinicia** el servicio

### Solución 3: El Servicio Está Iniciando

**Síntomas**: Punto amarillo, logs muestran "Starting..."

**Pasos**:
1. **Espera 2-3 minutos** para que el servicio termine de iniciar
2. **Actualiza la página** del dashboard
3. Si después de 3 minutos sigue 502, ve a Solución 1 o 2

### Solución 4: Falta Memoria

**Síntomas**: Logs muestran "Killed" o el servicio se reinicia constantemente

**Pasos**:
1. Ve a **"Recursos"** del servicio
2. **Aumenta la memoria** a `1024 MB` (1 GB) o `2048 MB` (2 GB)
3. **Guarda** y **reinicia** el servicio

### Solución 5: Archivos Faltantes

**Síntomas**: Logs muestran "Cannot find module" o "File not found"

**Pasos**:
1. Verifica que el **comando de inicio** sea correcto:
   ```bash
   node server.js
   ```
2. Verifica que la **ruta de compilación** sea correcta:
   - Debe apuntar a la carpeta raíz del proyecto
   - O a la carpeta donde está `server.js`
3. Si usas GitHub, verifica que el **repositorio** y **rama** sean correctos

## 🔧 Configuración Correcta del Dashboard

### Variables de Entorno

```env
PORT=3000
NODE_ENV=production
```

### Puerto Interno

- **Puerto interno**: `3000`
- **Protocolo**: `HTTP`

### Comando de Inicio

```bash
node server.js
```

### Ruta de Compilación

- Si `server.js` está en la raíz: `/` o dejar vacío
- Si está en una subcarpeta: `/ruta/a/la/carpeta`

## 📋 Checklist de Verificación

- [ ] El servicio está en verde (Running) en EasyPanel
- [ ] Los logs muestran "Server started on port 3000" (o el puerto configurado)
- [ ] El puerto interno en EasyPanel coincide con el puerto del servicio (3000)
- [ ] El dominio `dashboard.checkin24hs.com` está configurado correctamente
- [ ] No hay errores en los logs
- [ ] El servicio tiene suficiente memoria (mínimo 512 MB)

## 🚀 Pasos de Solución Rápida

1. **Abre EasyPanel** → Proyecto → Servicio del dashboard
2. **Verifica el estado** (verde/amarillo/rojo)
3. **Revisa los logs** (últimas 50 líneas)
4. **Verifica el puerto interno** (debe ser 3000)
5. **Reinicia el servicio** si es necesario
6. **Espera 2-3 minutos** si está iniciando
7. **Intenta acceder** a `dashboard.checkin24hs.com` de nuevo

## 🆘 Si Nada Funciona

1. **Copia los logs completos** del servicio
2. **Toma captura** de la configuración del servicio (puertos, variables)
3. **Verifica** que el archivo `server.js` exista y tenga el código correcto
4. **Prueba acceder directamente** al puerto:
   - `http://72.61.58.240:3000` (si el puerto está expuesto)
   - Si funciona, el problema es la configuración del dominio
   - Si no funciona, el problema es el servicio

## 💡 Nota Importante

El dashboard puede servir archivos estáticos (`dashboard.html`) o usar un servidor Node.js (`server.js`). Verifica cuál estás usando:

- **Si usas `server.js`**: Necesitas el servicio corriendo en EasyPanel
- **Si solo sirves `dashboard.html`**: Puedes usar un servicio estático o Nginx directamente

