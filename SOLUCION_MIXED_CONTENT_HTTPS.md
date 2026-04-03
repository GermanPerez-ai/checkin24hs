# Solución: Mixed Content Error (HTTP/HTTPS)

## Problema

El dashboard está cargado sobre **HTTPS** (`https://dashboard.checkin24hs.com`) pero intenta hacer peticiones a recursos **HTTP** (`http://72.61.58.240`), lo cual está bloqueado por el navegador por razones de seguridad.

### Errores Observados:
```
Mixed Content: The page at 'https://dashboard.checkin24hs.com/#' was loaded over HTTPS, 
but requested an insecure resource 'http://72.61.58.240/disconnect'. 
This request has been blocked; the content must be served over HTTPS.
```

## Solución Aplicada

### 1. Función Helper `ensureHTTPS()`
Creada una función que convierte automáticamente URLs HTTP a HTTPS cuando la página está en HTTPS:

```javascript
function ensureHTTPS(url) {
    if (!url) return url;
    
    // Si la página está en HTTPS y la URL es HTTP, convertir a HTTPS
    if (window.location.protocol === 'https:' && url.startsWith('http://')) {
        return url.replace('http://', 'https://');
    }
    
    return url;
}
```

### 2. Función `getServerURL()` Actualizada
Ahora usa `ensureHTTPS()` automáticamente:

```javascript
function getServerURL() {
    const serverUrl = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl');
    if (serverUrl && serverUrl.trim() !== '') {
        return ensureHTTPS(serverUrl.trim());
    }
    
    // Valor por defecto (convertido a HTTPS si es necesario)
    const defaultUrl = 'http://72.61.58.240';
    return ensureHTTPS(defaultUrl);
}
```

### 3. Funciones Corregidas
- ✅ `connectWhatsApp()` - Usa `getServerURL()` que ya convierte a HTTPS
- ✅ `updateWhatsApp()` - Usa `getServerURL()` que ya convierte a HTTPS
- ✅ `checkWhatsAppConnectionStatus()` - Usa `getServerURL()` que ya convierte a HTTPS
- ✅ `disconnectWhatsApp()` - Convierte HTTP a HTTPS antes de hacer fetch
- ✅ `saveWhatsAppServerUrl()` - Convierte HTTP a HTTPS antes de guardar
- ✅ `loadWhatsAppServerUrl()` - Convierte HTTP a HTTPS al cargar

### 4. Valores por Defecto Actualizados
- Placeholder del input: `https://72.61.58.240` (antes: `http://72.61.58.240`)
- Valor por defecto: `https://72.61.58.240` (convertido automáticamente)

## Importante: Configuración del Servidor

⚠️ **El servidor WhatsApp debe estar configurado con HTTPS** para que esto funcione.

### Opciones:

1. **Configurar HTTPS en el servidor** (Recomendado)
   - Instalar certificado SSL en el servidor
   - Configurar nginx/apache para HTTPS
   - Usar Let's Encrypt para certificado gratuito

2. **Usar un proxy reverso con HTTPS**
   - Configurar Cloudflare, Nginx, o similar
   - El proxy maneja HTTPS y redirige a HTTP interno

3. **Usar un servicio con HTTPS**
   - Migrar a un servicio que ya tenga HTTPS configurado

## Verificación

Después de implementar:

1. **Abre el dashboard** en `https://dashboard.checkin24hs.com`
2. **Abre la consola** (`F12`)
3. **Ve a Flor IA → WhatsApp**
4. **Haz clic en "Conectar" o "Desconectar"**
5. **No deberían aparecer errores de Mixed Content**

## Nota sobre Supabase

El error `ERR_CONNECTION_CLOSED` con Supabase es un problema temporal de red/conexión, no relacionado con Mixed Content. Si persiste:
- Verifica tu conexión a internet
- Verifica que Supabase esté funcionando
- Revisa los logs de Supabase Dashboard

## Archivos Modificados

- ✅ `dashboard.html` - Funciones corregidas para usar HTTPS
- ✅ `SOLUCION_MIXED_CONTENT_HTTPS.md` - Este documento

