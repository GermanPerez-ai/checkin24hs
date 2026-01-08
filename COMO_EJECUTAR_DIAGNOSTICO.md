# 📍 Dónde y Cómo Ejecutar el Diagnóstico

## ⚠️ Importante

El script de diagnóstico **DEBE ejecutarse en el servidor** donde está desplegado el webmail, **NO en tu computadora local**.

## 🖥️ Opción 1: Ejecutar en el Servidor (Recomendado)

### Paso 1: Conectarte al Servidor

Necesitas conectarte al servidor usando SSH. Tienes varias opciones:

#### Si tienes acceso SSH directo:

```bash
# Conectarte al servidor
ssh usuario@ip_del_servidor
# O
ssh usuario@webmail.checkin24hs.com
```

**Ejemplo:**
```bash
ssh root@192.168.1.100
# O
ssh admin@servidor.checkin24hs.com
```

#### Si usas un panel de control (cPanel, Plesk, etc.):

1. Accede al panel de control
2. Busca la opción **"Terminal"**, **"SSH"** o **"Consola"**
3. Abre la terminal desde ahí

#### Si usas un servicio de hosting:

- **DigitalOcean, AWS, Azure, etc.**: Usa la consola web o conecta por SSH
- **Hosting compartido**: Puede que no tengas acceso SSH, en ese caso usa la Opción 2

### Paso 2: Subir el Script al Servidor

Una vez conectado al servidor, necesitas tener el script ahí. Opciones:

#### Opción A: Crear el script directamente en el servidor

```bash
# En el servidor, crea el archivo
nano diagnosticar-503.sh
```

Luego copia y pega el contenido del archivo `diagnosticar-503.sh` que está en tu proyecto.

#### Opción B: Subir el archivo usando SCP

Desde tu computadora Windows (PowerShell):

```powershell
# Subir el archivo al servidor
scp diagnosticar-503.sh usuario@ip_del_servidor:/home/usuario/
```

#### Opción C: Usar FTP/SFTP

1. Conecta con un cliente FTP (FileZilla, WinSCP, etc.)
2. Sube el archivo `diagnosticar-503.sh` al servidor
3. Colócalo en una carpeta accesible (ej: `/home/usuario/` o `/tmp/`)

### Paso 3: Ejecutar el Script

Una vez que el archivo está en el servidor:

```bash
# Dar permisos de ejecución
chmod +x diagnosticar-503.sh

# Ejecutar el script
bash diagnosticar-503.sh
# O
./diagnosticar-503.sh
```

## 💻 Opción 2: Ejecutar Comandos Manualmente

Si no puedes ejecutar el script, puedes ejecutar los comandos manualmente uno por uno:

### 1. Verificar configuración de Nginx

```bash
sudo cat /etc/nginx/sites-available/webmail.checkin24hs.com
# O buscar en otras ubicaciones
sudo cat /etc/nginx/conf.d/webmail.conf
sudo cat /etc/nginx/sites-enabled/webmail.checkin24hs.com
```

### 2. Verificar si PHP-FPM está corriendo

```bash
sudo systemctl status php8.1-fpm
# O
sudo systemctl status php-fpm
```

### 3. Verificar puertos en uso

```bash
sudo netstat -tulpn | grep LISTEN
# O
sudo ss -tulpn | grep LISTEN
```

### 4. Verificar contenedores Docker

```bash
docker ps -a | grep -i mail
```

### 5. Ver logs de Nginx

```bash
sudo tail -f /var/log/nginx/webmail-error.log
sudo tail -f /var/log/nginx/error.log
```

## 🔧 Opción 3: Si No Tienes Acceso SSH

Si no tienes acceso SSH al servidor, necesitas:

1. **Contactar al administrador del servidor** para que ejecute el diagnóstico
2. **Usar el panel de control** (cPanel, Plesk) si tiene terminal disponible
3. **Solicitar acceso SSH** al proveedor de hosting

## 📋 Resumen de Comandos Rápidos

```bash
# 1. Conectarte al servidor
ssh usuario@ip_del_servidor

# 2. Navegar a donde subiste el script (o crearlo)
cd ~
nano diagnosticar-503.sh  # Pegar el contenido

# 3. Dar permisos y ejecutar
chmod +x diagnosticar-503.sh
bash diagnosticar-503.sh
```

## ❓ ¿Cómo Saber la IP o Dominio del Servidor?

- **Si tienes acceso al panel de control**: Busca la sección "Información del Servidor" o "Detalles de la Cuenta"
- **Si usas un VPS**: Revisa el email de bienvenida del proveedor
- **Si no sabes**: Contacta a tu proveedor de hosting o al administrador del sistema

## 🆘 Si No Puedes Conectarte

Si no puedes conectarte al servidor, puedes:

1. **Compartir los archivos de diagnóstico** (`SOLUCION_ERROR_503.md` y `diagnosticar-503.sh`) con quien tenga acceso
2. **Pedirle que ejecute el script** y te comparta los resultados
3. **Usar los comandos manuales** de la Opción 2

## 📝 Nota Importante

El script necesita permisos de administrador (sudo) para algunas verificaciones. Si no tienes permisos sudo, algunos comandos pueden fallar, pero aún así obtendrás información útil.

