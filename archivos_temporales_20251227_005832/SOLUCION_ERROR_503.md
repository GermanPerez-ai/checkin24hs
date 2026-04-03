# 🔧 Solución: Error 503 (Service Unavailable)

## Problema
El webmail muestra error **503 (Service Unavailable)** al intentar acceder. Esto significa que Nginx está configurado pero el servicio backend no está disponible.

## Causas Comunes

1. **Servicio backend no está corriendo** (Node.js, PHP-FPM, Docker, etc.)
2. **Proxy_pass apunta a un puerto incorrecto o servicio detenido**
3. **PHP-FPM no está corriendo** (si el webmail usa PHP)
4. **Servicio sobrecargado o bloqueado**

## Diagnóstico Rápido

### Paso 1: Verificar qué servicio debería estar corriendo

Conéctate al servidor y verifica la configuración de Nginx:

```bash
# Ver la configuración de webmail en Nginx
sudo cat /etc/nginx/sites-available/webmail.checkin24hs.com
# O
sudo cat /etc/nginx/conf.d/webmail.conf

# Buscar líneas con proxy_pass o fastcgi_pass
sudo grep -r "proxy_pass\|fastcgi_pass" /etc/nginx/sites-available/
```

### Paso 2: Verificar si el servicio backend está corriendo

#### Si usa proxy_pass (Node.js, Docker, etc.):

```bash
# Ver qué puerto está configurado (ej: 8080, 3000)
# Luego verificar si hay algo escuchando en ese puerto
sudo netstat -tulpn | grep LISTEN
# O
sudo ss -tulpn | grep LISTEN

# Verificar si hay un proceso Node.js corriendo
ps aux | grep node

# Verificar contenedores Docker
docker ps -a
```

#### Si usa PHP-FPM:

```bash
# Verificar si PHP-FPM está corriendo
sudo systemctl status php8.1-fpm
# O la versión que tengas instalada
sudo systemctl status php7.4-fpm
sudo systemctl status php-fpm

# Verificar el socket de PHP-FPM
ls -la /var/run/php/
```

## Soluciones

### Solución 1: Si el webmail usa proxy_pass a Node.js/Docker

#### Verificar el puerto configurado:

```bash
# Ver la configuración de Nginx
sudo grep "proxy_pass" /etc/nginx/sites-available/webmail.checkin24hs.com
```

Si muestra algo como `proxy_pass http://localhost:8080;`, entonces:

#### Iniciar el servicio backend:

**Si es Node.js:**
```bash
# Verificar si hay un server.js o similar
cd /ruta/del/proyecto
node server.js
# O con PM2
pm2 start server.js --name webmail
pm2 save
```

**Si es Docker:**
```bash
# Ver contenedores
docker ps -a | grep webmail
docker ps -a | grep roundcube

# Iniciar el contenedor
docker start nombre_contenedor
# O
docker-compose up -d
```

### Solución 2: Si el webmail usa PHP-FPM

#### Iniciar PHP-FPM:

```bash
# Verificar qué versión de PHP tienes
php -v

# Iniciar PHP-FPM (ajusta la versión)
sudo systemctl start php8.1-fpm
sudo systemctl enable php8.1-fpm

# O
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# Verificar que esté corriendo
sudo systemctl status php8.1-fpm
```

#### Verificar el socket de PHP-FPM:

```bash
# Ver qué socket está configurado en Nginx
sudo grep "fastcgi_pass" /etc/nginx/sites-available/webmail.checkin24hs.com

# Verificar que el socket exista
ls -la /var/run/php/php8.1-fpm.sock
# Ajusta la versión según tu instalación
```

Si el socket no existe, verifica la configuración de PHP-FPM:

```bash
# Editar configuración de PHP-FPM
sudo nano /etc/php/8.1/fpm/pool.d/www.conf
# Buscar la línea: listen = /var/run/php/php8.1-fpm.sock
# Asegúrate de que coincida con la configuración de Nginx
```

### Solución 3: Si el webmail está en Roundcube local

#### Verificar que Roundcube esté instalado:

```bash
# Verificar instalación
ls -la /usr/share/roundcube
# O
ls -la /var/www/roundcube

# Verificar permisos
sudo chown -R www-data:www-data /usr/share/roundcube
sudo chmod -R 755 /usr/share/roundcube
```

#### Verificar configuración de Nginx:

Asegúrate de que la configuración de Nginx sea correcta:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name webmail.checkin24hs.com mail.checkin24hs.com;
    
    root /usr/share/roundcube;
    index index.php index.html;
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;  # Ajusta la versión
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### Solución 4: Verificar logs para más detalles

```bash
# Logs de Nginx (más importante)
sudo tail -f /var/log/nginx/webmail-error.log
sudo tail -f /var/log/nginx/error.log

# Logs de PHP-FPM (si aplica)
sudo tail -f /var/log/php8.1-fpm.log
sudo journalctl -u php8.1-fpm -f

# Logs del sistema
sudo journalctl -xe
```

Los logs te dirán exactamente qué está fallando. Busca mensajes como:
- `connect() failed (111: Connection refused)` → El servicio no está corriendo
- `upstream timed out` → El servicio está lento o bloqueado
- `No such file or directory` → Ruta incorrecta

## Verificación y Recarga

Después de iniciar los servicios:

```bash
# Verificar configuración de Nginx
sudo nginx -t

# Si está correcta, recargar Nginx
sudo systemctl reload nginx
# O
sudo service nginx reload
```

## Comandos de Diagnóstico Completos

Ejecuta estos comandos para un diagnóstico completo:

```bash
# 1. Ver configuración de Nginx
echo "=== Configuración de Nginx ==="
sudo cat /etc/nginx/sites-available/webmail.checkin24hs.com | grep -E "proxy_pass|fastcgi_pass|root"

# 2. Ver servicios corriendo
echo "=== Servicios PHP-FPM ==="
sudo systemctl status php8.1-fpm php7.4-fpm php-fpm 2>/dev/null

# 3. Ver puertos en uso
echo "=== Puertos en uso ==="
sudo netstat -tulpn | grep -E ':(80|443|8080|3000|9000)'

# 4. Ver procesos Node.js
echo "=== Procesos Node.js ==="
ps aux | grep node

# 5. Ver contenedores Docker
echo "=== Contenedores Docker ==="
docker ps -a 2>/dev/null

# 6. Ver logs recientes
echo "=== Últimos errores de Nginx ==="
sudo tail -20 /var/log/nginx/error.log
```

## Resumen de Comandos Rápidos

```bash
# Iniciar PHP-FPM
sudo systemctl start php8.1-fpm && sudo systemctl enable php8.1-fpm

# Iniciar servicio Node.js
cd /ruta/del/proyecto && node server.js &
# O con PM2
pm2 start server.js --name webmail && pm2 save

# Iniciar contenedor Docker
docker start nombre_contenedor
# O
docker-compose up -d

# Recargar Nginx
sudo nginx -t && sudo systemctl reload nginx

# Ver logs en tiempo real
sudo tail -f /var/log/nginx/webmail-error.log
```

## Si Nada Funciona

1. **Verifica que el dominio apunte correctamente:**
   ```bash
   nslookup webmail.checkin24hs.com
   ```

2. **Verifica el firewall:**
   ```bash
   sudo ufw status
   sudo iptables -L -n
   ```

3. **Reinicia todos los servicios:**
   ```bash
   sudo systemctl restart nginx
   sudo systemctl restart php8.1-fpm
   # O reinicia el servicio backend que corresponda
   ```

4. **Verifica espacio en disco:**
   ```bash
   df -h
   ```

## Notas Importantes

- El error 503 significa que **Nginx está funcionando** pero **no puede conectarse al backend**
- Siempre verifica los **logs de Nginx** primero, ahí está la respuesta
- Asegúrate de que el **puerto o socket** en la configuración de Nginx coincida con el servicio real
- Si cambias la configuración, siempre ejecuta `sudo nginx -t` antes de recargar

