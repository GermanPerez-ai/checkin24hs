# Dockerfile para WhatsApp Server - Checkin24hs (Flor IA + Baileys)
# Optimizado: persistencia de sesión, menos tokens (RAG selectivo), backoff 429.

FROM node:20-slim

# Dependencias para compilación de Baileys (native modules) + ffmpeg para convertir audio webm→ogg (notas de voz)
RUN apt-get update && apt-get install -y \
    python3 make g++ ca-certificates git ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /app
COPY package*.json ./
# Instalar dependencias (sin caché de npm para evitar imágenes sin Baileys)
RUN npm install --production --no-optional && \
    node -e "require('@whiskeysockets/baileys')" || (echo "FATAL: Baileys no instalado" && exit 1)
COPY whatsapp-server-baileys.js ./
COPY whatsapp-server.js ./
COPY huilo-parse.js ./
COPY huilo-group-reservations.js ./

# Carpetas para persistencia de sesión WhatsApp (montar volumen en EasyPanel)
RUN mkdir -p logs auth_info_baileys_1 auth_info_baileys_2 auth_info_baileys_3 auth_info_baileys_4

EXPOSE 3001
ENV PORT=3001
CMD ["node", "whatsapp-server-baileys.js"]
