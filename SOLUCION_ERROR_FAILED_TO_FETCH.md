# 🔧 Solución: Error "Failed to fetch" al Conectar WhatsApp

## ❌ Error que Estás Viendo

```
Error: Failed to fetch
No se pudo conectar con el servidor
Verifica que el servidor esté corriendo en el puerto 3001
```

## 🎯 Causas Posibles

Este error significa que el dashboard **no puede alcanzar** el servidor de WhatsApp. Las causas más comunes son:

1. ❌ El servicio no está corriendo en EasyPanel
2. ❌ La URL del servidor está mal configurada
3. ❌ El puerto no está abierto o accesible
4. ❌ El servicio no está escuchando en el puerto correcto
5. ❌ Problemas de red/firewall

---

## ✅ Solución Paso a Paso

### Paso 1: Verificar que el Servicio Esté Corriendo en EasyPanel

1. **Abre EasyPanel**
2. **Busca el servicio `whatsapp`** (o el que corresponda a la instancia 1)
3. **Verifica el estado**:
   - ✅ Debe estar en **VERDE** (Running/Corriendo)
   - ❌ Si está en rojo o amarillo, hay un problema

4. **Si NO está corriendo**:
   - Haz clic en **"Iniciar"** o **"Start"**
   - Espera unos segundos
   - Verifica que cambie a verde

### Paso 2: Verificar los Logs del Servicio

1. **Haz clic en el servicio `whatsapp`** en EasyPanel
2. **Ve a la pestaña "Logs"** o **"Registros"**
3. **Revisa los mensajes**:
   - ✅ Deberías ver: "WhatsApp server iniciado en puerto 3001"
   - ✅ O: "Server listening on port 3001"
   - ❌ Si ves errores, anótalos

4. **Errores comunes en los logs**:
   - "Port 3001 already in use" → El puerto está ocupado
   - "Cannot find module" → Faltan dependencias
   - "INSTANCE_NUMBER is not defined" → Falta variable de entorno

### Paso 3: Verificar la URL del Servidor en el Dashboard

1. **En el Dashboard**, ve a **Flor IA → WhatsApp**
2. **Verifica el campo "URL del Servidor WhatsApp"**:
   - ✅ Debe ser: `http://72.61.58.240`
   - ❌ NO debe tener puerto al final (el sistema lo agrega automáticamente)
   - ❌ NO debe ser `localhost` o `127.0.0.1` (a menos que estés en el mismo servidor)

3. **Si está vacío o incorrecto**:
   - Ingresa: `http://72.61.58.240`
   - Guarda la configuración

### Paso 4: Verificar Variables de Entorno en EasyPanel

1. **Edita el servicio `whatsapp`** en EasyPanel
2. **Ve a "Variables de Entorno"**
3. **Verifica que existan estas variables**:

```
INSTANCE_NUMBER=1
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

4. **Si faltan variables**:
   - Agrégalas
   - Guarda los cambios
   - **Reinicia el servicio**

### Paso 5: Verificar Configuración de Puerto

1. **En EasyPanel**, edita el servicio `whatsapp`
2. **Ve a la sección "Puertos"**
3. **Verifica**:
   - **Puerto Interno**: `3001`
   - **Puerto Externo**: `3001` (o automático)
   - **Protocolo**: `HTTP`

4. **Si está mal configurado**:
   - Corrígelo
   - Guarda
   - Reinicia el servicio

### Paso 6: Probar la Conexión Manualmente

Desde la terminal de EasyPanel o desde tu servidor, prueba:

```bash
curl http://localhost:3001/api/status
```

**Resultados esperados**:
- ✅ Si funciona: Verás un JSON con el estado del WhatsApp
- ❌ Si no funciona: Verás un error de conexión

**Si funciona localmente pero no desde el dashboard**:
- El problema es de red/firewall
- Verifica que el puerto 3001 esté abierto externamente

### Paso 7: Verificar desde el Navegador

Abre en tu navegador:

```
http://72.61.58.240:3001/api/status
```

**Resultados esperados**:
- ✅ Si funciona: Verás un JSON con el estado
- ❌ Si no funciona: Verás un error de conexión o timeout

**Si no funciona**:
- El puerto no está accesible externamente
- Necesitas configurar el firewall o el proxy en EasyPanel

---

## 🔍 Diagnóstico Rápido

### Checklist de Verificación:

- [ ] Servicio `whatsapp` está en **VERDE (Running)** en EasyPanel
- [ ] No hay errores en los logs del servicio
- [ ] Variable `INSTANCE_NUMBER=1` está configurada
- [ ] Variable `PORT=3001` está configurada
- [ ] Puerto interno está configurado como `3001`
- [ ] URL en el dashboard es: `http://72.61.58.240` (sin puerto)
- [ ] El servicio responde a `curl http://localhost:3001/api/status`
- [ ] El servicio responde a `http://72.61.58.240:3001/api/status` desde el navegador

---

## 🆘 Soluciones por Problema Específico

### Problema 1: Servicio No Inicia

**Síntomas**: El servicio está en rojo o no inicia

**Solución**:
1. Revisa los logs del servicio
2. Verifica que todas las variables de entorno estén configuradas
3. Verifica que el archivo `whatsapp-server.js` exista
4. Verifica que no haya otro proceso usando el puerto 3001

### Problema 2: Puerto Ya en Uso

**Síntomas**: Error "Port 3001 already in use" en los logs

**Solución**:
1. Detén otros servicios que puedan estar usando el puerto 3001
2. O cambia el puerto del servicio (pero también actualiza la configuración)

### Problema 3: Variables de Entorno Faltantes

**Síntomas**: Error "INSTANCE_NUMBER is not defined" en los logs

**Solución**:
1. Agrega todas las variables de entorno necesarias
2. Reinicia el servicio después de agregarlas

### Problema 4: Servicio Responde Localmente pero No desde el Dashboard

**Síntomas**: `curl localhost:3001` funciona, pero el dashboard no se conecta

**Solución**:
1. Verifica que el puerto esté abierto externamente
2. Verifica la configuración de firewall en EasyPanel
3. Verifica que la URL en el dashboard sea correcta (no `localhost`)

### Problema 5: Error CORS o de Red

**Síntomas**: Error en la consola del navegador sobre CORS o red

**Solución**:
1. Verifica que el servidor de WhatsApp tenga CORS habilitado
2. Verifica que no haya bloqueadores de red/firewall

---

## 📝 Pasos de Recuperación Rápida

Si nada funciona, intenta esto en orden:

1. **Reinicia el servicio** en EasyPanel
2. **Verifica los logs** para ver si hay errores nuevos
3. **Elimina y vuelve a agregar las variables de entorno**
4. **Reinicia el servicio nuevamente**
5. **Espera 30 segundos** después de reiniciar
6. **Intenta conectar desde el dashboard** nuevamente

---

## 🎯 Verificación Final

Una vez que hayas seguido todos los pasos, verifica:

1. ✅ El servicio está en verde en EasyPanel
2. ✅ Los logs muestran "Server listening on port 3001"
3. ✅ `curl http://localhost:3001/api/status` funciona
4. ✅ La URL en el dashboard es correcta
5. ✅ Al hacer clic en "Conectar", aparece un QR o cambia el estado

---

## 💡 Consejos Adicionales

- **Espera unos segundos** después de iniciar el servicio antes de intentar conectar
- **Revisa la consola del navegador** (F12) para ver errores más detallados
- **Verifica que no haya espacios extra** en las variables de entorno
- **Asegúrate de reiniciar el servicio** después de cambiar variables de entorno

---

## 🆘 Si Aún No Funciona

Si después de seguir todos estos pasos el problema persiste:

1. **Comparte los logs del servicio** de EasyPanel
2. **Comparte los errores de la consola del navegador** (F12)
3. **Indica qué pasos ya intentaste**
4. **Verifica la IP del servidor** (puede haber cambiado)

