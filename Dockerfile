FROM node:18-alpine

WORKDIR /app

# Copiar package.json e instalar dependencias
COPY package.json package-lock.json* ./
RUN npm install

# Copiar todos los archivos del proyecto (excepto node_modules, .git, etc.)
COPY dashboard.html ./
COPY server.js ./
COPY supabase-client.js ./
COPY supabase-config.js ./
COPY database.js ./
COPY dashboard-integration.js ./
COPY flor-agent.js ./
COPY flor-ai-service.js ./
COPY flor-knowledge-base.js ./
COPY flor-learning-system.js ./
COPY flor-multimodal-service.js ./
COPY flor-widget.js ./
COPY puppeteer-real-cotizacion.js ./
COPY logo*.png ./
COPY logo*.svg ./
COPY hotel-images/ ./hotel-images/

# Exponer el puerto 3000
EXPOSE 3000

# Comando para iniciar el servidor
CMD ["node", "server.js"]
