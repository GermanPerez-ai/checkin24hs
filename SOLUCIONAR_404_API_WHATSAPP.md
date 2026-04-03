# 🔧 Solucionar Error 404 en API de WhatsApp

## ❌ Error Actual

`GET http://api1.checkin24hs.com/api/status?card=1 404 (Not Found)`

Esto significa que Traefik está recibiendo la petición pero no puede enrutarla al servicio.

---

## ✅ Verificaciones Paso a Paso

### Paso 1: Verificar que el Servicio Esté Corriendo

1. **Ve a EasyPanel** → **Servicios** → **`whatsapp`**
2. **Verifica el estado**:
   - ✅ **VERDE** = Está corriendo (correcto)
   - 🟡 **AMARILLO** = Está iniciando (espera 1-2 minutos)
   - 🔴 **ROJO/GRIS** = Está detenido (necesitas iniciarlo)

3. **Si está detenido**:
   - Haz clic en el botón **"Iniciar"** o **"Start"**
   - Espera hasta que esté en VERDE

### Paso 2: Verificar Configuración del Dominio

1. **Ve a "🔗 Dominios"** en el servicio `whatsapp`
2. **Haz clic en `api1.checkin24hs.com`**
3. **Verifica en la pestaña "Detalles"**:
   - ✅ **HTTPS**: Activado (toggle en azul)
   - ✅ **Host**: `api1.checkin24hs.com`
   - ✅ **Puerto Destino**: **`3001`** ⚠️ **DEBE SER 3001, NO 80**
   - ✅ **Ruta destino**: `/`

4. **Si el puerto destino es `80`**:
   - Cámbialo a **`3001`**
   - Guarda los cambios
   - Espera 30 segundos

### Paso 3: Verificar Logs del Servicio

1. **Ve a "Logs"** en el servicio `whatsapp`
2. **Busca mensajes como**:
   ```
   WhatsApp server iniciado en puerto 3001
   Server listening on port 3001
   ```
3. **Si ves errores de Chromium**, el servicio no está funcionando correctamente

### Paso 4: Probar Directamente el Puerto

Si tienes acceso SSH al servidor, prueba:

```bash
# Desde el servidor
curl http://localhost:3001/api/status?card=1
```

**Si esto funciona**, el problema es la configuración de Traefik.
**Si esto NO funciona**, el problema es el servicio WhatsApp.

---

## 🔍 Diagnóstico Rápido

### Si el servicio está en VERDE pero sigue dando 404:

1. **Verifica el puerto destino** en la configuración del dominio (debe ser `3001`)
2. **Revisa los logs de Traefik** para ver errores de enrutamiento
3. **Reinicia Traefik** (puede estar en caché)

### Si el servicio está en GRIS/ROJO:

1. **Inicia el servicio**
2. **Espera hasta que esté en VERDE**
3. **Revisa los logs** para ver si hay errores

### Si el servicio está en AMARILLO:

1. **Espera 1-2 minutos** (se está iniciando)
2. **Revisa los logs** para ver el progreso
3. **Si tarda mucho**, puede haber un error (revisa los logs)

---

## 🎯 Solución Más Probable

El problema más común es que el **puerto destino está en `80` en lugar de `3001`**.

**Solución**:
1. Ve a **"Dominios"** → **`api1.checkin24hs.com`**
2. En **"Detalles"**, cambia **"Puerto"** de `80` a `3001`
3. **Guarda** los cambios
4. **Espera 30 segundos**
5. **Prueba nuevamente**: `http://api1.checkin24hs.com/api/status?card=1`

---

**¿Qué estado tiene el servicio `whatsapp` en EasyPanel? ¿Está en VERDE, AMARILLO o GRIS/ROJO? ¿Cuál es el puerto destino configurado en el dominio?**









