# Dockerfile para WhatsApp Server - Checkin24hs
# Usa Node.js con Chromium para whatsapp-web.js

FROM node:18-slim

# Actualizar sistema e instalar dependencias básicas primero
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependencias de Chromium (versión completa con todas las librerías)
# Incluyendo todas las dependencias necesarias para Chromium/Puppeteer
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-sandbox \
    ca-certificates \
    fonts-liberation \
    libappindicator3-1 \
    libappindicator1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libnss3-dev \
    libnss3-tools \
    libnssutil3 \
    libssl3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    lsb-release \
    wget \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Verificar que las librerías necesarias estén disponibles
RUN ldconfig || true

# Crear directorio para librerías de Puppeteer Chromium (si se descarga)
RUN mkdir -p /app/node_modules/puppeteer-core/.local-chromium/linux-1045629/chrome-linux/lib || true

# Copiar librerías del sistema al directorio de Puppeteer Chromium después de que se descargue
# Esto se hará en un script de inicio

# Variables de entorno para Puppeteer
# Permitir que Puppeteer descargue Chromium pero asegurar que tenga las librerías necesarias
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMIUM_FLAGS="--no-sandbox --disable-setuid-sandbox"
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm install --production

# Copiar código fuente
COPY . .

# Crear directorios necesarios
RUN mkdir -p logs .wwebjs_auth

# Copiar script de fix de librerías
COPY fix-chromium-libs.sh /app/fix-chromium-libs.sh
RUN chmod +x /app/fix-chromium-libs.sh

# Puerto del servidor
EXPOSE 3001

# Variable de entorno para el puerto
ENV PORT=3001

# Comando de inicio usando el script que arregla las librerías
CMD ["/app/fix-chromium-libs.sh"]

