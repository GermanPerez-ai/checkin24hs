# Guía: Configurar SSL para Servidor WhatsApp

## 🔴 Problema Actual

El dashboard está en HTTPS (`https://dashboard.checkin24hs.com`) pero intenta conectarse a:
- `https://72.61.58.240:3001` → Error: `ERR_SSL_PROTOCOL_ERROR`

Esto significa que el servidor WhatsApp no tiene SSL configurado en el puerto 3001.

---

## ✅ Solución Recomendada: Nginx como Proxy Reverso con SSL

### Paso 1: Configurar DNS

1. **Elegir un dominio**: `configwp.checkin24hs.com`
2. **Configurar registro A** en tu proveedor DNS:
   ```
   Tipo: A
   Nombre: configwp
   Valor: 72.61.58.240
   TTL: 3600
   ```

### Paso 2: Instalar Nginx y Certbot en el VPS

Conecta por SSH a tu VPS (`72.61.58.240`) y ejecuta:

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Nginx
sudo apt install -y nginx

# Instalar Certbot (Let's Encrypt)
sudo apt install -y certbot python3-certbot-nginx

# Verificar que Nginx está corriendo
sudo systemctl status nginx
```

### Paso 3: Configurar Nginx como Proxy Reverso

Crea el archivo de configuración:

```bash
sudo nano /etc/nginx/sites-available/configwp.checkin24hs.com
```

**Contenido del archivo**:

```nginx
# Configuración para HTTP (puerto 80) - redirigirá a HTTPS
server {
    listen 80;
    server_name configwp.checkin24hs.com;

    # Redirigir todo a HTTPS
    return 301 https://$server_name$request_uri;
}

# Configuración para HTTPS (puerto 443)
server {
    listen 443 ssl http2;
    server_name configwp.checkin24hs.com;

    # Certificados SSL (se generarán automáticamente con Certbot)
    # ssl_certificate /etc/letsencrypt/live/configwp.checkin24hs.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/configwp.checkin24hs.com/privkey.pem;

    # Configuración SSL recomendada
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Headers de seguridad
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Proxy reverso al servidor WhatsApp
    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        
        # Headers importantes para el proxy
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        
        # WebSocket support (si es necesario)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Logs
    access_log /var/log/nginx/configwp.checkin24hs.com-access.log;
    error_log /var/log/nginx/configwp.checkin24hs.com-error.log;
}
```

### Paso 4: Activar la Configuración

```bash
# Crear enlace simbólico
sudo ln -s /etc/nginx/sites-available/configwp.checkin24hs.com /etc/nginx/sites-enabled/

# Verificar configuración
sudo nginx -t

# Si todo está bien, recargar Nginx
sudo systemctl reload nginx
```

### Paso 5: Obtener Certificado SSL con Let's Encrypt

```bash
# Generar certificado SSL automáticamente
sudo certbot --nginx -d configwp.checkin24hs.com

# Seguir las instrucciones:
# - Email: tu email
# - Aceptar términos
# - Decidir si compartir email con EFF (opcional)
```

**Certbot automáticamente:**
- Generará los certificados SSL
- Actualizará la configuración de Nginx
- Configurará renovación automática

### Paso 6: Verificar Renovación Automática

```bash
# Probar renovación (no renueva realmente, solo prueba)
sudo certbot renew --dry-run

# Verificar que el servicio de renovación está activo
sudo systemctl status certbot.timer
```

### Paso 7: Verificar que Funciona

1. **Probar en el navegador:**
   ```
   https://configwp.checkin24hs.com/api/qr?card=1
   ```
   Deberías ver una respuesta JSON o el QR code.

2. **Verificar logs de Nginx:**
   ```bash
   sudo tail -f /var/log/nginx/configwp.checkin24hs.com-access.log
   ```

3. **Verificar que el proxy funciona:**
   ```bash
   curl -I https://configwp.checkin24hs.com/api/qr?card=1
   ```

---

## 🔧 Configuración para Múltiples Instancias de WhatsApp

Si tienes múltiples instancias de WhatsApp (puertos 3001, 3002, 3003, 3004), puedes:

### Opción 1: Subdominios separados

```
configwp1.checkin24hs.com → puerto 3001
configwp2.checkin24hs.com → puerto 3002
configwp3.checkin24hs.com → puerto 3003
configwp4.checkin24hs.com → puerto 3004
```

### Opción 2: Rutas en el mismo dominio

```nginx
location /api1/ {
    proxy_pass http://127.0.0.1:3001/;
    # ... resto de configuración proxy
}

location /api2/ {
    proxy_pass http://127.0.0.1:3002/;
    # ... resto de configuración proxy
}
```

### Opción 3: Usar parámetro de puerto (más simple)

Mantener la estructura actual y usar el mismo dominio con diferentes puertos (pero esto requiere certificados SSL para cada puerto, no recomendado).

---

## 📝 Actualizar Código del Dashboard

Una vez que tengas el dominio HTTPS funcionando:

1. **En el dashboard**, ve a **Flor IA → WhatsApp**
2. **En el campo "URL del Servidor WhatsApp"**, ingresa:
   ```
   https://configwp.checkin24hs.com
   ```
   (sin el puerto, Nginx manejará el enrutamiento)

3. **Haz clic en "Guardar URL"**

El código automáticamente agregará los puertos `:3001`, `:3002`, etc., pero como Nginx está en el puerto 443 (HTTPS), necesitarás ajustar la configuración.

**Mejor opción:** Configurar rutas en Nginx para cada instancia:

```nginx
# Instancia 1 (card 1)
location /api/qr {
    if ($arg_card = "1") {
        proxy_pass http://127.0.0.1:3001;
    }
    if ($arg_card = "2") {
        proxy_pass http://127.0.0.1:3002;
    }
    if ($arg_card = "3") {
        proxy_pass http://127.0.0.1:3003;
    }
    if ($arg_card = "4") {
        proxy_pass http://127.0.0.1:3004;
    }
    # ... resto de configuración proxy
}
```

O mejor aún, usar rutas específicas:

```nginx
location /api1/ {
    proxy_pass http://127.0.0.1:3001/;
}

location /api2/ {
    proxy_pass http://127.0.0.1:3002/;
}

location /api3/ {
    proxy_pass http://127.0.0.1:3003/;
}

location /api4/ {
    proxy_pass http://127.0.0.1:3004/;
}
```

Y actualizar el código para usar estas rutas.

---

## 🔍 Troubleshooting

### Error: "No se puede resolver el dominio"
- Verifica que el DNS esté configurado correctamente
- Espera unos minutos para que se propague el DNS
- Verifica con: `nslookup api.checkin24hs.com`

### Error: "Certificado SSL inválido"
- Verifica que Certbot haya generado los certificados correctamente
- Revisa los logs: `sudo tail -f /var/log/letsencrypt/letsencrypt.log`

### Error: "502 Bad Gateway"
- Verifica que el servidor WhatsApp esté corriendo: `curl http://127.0.0.1:3001/api/qr?card=1`
- Verifica los logs de Nginx: `sudo tail -f /var/log/nginx/api.checkin24hs.com-error.log`

### El proxy no funciona
- Verifica la configuración de Nginx: `sudo nginx -t`
- Verifica que Nginx esté escuchando en el puerto 443: `sudo netstat -tlnp | grep :443`
- Verifica que el firewall permita el puerto 443: `sudo ufw status`

---

## 📋 Resumen de Comandos

```bash
# 1. Instalar Nginx y Certbot
sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx

# 2. Crear configuración
sudo nano /etc/nginx/sites-available/api.checkin24hs.com
# (pegar configuración de arriba)

# 3. Activar configuración
sudo ln -s /etc/nginx/sites-available/api.checkin24hs.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 4. Obtener certificado SSL
sudo certbot --nginx -d api.checkin24hs.com

# 5. Verificar renovación automática
sudo certbot renew --dry-run
```

---

## ✅ Una vez configurado

1. **Actualiza la URL en el dashboard** a: `https://api.checkin24hs.com`
2. **Prueba la conexión** desde el dashboard
3. **Verifica que el QR se genere correctamente**

¡Listo! El servidor WhatsApp ahora tendrá SSL válido y funcionará desde el dashboard HTTPS.

