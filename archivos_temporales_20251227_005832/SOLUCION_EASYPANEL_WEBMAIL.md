# 🔧 Solución Error 503 Webmail - EasyPanel

## 📍 Acceso desde EasyPanel

EasyPanel tiene todas las herramientas necesarias para diagnosticar y solucionar el error 503 del webmail directamente desde su interfaz web.

## 🔍 Paso 1: Diagnosticar el Problema

### Opción A: Usar la Terminal Integrada

1. **Accede a EasyPanel** en tu navegador
2. Ve a **"Terminal"** o **"SSH"** en el menú lateral
3. Una vez en la terminal, ejecuta estos comandos:

```bash
# 1. Verificar configuración de Nginx del webmail
cat /etc/nginx/sites-available/webmail.checkin24hs.com
# O buscar en otras ubicaciones
cat /etc/nginx/conf.d/webmail.conf

# 2. Verificar si PHP-FPM está corriendo
systemctl status php8.1-fpm
# O
systemctl status php-fpm

# 3. Ver puertos en uso
netstat -tulpn | grep LISTEN
# O
ss -tulpn | grep LISTEN

# 4. Ver logs de Nginx
tail -20 /var/log/nginx/error.log
tail -20 /var/log/nginx/webmail-error.log
```

### Opción B: Usar la Gestión de Servicios

1. En EasyPanel, ve a **"Services"** o **"Servicios"**
2. Busca estos servicios y verifica su estado:
   - `nginx` - Debe estar **Running** (Verde)
   - `php8.1-fpm` o `php-fpm` - Debe estar **Running** (Verde)
   - `postfix` (si aplica)
   - `dovecot` (si aplica)

3. Si algún servicio está **Stopped** (Rojo), haz clic en **"Start"** o **"Iniciar"**

### Opción C: Ver Logs desde EasyPanel

1. Ve a **"Logs"** o **"Registros"** en EasyPanel
2. Busca los logs de:
   - **Nginx Error Log**
   - **Webmail Error Log** (si existe)
3. Revisa las últimas líneas buscando errores como:
   - `503 Service Unavailable`
   - `Connection refused`
   - `upstream timed out`

## 🔧 Paso 2: Solucionar el Problema

### Solución 1: Si PHP-FPM no está corriendo

#### Desde la Terminal de EasyPanel:

```bash
# Iniciar PHP-FPM
sudo systemctl start php8.1-fpm
# O la versión que tengas
sudo systemctl start php-fpm

# Habilitar para que inicie automáticamente
sudo systemctl enable php8.1-fpm
sudo systemctl enable php-fpm

# Verificar que esté corriendo
sudo systemctl status php8.1-fpm
```

#### Desde la Interfaz de EasyPanel:

1. Ve a **"Services"** / **"Servicios"**
2. Busca `php8.1-fpm` o `php-fpm`
3. Si está detenido, haz clic en **"Start"** o **"Iniciar"**
4. Opcionalmente, habilita **"Auto Start"** o **"Inicio Automático"**

### Solución 2: Si el webmail usa Docker

#### Desde la Terminal de EasyPanel:

```bash
# Ver contenedores de webmail
docker ps -a | grep -i webmail
docker ps -a | grep -i roundcube

# Iniciar el contenedor si está detenido
docker start nombre_del_contenedor

# O si usas docker-compose
cd /ruta/al/docker-compose
docker-compose up -d
```

#### Desde la Interfaz de EasyPanel:

1. Ve a **"Docker"** o **"Containers"** en EasyPanel
2. Busca el contenedor del webmail (roundcube, webmail, etc.)
3. Si está detenido, haz clic en **"Start"** o **"Iniciar"**

### Solución 3: Si el webmail usa Node.js

#### Desde la Terminal de EasyPanel:

```bash
# Ver procesos Node.js
ps aux | grep node

# Si no hay proceso, iniciar el servidor
cd /ruta/del/proyecto/webmail
node server.js
# O con PM2
pm2 start server.js --name webmail
pm2 save
```

#### Desde EasyPanel (si tienes PM2 instalado):

1. Ve a **"Process Manager"** o busca **"PM2"**
2. Inicia el proceso del webmail desde ahí

### Solución 4: Verificar y Recargar Nginx

#### Desde la Terminal de EasyPanel:

```bash
# Verificar configuración de Nginx
sudo nginx -t

# Si está correcta, recargar Nginx
sudo systemctl reload nginx
# O
sudo service nginx reload
```

#### Desde la Interfaz de EasyPanel:

1. Ve a **"Services"** / **"Servicios"**
2. Busca `nginx`
3. Haz clic en **"Reload"** o **"Recargar"**

## 🎯 Paso 3: Verificar la Configuración de Nginx

### Desde EasyPanel - Editor de Archivos

1. Ve a **"Files"** / **"Archivos"** o **"File Manager"**
2. Navega a `/etc/nginx/sites-available/`
3. Abre el archivo de configuración del webmail (ej: `webmail.checkin24hs.com`)
4. Verifica que la configuración sea correcta:

#### Si el webmail usa PHP (Roundcube):

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name webmail.checkin24hs.com mail.checkin24hs.com;
    
    root /usr/share/roundcube;
    index index.php index.html;
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

#### Si el webmail usa Docker/Proxy:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name webmail.checkin24hs.com mail.checkin24hs.com;
    
    location / {
        proxy_pass http://localhost:8080;  # Ajusta el puerto
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

5. Guarda los cambios
6. Recarga Nginx (ver Solución 4)

## 📊 Paso 4: Monitoreo en Tiempo Real

### Ver Logs en Tiempo Real desde EasyPanel

1. Ve a **"Logs"** / **"Registros"**
2. Selecciona **"Nginx Error Log"** o **"Webmail Error Log"**
3. Haz clic en **"Follow"** o **"Seguir"** para ver logs en tiempo real
4. Intenta acceder al webmail desde otro navegador
5. Observa los errores que aparecen en los logs

### Ver Estado de Servicios

1. Ve a **"Dashboard"** o **"Panel Principal"** de EasyPanel
2. Revisa el estado de los servicios:
   - ✅ Verde = Funcionando
   - ❌ Rojo = Detenido
   - ⚠️ Amarillo = Advertencia

## 🔄 Paso 5: Reiniciar Todo (Último Recurso)

Si nada funciona, reinicia los servicios en este orden:

### Desde EasyPanel - Services:

1. **Reiniciar PHP-FPM:**
   - Busca `php8.1-fpm` o `php-fpm`
   - Haz clic en **"Restart"** o **"Reiniciar"**

2. **Reiniciar Nginx:**
   - Busca `nginx`
   - Haz clic en **"Restart"** o **"Reiniciar"**

3. **Si usas Docker, reiniciar el contenedor:**
   - Ve a **"Docker"** / **"Containers"**
   - Busca el contenedor del webmail
   - Haz clic en **"Restart"** o **"Reiniciar"**

## ✅ Verificación Final

1. Desde EasyPanel, ve a **"Sites"** / **"Sitios"** o **"Applications"**
2. Busca el webmail (`webmail.checkin24hs.com`)
3. Verifica que el estado sea **"Running"** o **"Activo"**
4. Haz clic en el enlace para abrir el webmail
5. Deberías ver la página de login, no el error 503

## 🆘 Comandos Rápidos para la Terminal de EasyPanel

Copia y pega estos comandos en la terminal de EasyPanel para un diagnóstico rápido:

```bash
# Diagnóstico completo
echo "=== Estado de Servicios ==="
systemctl status nginx php8.1-fpm --no-pager
echo ""
echo "=== Puertos en uso ==="
netstat -tulpn | grep -E ':(80|443|8080|3000|9000)'
echo ""
echo "=== Últimos errores de Nginx ==="
tail -10 /var/log/nginx/error.log
echo ""
echo "=== Contenedores Docker ==="
docker ps -a | grep -i mail
```

## 📝 Notas Importantes

- EasyPanel generalmente requiere permisos de administrador para algunas acciones
- Si no ves ciertas opciones, puede que necesites permisos adicionales
- Los nombres de las secciones pueden variar según la versión de EasyPanel
- Siempre verifica los logs después de hacer cambios

## 🔗 Recursos Adicionales

- Consulta `SOLUCION_ERROR_503.md` para más detalles técnicos
- Consulta `SOLUCION_WEBMAIL.md` para configuración completa del webmail

