# 🔧 Solución: Webmail no está funcionando

## Problema
El webmail en `webmail.checkin24hs.com` muestra uno de estos errores:
- **"Service is not started"** (El servicio no está iniciado)
- **Error 503 (Service Unavailable)** - El servicio está configurado pero no responde

## Diagnóstico

El servicio de webmail (probablemente Roundcube) necesita estar corriendo y configurado correctamente.

> **Nota:** Si ves error **503**, consulta también `SOLUCION_ERROR_503.md` para diagnóstico detallado.

## Solución Paso a Paso

### Paso 1: Verificar si el servicio de webmail está instalado

Conéctate al servidor donde está desplegado el webmail y verifica:

```bash
# Verificar si Roundcube está instalado
ls -la /usr/share/roundcube
# O
ls -la /var/www/roundcube

# Verificar si hay un servicio de webmail corriendo
sudo systemctl list-units | grep -i mail
sudo systemctl list-units | grep -i roundcube
```

### Paso 2: Verificar servicios de correo

```bash
# Ver todos los servicios relacionados con correo
sudo systemctl status postfix
sudo systemctl status dovecot
sudo systemctl status roundcube

# Ver puertos en uso
sudo netstat -tulpn | grep -E ':(80|443|8080|8081)'
# O
sudo ss -tulpn | grep -E ':(80|443|8080|8081)'
```

### Paso 3: Iniciar el servicio de webmail

Si el servicio existe pero no está corriendo:

```bash
# Para Roundcube (si está como servicio)
sudo systemctl start roundcube
sudo systemctl enable roundcube

# Para servicios de correo base
sudo systemctl start postfix
sudo systemctl start dovecot
sudo systemctl enable postfix
sudo systemctl enable dovecot
```

### Paso 4: Configurar Nginx para webmail

Edita el archivo de configuración de Nginx en el servidor:

```bash
sudo nano /etc/nginx/sites-available/webmail.checkin24hs.com
# O
sudo nano /etc/nginx/conf.d/webmail.conf
```

Agrega o descomenta la siguiente configuración:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name webmail.checkin24hs.com mail.checkin24hs.com;
    
    # Si Roundcube está instalado localmente
    root /usr/share/roundcube;
    index index.php index.html;
    
    # Configuración para PHP (si Roundcube usa PHP)
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;  # Ajusta la versión de PHP
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Si el webmail está en otro puerto (proxy)
    # location / {
    #     proxy_pass http://localhost:8080;  # Ajusta el puerto
    #     proxy_set_header Host $host;
    #     proxy_set_header X-Real-IP $remote_addr;
    #     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #     proxy_set_header X-Forwarded-Proto $scheme;
    # }
    
    # Servir archivos estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Logs
    access_log /var/log/nginx/webmail-access.log;
    error_log /var/log/nginx/webmail-error.log;
}
```

### Paso 5: Si el webmail está en Docker

Si el webmail está corriendo en un contenedor Docker:

```bash
# Ver contenedores de Docker
docker ps -a | grep -i mail
docker ps -a | grep -i roundcube

# Iniciar el contenedor si está detenido
docker start nombre_contenedor_webmail

# O iniciar con docker-compose
cd /ruta/al/docker-compose
docker-compose up -d webmail
```

Luego configura Nginx para hacer proxy al contenedor:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name webmail.checkin24hs.com mail.checkin24hs.com;
    
    location / {
        proxy_pass http://localhost:8080;  # Puerto del contenedor
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Paso 6: Verificar y recargar Nginx

```bash
# Verificar la configuración de Nginx
sudo nginx -t

# Si está correcta, recargar Nginx
sudo systemctl reload nginx
# O
sudo service nginx reload
```

### Paso 7: Verificar logs

Si aún no funciona, revisa los logs:

```bash
# Logs de Nginx
sudo tail -f /var/log/nginx/webmail-error.log
sudo tail -f /var/log/nginx/error.log

# Logs del servicio de webmail (si aplica)
sudo journalctl -u roundcube -f
sudo journalctl -u postfix -f
```

## Si el webmail NO está instalado

Si el webmail no está instalado, necesitas instalarlo. Opciones comunes:

### Opción 1: Instalar Roundcube (recomendado)

```bash
# En Ubuntu/Debian
sudo apt update
sudo apt install roundcube roundcube-core roundcube-mysql roundcube-plugins

# Configurar Roundcube
sudo dpkg-reconfigure roundcube-core
```

### Opción 2: Usar Docker (más fácil)

Crea un archivo `docker-compose.yml`:

```yaml
version: '3.8'

services:
  webmail:
    image: roundcube/roundcubemail:latest
    container_name: roundcube
    ports:
      - "8080:80"
    environment:
      - ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
      - ROUNDCUBEMAIL_DEFAULT_PORT=143
      - ROUNDCUBEMAIL_SMTP_SERVER=smtp.checkin24hs.com
      - ROUNDCUBEMAIL_SMTP_PORT=587
    volumes:
      - roundcube_data:/var/www/html
    restart: unless-stopped

volumes:
  roundcube_data:
```

Inicia el contenedor:

```bash
docker-compose up -d
```

## Verificación Final

1. Accede a `http://webmail.checkin24hs.com` (o `https://` si tienes SSL)
2. Deberías ver la página de login del webmail, no el error "Service is not started"

## Resumen de Comandos Rápidos

```bash
# 1. Verificar servicios
sudo systemctl status roundcube postfix dovecot

# 2. Iniciar servicios
sudo systemctl start roundcube postfix dovecot
sudo systemctl enable roundcube postfix dovecot

# 3. Verificar puertos
sudo netstat -tulpn | grep LISTEN

# 4. Verificar Nginx
sudo nginx -t
sudo systemctl reload nginx

# 5. Ver logs
sudo tail -f /var/log/nginx/webmail-error.log
```

## Notas Importantes

- El webmail necesita un servidor de correo (Postfix/Dovecot) funcionando
- Asegúrate de que los puertos 80/443 estén abiertos en el firewall
- Si usas SSL, configura certificados SSL para `webmail.checkin24hs.com`
- El DNS debe apuntar correctamente a la IP del servidor

