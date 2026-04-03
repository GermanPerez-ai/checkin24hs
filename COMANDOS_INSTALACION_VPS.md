# 🚀 Comandos de Instalación - VPS WhatsApp

## ✅ Estado Actual

- ✅ Conectado al VPS
- ✅ Ubuntu 24.04.3 LTS
- ✅ IP: 72.61.58.240
- ⚠️ Hay 20 actualizaciones pendientes

## 🎯 Paso 1: Actualizar el Sistema

Copia y pega este comando:

```bash
apt update && apt upgrade -y
```

**Esto puede tardar 2-3 minutos**

## 🎯 Paso 2: Instalar Node.js 20

Copia y pega estos comandos uno por uno:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
```

```bash
apt install -y nodejs
```

```bash
node --version
```

**Deberías ver**: `v20.x.x`

## 🎯 Paso 3: Instalar Chrome/Chromium

Copia y pega este comando:

```bash
apt install -y chromium-browser fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 libx11-xcb1 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 xdg-utils
```

**Esto puede tardar 1-2 minutos**

## 🎯 Paso 4: Verificar Chrome

```bash
which chromium-browser
```

**Deberías ver**: `/usr/bin/chromium-browser`

## 🎯 Paso 5: Instalar PM2

```bash
npm install -g pm2
```

## 🎯 Paso 6: Configurar PM2 para Iniciar al Arrancar

```bash
pm2 startup
```

**IMPORTANTE**: Copia y ejecuta el comando que te muestra (algo como `sudo env PATH=...`)

## 🎯 Paso 7: Clonar el Repositorio

```bash
cd ~
```

```bash
git clone https://github.com/GermanPerez-ai/checkin24hs.git
```

## 🎯 Paso 8: Ir al Directorio del Servidor

```bash
cd checkin24hs/whatsapp-server
```

## 🎯 Paso 9: Instalar Dependencias

```bash
npm install
```

**Esto puede tardar 2-3 minutos**

## 🎯 Paso 10: Crear Directorio de Logs

```bash
mkdir -p logs
```

## 🎯 Paso 11: Iniciar Primera Instancia (WhatsApp 1)

```bash
pm2 start whatsapp-server.js --name whatsapp-1 --env PORT=3001 --env INSTANCE_NUMBER=1 --env SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co --env SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

## 🎯 Paso 12: Ver Logs y QR

```bash
pm2 logs whatsapp-1
```

**Deberías ver el código QR** - Presiona `Ctrl+C` para salir de los logs

## 🎯 Paso 13: Ver Estado

```bash
pm2 status
```

**Deberías ver**: `whatsapp-1` en estado "online"

## 🎯 Paso 14: Guardar Configuración PM2

```bash
pm2 save
```

## 🎯 Paso 15: Configurar Firewall

```bash
ufw allow 3001/tcp
ufw allow 3002/tcp
ufw allow 3003/tcp
ufw allow 3004/tcp
ufw enable
```

## 🎯 Paso 16: Iniciar las Otras 3 Instancias

```bash
pm2 start whatsapp-server.js --name whatsapp-2 --env PORT=3002 --env INSTANCE_NUMBER=2 --env SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co --env SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

```bash
pm2 start whatsapp-server.js --name whatsapp-3 --env PORT=3003 --env INSTANCE_NUMBER=3 --env SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co --env SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

```bash
pm2 start whatsapp-server.js --name whatsapp-4 --env PORT=3004 --env INSTANCE_NUMBER=4 --env SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co --env SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

## 🎯 Paso 17: Ver Todas las Instancias

```bash
pm2 list
```

**Deberías ver**: 4 instancias (whatsapp-1, whatsapp-2, whatsapp-3, whatsapp-4) todas en "online"

## 🎯 Paso 18: Guardar Todo

```bash
pm2 save
```

## ✅ Verificación Final

1. **Ver estado**: `pm2 status`
2. **Ver logs de WhatsApp 1**: `pm2 logs whatsapp-1`
3. **Acceder al panel web**: `http://72.61.58.240:3001`

## 📱 Acceder a los Paneles Web

- WhatsApp 1: `http://72.61.58.240:3001`
- WhatsApp 2: `http://72.61.58.240:3002`
- WhatsApp 3: `http://72.61.58.240:3003`
- WhatsApp 4: `http://72.61.58.240:3004`

