# 🔍 Diagnóstico Paso a Paso - EasyPanel

## 📸 Basado en tu Pantalla de EasyPanel

Veo que tienes:
- ✅ **roundcube** (verde, seleccionado)
- ✅ **webmail** (verde)
- ✅ **paginaweb** (verde)
- ✅ **whatsapp** (verde)
- ⚠️ **whatsapp2** (amarillo)

## 🎯 Pasos para Diagnosticar el Error 503

### Paso 1: Ver Detalles de Roundcube

1. **Haz clic en "roundcube"** (ya está seleccionado)
2. Busca estas secciones:
   - **"Logs"** o **"Registros"**
   - **"Configuration"** o **"Configuración"**
   - **"Status"** o **"Estado"**
   - **"Ports"** o **"Puertos"**

### Paso 2: Verificar el Estado del Servicio

En la página de detalles de roundcube, busca:

- **Status**: Debe decir "Running" o "Activo"
- **Port**: Anota el puerto (ej: 8080, 3000, etc.)
- **Health**: Debe estar en verde

### Paso 3: Ver los Logs

1. En la página de roundcube, ve a **"Logs"**
2. Busca errores recientes que contengan:
   - `503`
   - `Connection refused`
   - `upstream`
   - `PHP-FPM`

### Paso 4: Verificar la Configuración de Nginx

1. Haz clic en **"webmail"** en la lista de servicios
2. Ve a **"Configuration"** o **"Nginx Config"**
3. Verifica que tenga una configuración como:

```nginx
server {
    listen 80;
    server_name webmail.checkin24hs.com;
    
    location / {
        proxy_pass http://localhost:PUERTO_DE_ROUNDCUBE;
        # O si usa PHP directamente:
        # root /usr/share/roundcube;
        # fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
}
```

### Paso 5: Verificar PHP-FPM (si roundcube lo necesita)

1. En EasyPanel, busca en **"SERVICIOS"** un servicio llamado:
   - `php-fpm`
   - `php8.1-fpm`
   - `php8.0-fpm`

2. Si existe, verifica que esté en **verde (Running)**

3. Si no existe o está en rojo:
   - Haz clic en el servicio PHP-FPM
   - Haz clic en **"Start"** o **"Iniciar"**

## 🔧 Soluciones Rápidas desde EasyPanel

### Solución 1: Reiniciar Roundcube

1. Haz clic en **"roundcube"**
2. Busca el botón **"Restart"** o **"Reiniciar"**
3. Haz clic y espera unos segundos
4. Verifica que el estado vuelva a verde

### Solución 2: Verificar y Recargar Nginx

1. Haz clic en **"webmail"** (o busca un servicio llamado "nginx")
2. Si hay un servicio de Nginx:
   - Haz clic en **"Reload"** o **"Recargar"**
3. Si no hay servicio de Nginx separado:
   - La configuración de Nginx está en cada aplicación
   - Ve a la configuración de "webmail" y recarga

### Solución 3: Verificar el Puerto

1. En **"roundcube"**, anota el puerto (ej: 8080)
2. En **"webmail"**, ve a la configuración de Nginx
3. Verifica que `proxy_pass` apunte al puerto correcto:

```nginx
proxy_pass http://localhost:8080;  # Debe coincidir con el puerto de roundcube
```

### Solución 4: Usar la Terminal Integrada

1. En EasyPanel, busca **"Terminal"** o **"SSH"** en el menú
2. Ejecuta estos comandos:

```bash
# Ver estado de roundcube
docker ps | grep roundcube
# O si no es Docker:
systemctl status roundcube

# Ver logs de Nginx
tail -20 /var/log/nginx/error.log

# Verificar puertos
netstat -tulpn | grep LISTEN
```

## 🎯 Qué Buscar Específicamente

### Si Roundcube está en Docker:

1. Haz clic en **"roundcube"**
2. Busca la sección **"Docker"** o **"Container"**
3. Verifica:
   - **Status**: Running
   - **Port Mapping**: Debe mostrar algo como `8080:80`
   - **Health**: Healthy

### Si Roundcube usa PHP:

1. Verifica que PHP-FPM esté corriendo (punto verde)
2. En la configuración de roundcube, verifica la ruta:
   - Debe ser algo como `/usr/share/roundcube` o `/var/www/roundcube`
3. Verifica los permisos de archivos

## 📋 Checklist Rápido

- [ ] Roundcube está en verde (Running)
- [ ] Webmail está en verde (Running)
- [ ] PHP-FPM está corriendo (si aplica)
- [ ] El puerto en Nginx coincide con el puerto de roundcube
- [ ] Los logs no muestran errores críticos
- [ ] Nginx está recargado después de cambios

## 🆘 Si Nada Funciona

1. **Haz clic en "roundcube"**
2. Ve a **"Logs"** → **"View All"** o **"Ver Todos"**
3. Copia los últimos 50-100 líneas de logs
4. Busca errores que mencionen:
   - `503`
   - `Connection refused`
   - `upstream`
   - `PHP`

## 💡 Próximos Pasos

Una vez que tengas la información de los pasos anteriores, podremos:
1. Identificar exactamente qué está causando el 503
2. Ajustar la configuración específica
3. Solucionar el problema de manera definitiva

