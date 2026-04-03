# 🚀 Guía Completa: Configurar WhatsApp en VPS

## ✅ Por Qué VPS

- ✅ **Control total** - Acceso SSH directo
- ✅ **Más recursos** - Sin límites de EasyPanel
- ✅ **Más fácil de debuggear** - Ves los logs directamente
- ✅ **Funciona con whatsapp-web.js** sin problemas
- ✅ **Soporta 4 WhatsApp** simultáneamente
- ✅ **Más rápido** - Listo en 30 minutos

## 📋 Requisitos del VPS

### Mínimos Recomendados:
- **CPU**: 2 núcleos
- **RAM**: 4 GB (mínimo 2 GB)
- **Disco**: 20 GB
- **OS**: Ubuntu 20.04 o 22.04 (recomendado)

### Proveedores Recomendados:
- **DigitalOcean**: $12/mes (2GB RAM)
- **Vultr**: $12/mes (2GB RAM)
- **Linode**: $12/mes (2GB RAM)
- **Hetzner**: €4.15/mes (4GB RAM) - Más barato

## 🎯 Paso 1: Conectar al VPS

1. **Obtén la IP y credenciales** de tu VPS
2. **Conecta por SSH**:
   ```bash
   ssh root@TU_IP
   ```
   O si usas usuario:
   ```bash
   ssh usuario@TU_IP
   ```

## 🎯 Paso 2: Instalar Node.js

```bash
# Actualizar sistema
apt update && apt upgrade -y

# Instalar Node.js 20 (LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Verificar instalación
node --version  # Debe ser v20.x.x
npm --version
```

## 🎯 Paso 3: Instalar Dependencias del Sistema

```bash
# Instalar Chrome/Chromium para whatsapp-web.js
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
```

## 🎯 Paso 4: Instalar PM2 (Gestor de Procesos)

```bash
# Instalar PM2 globalmente
npm install -g pm2

# Configurar PM2 para iniciar al arrancar
pm2 startup
# Copia y ejecuta el comando que te muestra
```

## 🎯 Paso 5: Clonar el Repositorio

```bash
# Ir a directorio home
cd ~

# Clonar tu repositorio (o subir los archivos)
git clone https://github.com/GermanPerez-ai/checkin24hs.git
cd checkin24hs/whatsapp-server

# O si prefieres, crear el directorio manualmente
# mkdir -p ~/whatsapp-server
# cd ~/whatsapp-server
```

## 🎯 Paso 6: Instalar Dependencias del Proyecto

```bash
# En el directorio whatsapp-server
npm install
```

## 🎯 Paso 7: Configurar Variables de Entorno

```bash
# Crear archivo .env
nano .env
```

Agregar:
```env
PORT=3001
INSTANCE_NUMBER=1
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

Guardar: `Ctrl+O`, `Enter`, `Ctrl+X`

## 🎯 Paso 8: Configurar Chrome para WhatsApp

```bash
# Crear script de inicio que configure Chrome
nano ~/whatsapp-server/start.sh
```

Agregar:
```bash
#!/bin/bash
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
node whatsapp-server.js
```

Hacer ejecutable:
```bash
chmod +x ~/whatsapp-server/start.sh
```

## 🎯 Paso 9: Iniciar con PM2

```bash
# Desde el directorio whatsapp-server
cd ~/whatsapp-server

# Iniciar con PM2
pm2 start whatsapp-server.js --name whatsapp-1 --env PORT=3001 --env INSTANCE_NUMBER=1

# O usar el script
pm2 start start.sh --name whatsapp-1

# Ver logs
pm2 logs whatsapp-1

# Ver estado
pm2 status

# Guardar configuración para que inicie al arrancar
pm2 save
```

## 🎯 Paso 10: Configurar Múltiples Instancias (4 WhatsApp)

Para 4 WhatsApp, necesitas 4 procesos diferentes:

```bash
# WhatsApp 1 (puerto 3001)
cd ~/whatsapp-server
pm2 start whatsapp-server.js --name whatsapp-1 \
  --env PORT=3001 --env INSTANCE_NUMBER=1

# WhatsApp 2 (puerto 3002)
pm2 start whatsapp-server.js --name whatsapp-2 \
  --env PORT=3002 --env INSTANCE_NUMBER=2

# WhatsApp 3 (puerto 3003)
pm2 start whatsapp-server.js --name whatsapp-3 \
  --env PORT=3003 --env INSTANCE_NUMBER=3

# WhatsApp 4 (puerto 3004)
pm2 start whatsapp-server.js --name whatsapp-4 \
  --env PORT=3004 --env INSTANCE_NUMBER=4

# Guardar configuración
pm2 save
```

## 🎯 Paso 11: Configurar Firewall

```bash
# Permitir puertos 3001-3004
ufw allow 3001/tcp
ufw allow 3002/tcp
ufw allow 3003/tcp
ufw allow 3004/tcp

# Activar firewall
ufw enable
```

## 🎯 Paso 12: Configurar Nginx (Opcional - Para Dominios)

Si quieres usar dominios como `whatsapp1.checkin24hs.com`:

```bash
# Instalar Nginx
apt install -y nginx

# Crear configuración para cada instancia
nano /etc/nginx/sites-available/whatsapp1
```

Agregar:
```nginx
server {
    listen 80;
    server_name whatsapp1.checkin24hs.com;

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

Activar:
```bash
ln -s /etc/nginx/sites-available/whatsapp1 /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## 📋 Comandos Útiles de PM2

```bash
# Ver todos los procesos
pm2 list

# Ver logs de una instancia
pm2 logs whatsapp-1

# Ver logs de todas
pm2 logs

# Reiniciar una instancia
pm2 restart whatsapp-1

# Detener una instancia
pm2 stop whatsapp-1

# Eliminar una instancia
pm2 delete whatsapp-1

# Ver uso de recursos
pm2 monit

# Reiniciar todas
pm2 restart all
```

## 🔍 Verificar que Funciona

1. **Ver logs**:
   ```bash
   pm2 logs whatsapp-1
   ```

2. **Deberías ver**:
   ```
   🚀 Iniciando servidor WhatsApp...
   📡 Servidor corriendo en puerto 3001
   ⏳ Inicializando WhatsApp...
   📱 Escanea el código QR...
   ```

3. **Acceder al panel web**:
   - Abre en navegador: `http://TU_IP:3001`
   - Deberías ver el código QR

## 🎯 Paso 13: Actualizar Dashboard

En tu dashboard, actualiza las URLs de los servidores:

- WhatsApp 1: `http://TU_IP:3001`
- WhatsApp 2: `http://TU_IP:3002`
- WhatsApp 3: `http://TU_IP:3003`
- WhatsApp 4: `http://TU_IP:3004`

## ✅ Ventajas del VPS

- ✅ **Logs en tiempo real** - `pm2 logs whatsapp-1`
- ✅ **Control total** - Reiniciar, detener, ver estado
- ✅ **Más recursos** - Sin límites
- ✅ **Más rápido** - Sin problemas de EasyPanel
- ✅ **4 WhatsApp** - Fácil de configurar

## 🆘 Solución de Problemas

### Si Chrome no funciona:
```bash
# Verificar que Chrome está instalado
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

### Si PM2 no inicia al arrancar:
```bash
# Reconfigurar
pm2 startup
# Ejecutar el comando que muestra
pm2 save
```

## 🎯 Próximos Pasos

1. **Contratar VPS** (DigitalOcean, Vultr, Hetzner)
2. **Seguir esta guía paso a paso**
3. **Configurar 4 instancias**
4. **Conectar desde el dashboard**

¿Necesitas ayuda con algún paso específico?

