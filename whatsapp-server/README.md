# 🌸 WhatsApp Flor - Checkin24hs

Servidor de WhatsApp integrado con Flor para respuestas automáticas.

## ✅ Características

- ✅ Usa WhatsApp en el teléfono mientras Flor responde
- ✅ Respuestas automáticas inteligentes
- ✅ Panel web para ver código QR
- ✅ API para enviar mensajes desde el CRM
- ✅ Registro de conversaciones

## 📋 Requisitos

- Node.js 16 o superior
- Google Chrome o Chromium (se instala automáticamente con puppeteer)

## 🚀 Instalación Local

```bash
cd whatsapp-server
npm install
npm start
```

## 📱 Conectar WhatsApp

1. Abre http://localhost:3001 en tu navegador
2. Abre WhatsApp en tu teléfono
3. Ve a **Configuración > Dispositivos vinculados**
4. Toca **Vincular un dispositivo**
5. Escanea el código QR

## 🌐 API Endpoints

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/api/status` | GET | Estado de conexión |
| `/api/qr` | GET | Obtener código QR |
| `/api/send` | POST | Enviar mensaje |
| `/api/toggle-auto-reply` | POST | Activar/desactivar respuestas |
| `/api/toggle-flor` | POST | Activar/desactivar Flor |
| `/api/messages/today` | GET | Mensajes del día |

### Enviar mensaje

```bash
curl -X POST http://localhost:3001/api/send \
  -H "Content-Type: application/json" \
  -d '{"number": "5491112345678", "message": "Hola!"}'
```

## 🖥️ Desplegar en Servidor

### Opción 1: VPS con Docker

```dockerfile
FROM node:18-slim

# Instalar Chrome
RUN apt-get update && apt-get install -y \
    chromium \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

EXPOSE 3001
CMD ["npm", "start"]
```

### Opción 2: PM2 (en VPS directamente)

```bash
# En el servidor
npm install -g pm2
cd whatsapp-server
npm install
pm2 start whatsapp-server.js --name "whatsapp-flor"
pm2 save
pm2 startup
```

## 🔧 Configuración

Edita las variables en `whatsapp-server.js`:

```javascript
const CONFIG = {
    PORT: 3001,
    AUTO_REPLY: true,      // Respuestas automáticas
    FLOR_ENABLED: true,    // Flor activa
    AGENT_NUMBERS: [       // Números que NO reciben auto-respuesta
        '5491112345678@c.us'
    ]
};
```

## 📝 Personalizar Respuestas de Flor

Edita `FLOR_KNOWLEDGE` en el archivo para personalizar:

- Saludo
- Despedida
- Información de hoteles
- Precios
- Contacto

## ⚠️ Notas Importantes

1. **No cierres la sesión en el teléfono** - Solo desvincula desde Configuración
2. **La sesión persiste** - No necesitas escanear QR cada vez
3. **Múltiples dispositivos** - WhatsApp permite hasta 4 dispositivos vinculados
4. **Grupos** - Flor NO responde en grupos, solo chats individuales

## 🆘 Solución de Problemas

### El QR no aparece
- Borra la carpeta `.wwebjs_auth` y reinicia

### Se desconecta frecuentemente
- Verifica la conexión a internet del servidor
- Revisa que el teléfono tenga WhatsApp actualizado

### Error de Puppeteer
- Instala las dependencias de Chrome:
```bash
sudo apt-get install -y libgbm-dev gconf-service libasound2
```

