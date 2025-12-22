# Solución: Error Mixed Content (HTTPS → HTTP)

## 🔴 Problema Identificado

El error **Mixed Content** ocurre porque:

1. **Dashboard**: Servido sobre **HTTPS** (`https://dashboard.checkin24hs.com`)
2. **Servidor WhatsApp**: Servido sobre **HTTP** (`http://72.61.58.240:3001`)
3. **Navegadores modernos**: Bloquean automáticamente las peticiones HTTP desde páginas HTTPS por seguridad

**Error en consola:**
```
Mixed Content: The page at 'https://dashboard.checkin24hs.com/#' was loaded over HTTPS, 
but requested an insecure resource 'http://72.61.58.240:3001/api/qr?card=1'. 
This request has been blocked; the content must be served over HTTPS.
```

## ✅ Soluciones

### Opción 1: Configurar HTTPS en el Servidor WhatsApp (RECOMENDADO)

**Configurar un dominio con SSL para el servidor WhatsApp:**

1. **Configurar dominio** (ej: `whatsapp.checkin24hs.com`)
2. **Configurar certificado SSL** (Let's Encrypt, Cloudflare, etc.)
3. **Configurar proxy reverso** (nginx, Caddy, etc.) que:
   - Acepte HTTPS en el puerto 443
   - Redirija a HTTP internamente al puerto 3001
4. **Actualizar URL en el dashboard** a `https://whatsapp.checkin24hs.com`

**Ejemplo con nginx:**
```nginx
server {
    listen 443 ssl;
    server_name whatsapp.checkin24hs.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Opción 2: Usar Proxy HTTPS en EasyPanel

Si EasyPanel soporta proxies reversos:

1. Configurar un servicio de proxy (nginx, Caddy) en EasyPanel
2. El proxy acepta HTTPS y redirige a HTTP internamente
3. Configurar dominio con SSL para el proxy

### Opción 3: Solución Temporal (NO RECOMENDADO para producción)

**Acceder al dashboard desde HTTP:**

1. Cambiar la URL del dashboard de `https://dashboard.checkin24hs.com` a `http://dashboard.checkin24hs.com`
2. Esto permite conexiones HTTP → HTTP sin bloqueos
3. **⚠️ NO recomendado** porque pierdes la seguridad de HTTPS

**O permitir contenido mixto en el navegador** (solo desarrollo):

1. Chrome: Click en el ícono de candado → Configuración del sitio → Contenido no seguro → Permitir
2. **⚠️ NO recomendado** porque reduce la seguridad

## 🔧 Cambios Aplicados en el Código

1. **Detección de Mixed Content**: El código ahora detecta cuando hay un error de Mixed Content y muestra un mensaje específico
2. **Mensaje claro**: Explica el problema y ofrece soluciones
3. **Limpieza de estado**: Limpia el estado de error previo al iniciar una nueva conexión

## 📋 Próximos Pasos

### Para Solucionar Definitivamente:

1. **Configurar dominio con SSL** para el servidor WhatsApp
2. **Configurar proxy reverso** (nginx, Caddy, etc.)
3. **Actualizar URL** en el dashboard a la nueva URL HTTPS
4. **Probar conexión** - debería funcionar sin errores

### Verificación:

Una vez configurado HTTPS en el servidor WhatsApp:

1. El dashboard debería poder conectarse sin errores de Mixed Content
2. El QR debería generarse correctamente
3. La conexión debería funcionar normalmente

## 📝 Nota

El código ahora muestra un mensaje claro cuando detecta Mixed Content, explicando el problema y ofreciendo soluciones. Una vez que configures HTTPS en el servidor WhatsApp, el problema se resolverá automáticamente.

