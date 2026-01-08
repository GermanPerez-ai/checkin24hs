# 🚀 Implementación Paso a Paso - VPS WhatsApp

## 📋 Checklist Pre-Implementación

Antes de empezar, necesitas:

- [ ] **VPS contratado** (DigitalOcean, Vultr, Hetzner, etc.)
- [ ] **IP del VPS** (ejemplo: 123.45.67.89)
- [ ] **Credenciales de acceso** (usuario/contraseña o SSH key)
- [ ] **Acceso SSH** al VPS

## 🎯 Paso 1: Conectar al VPS

### Si tienes Windows:
```bash
# Usar PowerShell o CMD
ssh root@TU_IP
# O si usas usuario:
ssh usuario@TU_IP
```

### Si tienes Mac/Linux:
```bash
ssh root@TU_IP
```

**Reemplaza `TU_IP` con la IP de tu VPS**

## 🎯 Paso 2: Actualizar el Sistema

```bash
# Actualizar lista de paquetes
apt update

# Actualizar sistema
apt upgrade -y
```

## 🎯 Paso 3: Instalar Node.js 20

```bash
# Instalar Node.js 20 (LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Verificar instalación
node --version
npm --version
```

**Deberías ver**: `v20.x.x` y la versión de npm

## 🎯 Paso 4: Instalar Chrome/Chromium

```bash
# Instalar Chromium y dependencias
apt install -y \
    chromium-browser \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    xdg-utils

# Verificar instalación
which chromium-browser
```

## 🎯 Paso 5: Instalar PM2

```bash
# Instalar PM2 globalmente
npm install -g pm2

# Configurar PM2 para iniciar al arrancar
pm2 startup
```

**IMPORTANTE**: Copia y ejecuta el comando que te muestra `pm2 startup`

## 🎯 Paso 6: Clonar el Repositorio

```bash
# Ir a directorio home
cd ~

# Clonar tu repositorio
git clone https://github.com/GermanPerez-ai/checkin24hs.git

# Ir al directorio del servidor
cd checkin24hs/whatsapp-server

# Verificar que estás en el directorio correcto
ls -la
```

**Deberías ver**: `whatsapp-server.js`, `package.json`, etc.

## 🎯 Paso 7: Instalar Dependencias

```bash
# Instalar dependencias de Node.js
npm install
```

**Esto puede tardar 2-3 minutos**

## 🎯 Paso 8: Crear Directorio de Logs

```bash
# Crear directorio para logs
mkdir -p logs
```

## 🎯 Paso 9: Configurar Variables de Entorno

```bash
# Crear archivo .env
nano .env
```

**Agregar estas líneas** (reemplaza con tus valores si son diferentes):

```env
PORT=3001
INSTANCE_NUMBER=1
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

**Guardar**: `Ctrl+O`, `Enter`, `Ctrl+X`

## 🎯 Paso 10: Iniciar Primera Instancia (WhatsApp 1)

```bash
# Iniciar con PM2 usando ecosystem.config.js
pm2 start ecosystem.config.js

# O iniciar manualmente:
pm2 start whatsapp-server.js --name whatsapp-1 --env PORT=3001 --env INSTANCE_NUMBER=1

# Ver estado
pm2 status
```

## 🎯 Paso 11: Ver Logs y QR

```bash
# Ver logs en tiempo real
pm2 logs whatsapp-1
```

**Deberías ver**:
```
🚀 Iniciando servidor WhatsApp...
📡 Servidor corriendo en puerto 3001
📱 Escanea el código QR...
[Código QR en ASCII]
```

## 🎯 Paso 12: Acceder al Panel Web

1. **Abre en tu navegador**: `http://TU_IP:3001`
2. **Deberías ver** el código QR en la página
3. **Escanea el QR** con tu teléfono WhatsApp

## 🎯 Paso 13: Configurar Firewall

```bash
# Permitir puertos 3001-3004
ufw allow 3001/tcp
ufw allow 3002/tcp
ufw allow 3003/tcp
ufw allow 3004/tcp

# Activar firewall
ufw enable
```

## 🎯 Paso 14: Iniciar las Otras 3 Instancias

```bash
# WhatsApp 2
pm2 start whatsapp-server.js --name whatsapp-2 --env PORT=3002 --env INSTANCE_NUMBER=2

# WhatsApp 3
pm2 start whatsapp-server.js --name whatsapp-3 --env PORT=3003 --env INSTANCE_NUMBER=3

# WhatsApp 4
pm2 start whatsapp-server.js --name whatsapp-4 --env PORT=3004 --env INSTANCE_NUMBER=4

# Guardar configuración
pm2 save

# Ver todas las instancias
pm2 list
```

## 🎯 Paso 15: Verificar que Todo Funciona

```bash
# Ver estado de todas las instancias
pm2 status

# Ver logs de todas
pm2 logs

# Ver uso de recursos
pm2 monit
```

## ✅ Verificación Final

1. **Todas las instancias en "online"**: `pm2 status`
2. **Logs muestran QR codes**: `pm2 logs whatsapp-1`
3. **Panel web accesible**: `http://TU_IP:3001`
4. **Puedes escanear QR** desde tu teléfono

## 🎯 Paso 16: Actualizar Dashboard

En tu dashboard (`deploy/dashboard.html`), actualiza las URLs:

- WhatsApp 1: `http://TU_IP:3001`
- WhatsApp 2: `http://TU_IP:3002`
- WhatsApp 3: `http://TU_IP:3003`
- WhatsApp 4: `http://TU_IP:3004`

## 📋 Comandos Útiles

```bash
# Ver logs de una instancia
pm2 logs whatsapp-1

# Reiniciar una instancia
pm2 restart whatsapp-1

# Detener una instancia
pm2 stop whatsapp-1

# Ver uso de recursos
pm2 monit

# Reiniciar todas
pm2 restart all
```

## 🆘 Si Algo Sale Mal

### Si Node.js no se instala:
```bash
# Intentar de nuevo
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
```

### Si Chrome no funciona:
```bash
# Verificar instalación
which chromium-browser
# Si no está, instalar
apt install -y chromium-browser
```

### Si el puerto está en uso:
```bash
# Ver qué está usando el puerto
lsof -i :3001
# Matar el proceso
kill -9 PID
```

## 🎯 ¿Listo para Empezar?

1. **¿Ya tienes VPS contratado?** (Sí/No)
2. **¿Tienes la IP del VPS?**
3. **¿Puedes conectarte por SSH?**

¡Dime cuando estés listo y te guío paso a paso!

