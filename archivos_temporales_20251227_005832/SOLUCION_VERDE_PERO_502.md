# 🔧 Solución: Servicio Verde pero Error 502 Bad Gateway

## 🎯 Problema

El servicio del dashboard está **🟢 verde (Running)** en EasyPanel, pero `dashboard.checkin24hs.com` sigue mostrando **502 Bad Gateway**.

## ✅ Esto Significa

- ✅ El servicio backend está corriendo
- ❌ El proxy (Traefik/Nginx) no puede comunicarse con el servicio
- ⚠️ **Problema de configuración del dominio o puerto**

## 🔍 Diagnóstico Paso a Paso

### Paso 1: Verificar los Logs del Servicio

1. En EasyPanel, haz clic en el servicio del dashboard
2. Ve a **"Logs"** o **"Registros"**
3. Busca el mensaje que indica en qué puerto está escuchando:
   - Deberías ver: `🚀 Servidor iniciado en http://0.0.0.0:3000`
   - O: `Server started on port 3000`
   - **Anota el puerto** que aparece (probablemente 3000)

### Paso 2: Verificar la Configuración del Dominio

**Este es el paso más importante:**

1. En EasyPanel, haz clic en el servicio del dashboard
2. Ve a la sección **"Dominios"** o **"Domains"**
3. Busca el dominio `dashboard.checkin24hs.com`
4. **Verifica el puerto configurado**:
   - Debe ser el mismo puerto que aparece en los logs (generalmente `3000`)
   - **NO debe ser** un puerto diferente (como 80, 8080, etc.)

### Paso 3: Verificar el Puerto Interno del Servicio

1. En el servicio del dashboard, ve a **"Puertos"** o **"Ports"**
2. Verifica el **puerto interno**:
   - Debe ser `3000` (o el que aparece en los logs)
   - El protocolo debe ser `HTTP` o `TCP`

### Paso 4: Verificar Variables de Entorno

1. Ve a **"Variables de Entorno"** o **"Environment Variables"**
2. Verifica que exista:
   ```
   PORT=3000
   ```
   Si no existe, agrégalo.

## ✅ Soluciones

### Solución 1: El Puerto del Dominio No Coincide (MÁS COMÚN)

**Síntomas**: Servicio verde, pero el puerto en "Dominios" es diferente al puerto del servicio

**Pasos**:

1. **Abre EasyPanel** → Servicio del dashboard → **"Dominios"**
2. **Haz clic en el dominio** `dashboard.checkin24hs.com`
3. **Verifica el puerto**:
   - Si el servicio está escuchando en `3000` (según los logs)
   - El puerto en "Dominios" **DEBE ser** `3000`
4. **Si el puerto es diferente** (como 80, 8080, etc.):
   - **Cámbialo a `3000`**
   - **Guarda** los cambios
   - **Espera 10-15 segundos**
   - **Actualiza** la página del dashboard

**IMPORTANTE**: En EasyPanel, el puerto en "Dominios" debe ser el **puerto interno** donde el servicio está escuchando, no un puerto externo.

### Solución 2: El Dominio No Está Configurado

**Síntomas**: El servicio está verde, pero no hay dominio configurado

**Pasos**:

1. En EasyPanel, ve a **"Dominios"** o **"Domains"**
2. Haz clic en **"+ Agregar Dominio"** o **"Add Domain"**
3. Ingresa: `dashboard.checkin24hs.com`
4. Configura el puerto: `3000` (o el puerto que aparece en los logs)
5. **Guarda** los cambios
6. **Espera 10-15 segundos**
7. **Actualiza** la página del dashboard

### Solución 3: El Puerto Interno No Coincide

**Síntomas**: El puerto interno del servicio es diferente al puerto en los logs

**Pasos**:

1. Revisa los logs para ver en qué puerto está escuchando realmente
2. Ve a **"Puertos"** o **"Ports"** del servicio
3. Verifica que el **puerto interno** coincida con el puerto de los logs
4. Si no coincide:
   - Cambia el puerto interno al puerto correcto
   - O agrega/cambia la variable de entorno `PORT=3000`
5. **Guarda** y **reinicia** el servicio
6. **Espera 2-3 minutos** para que reinicie
7. **Actualiza** la página del dashboard

### Solución 4: El Servicio Está Escuchando en un Puerto Diferente

**Síntomas**: Los logs muestran un puerto diferente a 3000

**Pasos**:

1. Revisa los logs para ver el puerto exacto
2. Si el puerto es diferente (por ejemplo, 3001, 3010, etc.):
   - **Opción A**: Actualiza la configuración del dominio para usar ese puerto
   - **Opción B**: Agrega variable de entorno `PORT=3000` y reinicia
3. **Guarda** y **reinicia** el servicio
4. **Actualiza** la configuración del dominio
5. **Espera 2-3 minutos**
6. **Actualiza** la página del dashboard

## 📋 Checklist de Verificación

Antes de reportar el problema, verifica:

- [ ] Los logs muestran en qué puerto está escuchando el servicio
- [ ] El puerto en "Dominios" coincide con el puerto de los logs
- [ ] El puerto interno del servicio coincide con el puerto de los logs
- [ ] La variable de entorno `PORT` está configurada (si es necesaria)
- [ ] El dominio `dashboard.checkin24hs.com` está configurado en EasyPanel
- [ ] Has esperado 10-15 segundos después de cambiar la configuración
- [ ] Has actualizado la página del dashboard (Ctrl+F5 para limpiar caché)

## 🚀 Pasos de Solución Rápida

1. **Abre EasyPanel** → Servicio del dashboard
2. **Revisa los logs** → Anota el puerto que aparece (ej: 3000)
3. **Ve a "Dominios"** → Haz clic en `dashboard.checkin24hs.com`
4. **Verifica el puerto** → Debe ser el mismo que en los logs
5. **Si es diferente, cámbialo** → Guarda los cambios
6. **Espera 10-15 segundos**
7. **Actualiza la página** del dashboard (Ctrl+F5)

## 🎯 Ejemplo de Configuración Correcta

### Configuración del Servicio:
- **Puerto interno**: `3000`
- **Variable de entorno**: `PORT=3000`
- **Comando de inicio**: `node server.js`
- **Logs muestran**: `🚀 Servidor iniciado en http://0.0.0.0:3000`

### Configuración del Dominio:
- **Dominio**: `dashboard.checkin24hs.com`
- **Puerto**: `3000` ← **DEBE coincidir con el puerto del servicio**
- **Protocolo**: `HTTP`

## 🆘 Si Nada Funciona

### Opción 1: Probar Acceso Directo

1. Intenta acceder directamente al puerto:
   - `http://72.61.58.240:3000` (reemplaza 3000 con el puerto de los logs)
   - Si funciona, el problema es la configuración del dominio
   - Si no funciona, el problema es el servicio

### Opción 2: Recrear el Dominio

1. En EasyPanel, **elimina** el dominio `dashboard.checkin24hs.com`
2. **Espera 10 segundos**
3. **Crea el dominio de nuevo**:
   - Dominio: `dashboard.checkin24hs.com`
   - Puerto: `3000` (o el puerto de los logs)
4. **Guarda** y **espera 10-15 segundos**
5. **Actualiza** la página del dashboard

### Opción 3: Reiniciar el Servicio

1. En EasyPanel, **detén** el servicio del dashboard
2. **Espera 10 segundos**
3. **Inicia** el servicio de nuevo
4. **Espera 2-3 minutos** para que termine de iniciar
5. **Verifica los logs** para confirmar el puerto
6. **Actualiza** la configuración del dominio si es necesario
7. **Actualiza** la página del dashboard

## 💡 Notas Importantes

- El puerto en "Dominios" debe ser el **puerto interno** donde el servicio está escuchando
- No confundas el puerto interno con el puerto externo
- Después de cambiar la configuración, espera 10-15 segundos antes de probar
- Limpia la caché del navegador (Ctrl+F5) si es necesario
- El servicio puede tardar 2-3 minutos en iniciar completamente

## 📞 Información para Soporte

Si necesitas ayuda adicional, proporciona:

1. **Puerto que aparece en los logs** (ej: 3000)
2. **Puerto configurado en "Dominios"** (ej: 80, 3000, etc.)
3. **Puerto interno del servicio** (ej: 3000)
4. **Variable de entorno PORT** (si está configurada)
5. **Últimas 20 líneas de logs** del servicio
6. **Resultado de acceso directo** al puerto (si es posible)

