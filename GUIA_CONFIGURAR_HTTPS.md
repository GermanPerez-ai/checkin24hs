# 🔒 Guía: Configurar HTTPS para WhatsApp API

## 🎯 Objetivo

Configurar HTTPS para que el dashboard (`https://dashboard.checkin24hs.com`) pueda conectarse a los servidores WhatsApp sin errores de Mixed Content.

## 📋 Opción Recomendada: Nginx + Let's Encrypt (Fácil)

### Paso 1: Crear Subdominio para API WhatsApp

**En tu panel de DNS de Hostinger**, agrega un nuevo registro:

```
Tipo: A
Nombre: api
Apunta a: 72.61.58.240
TTL: 14400
```

Esto creará: `api.checkin24hs.com` → `72.61.58.240`

---

### Paso 2: Instalar Nginx y Certbot (en el servidor SSH)

```bash
# Conectarse al servidor
ssh root@72.61.58.240

# Actualizar sistema
apt update

# Instalar Nginx y Certbot
apt install -y nginx certbot python3-certbot-nginx

# Verificar que Nginx esté corriendo
systemctl status nginx
```

---

### Paso 3: Configurar Nginx como Proxy Reverso

Crea el archivo de configuración:

```bash
nano /etc/nginx/sites-available/api-whatsapp.conf
```

Pega esta configuración:

```nginx
# Proxy para WhatsApp API - Puerto 3001
server {
    listen 80;
    server_name api.checkin24hs.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# Proxy para WhatsApp API - Puerto 3002
server {
    listen 80;
    server_name whatsapp2-api.checkin24hs.com;

    location / {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# Proxy para WhatsApp API - Puerto 3003
server {
    listen 80;
    server_name whatsapp3-api.checkin24hs.com;

    location / {
        proxy_pass http://localhost:3003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# Proxy para WhatsApp API - Puerto 3004
server {
    listen 80;
    server_name whatsapp4-api.checkin24hs.com;

    location / {
        proxy_pass http://localhost:3004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**O mejor aún, una configuración más simple con rutas:**

```bash
nano /etc/nginx/sites-available/api-whatsapp.conf
```

```nginx
# Proxy para WhatsApp API - Un solo dominio con rutas
server {
    listen 80;
    server_name api.checkin24hs.com;

    # Puerto 3001 (WhatsApp 1)
    location /card/1/ {
        rewrite ^/card/1/(.*) /$1 break;
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Puerto 3002 (WhatsApp 2)
    location /card/2/ {
        rewrite ^/card/2/(.*) /$1 break;
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Puerto 3003 (WhatsApp 3)
    location /card/3/ {
        rewrite ^/card/3/(.*) /$1 break;
        proxy_pass http://localhost:3003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Puerto 3004 (WhatsApp 4)
    location /card/4/ {
        rewrite ^/card/4/(.*) /$1 break;
        proxy_pass http://localhost:3004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Por defecto, usar puerto 3001
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Activar la configuración:**

```bash
# Crear enlace simbólico
ln -s /etc/nginx/sites-available/api-whatsapp.conf /etc/nginx/sites-enabled/

# Verificar configuración
nginx -t

# Si está bien, recargar Nginx
systemctl reload nginx
```

---

### Paso 4: Obtener Certificado SSL con Let's Encrypt

```bash
# Obtener certificado SSL (reemplaza con tu email)
certbot --nginx -d api.checkin24hs.com --email tu-email@checkin24hs.com --agree-tos --non-interactive

# Verificar renovación automática
certbot renew --dry-run
```

---

### Paso 5: Actualizar Dashboard para Usar HTTPS

Una vez configurado HTTPS, actualiza la URL en el dashboard:

1. Ve a **Flor IA** → **WhatsApp**
2. Haz clic en **"⚙️ Configurar Servidor"**
3. Cambia la URL de `http://72.61.58.240` a `https://api.checkin24hs.com`
4. Guarda la configuración

---

## ✅ Verificación

Después de configurar, verifica:

```bash
# Verificar que Nginx esté corriendo
systemctl status nginx

# Verificar certificados SSL
certbot certificates

# Probar conexión HTTPS
curl -I https://api.checkin24hs.com
```

---

## 🔄 Renovación Automática

Let's Encrypt renueva automáticamente los certificados. Verifica que el timer esté activo:

```bash
systemctl status certbot.timer
```

---

## 📝 Notas Importantes

1. **Espera propagación DNS**: Después de agregar el registro DNS, espera 5-15 minutos antes de obtener el certificado SSL.

2. **Puertos abiertos**: Asegúrate de que los puertos 80 y 443 estén abiertos en el firewall:
   ```bash
   ufw allow 80/tcp
   ufw allow 443/tcp
   ```

3. **EasyPanel**: Si EasyPanel ya maneja el puerto 80, puedes cambiar Nginx a otro puerto o deshabilitar el proxy de EasyPanel para `api.checkin24hs.com`.

---

## 🆘 Si Algo Sale Mal

1. **Ver logs de Nginx**: `tail -f /var/log/nginx/error.log`
2. **Verificar configuración**: `nginx -t`
3. **Reiniciar Nginx**: `systemctl restart nginx`









