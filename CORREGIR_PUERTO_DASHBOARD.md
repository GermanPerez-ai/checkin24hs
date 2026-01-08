# 🔧 Corrección del Puerto del Dashboard

## Problema
El dashboard (`dashboard.checkin24hs.com`) está mostrando la página de Roundcube (webmail) en lugar del dashboard correcto. Esto indica que los puertos están mezclados.

## Solución

### Paso 1: Verificar la configuración de Nginx en el servidor

1. **Conectarse al servidor** donde está desplegado el dashboard
2. **Editar el archivo de configuración de Nginx**:
   ```bash
   sudo nano /etc/nginx/sites-available/dashboard.checkin24hs.com
   # O
   sudo nano /etc/nginx/conf.d/dashboard.conf
   ```

### Paso 2: Verificar la configuración actual

Asegúrate de que la configuración del dashboard sea similar a esta:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name dashboard.checkin24hs.com;
    
    # IMPORTANTE: Root directory del dashboard, NO del correo
    root /usr/share/nginx/html;
    # O la ruta donde tienes los archivos del dashboard
    # root /var/www/checkin24hs;
    
    index dashboard.html;
    
    location / {
        try_files $uri $uri/ /dashboard.html;
    }
    
    # Prevenir acceso a archivos de correo/webmail
    location ~ /(webmail|roundcube|mail|correo) {
        return 404;
    }
}
```

### Paso 3: Verificar que NO haya proxy_pass al correo

**IMPORTANTE**: Asegúrate de que NO haya ninguna línea como esta en la configuración del dashboard:

```nginx
# ❌ INCORRECTO - Esto redirige al correo
proxy_pass http://localhost:PUERTO_CORREO;
proxy_pass http://127.0.0.1:PUERTO_CORREO;
```

### Paso 4: Configurar el correo en un subdominio diferente

El correo/webmail debe estar en un subdominio separado, por ejemplo:

```nginx
# Configuración del correo (en un archivo separado)
server {
    listen 80;
    server_name mail.checkin24hs.com webmail.checkin24hs.com;
    
    # Aquí va la configuración del webmail
    # Por ejemplo:
    # proxy_pass http://localhost:PUERTO_WEBMAIL;
    # O si está en el mismo servidor:
    # root /usr/share/roundcube;
}
```

### Paso 5: Verificar los puertos en uso

Verifica qué puertos están en uso:

```bash
# Ver puertos en uso
sudo netstat -tulpn | grep LISTEN
# O
sudo ss -tulpn | grep LISTEN
```

### Paso 6: Reiniciar Nginx

Después de hacer los cambios:

```bash
# Verificar la configuración
sudo nginx -t

# Si está correcta, recargar Nginx
sudo systemctl reload nginx
# O
sudo service nginx reload
```

### Paso 7: Verificar que funcione

1. Accede a `https://dashboard.checkin24hs.com` (o `http://` si no tienes SSL)
2. Deberías ver el dashboard, NO la página de Roundcube

## Si el problema persiste

### Verificar archivos en el servidor

1. Verifica que el archivo `dashboard.html` esté en la ruta correcta:
   ```bash
   ls -la /usr/share/nginx/html/dashboard.html
   # O la ruta que configuraste en root
   ```

2. Verifica los permisos:
   ```bash
   sudo chown -R www-data:www-data /usr/share/nginx/html
   sudo chmod -R 755 /usr/share/nginx/html
   ```

### Verificar logs

Revisa los logs de Nginx para ver errores:

```bash
sudo tail -f /var/log/nginx/dashboard-error.log
sudo tail -f /var/log/nginx/error.log
```

### Verificar configuración de DNS

Asegúrate de que el DNS apunte correctamente:

```bash
nslookup dashboard.checkin24hs.com
```

## Resumen

- ✅ El dashboard debe servir archivos estáticos desde `/usr/share/nginx/html` (o tu ruta)
- ✅ El dashboard NO debe tener `proxy_pass` al correo
- ✅ El correo debe estar en un subdominio diferente (`mail.checkin24hs.com`)
- ✅ Verificar y reiniciar Nginx después de los cambios

## Archivo de referencia

El archivo `nginx.conf` en este proyecto ya está actualizado con la configuración correcta. Úsalo como referencia para tu servidor.


