FROM node:18-alpine

# Forzar reconstrucción sin caché - 2026-01-24
# CRÍTICO: Fix 404 favicon/index - cambiar REBUILD_404 para invalidar caché
ARG BUILD_DATE=2026-01-24T00:00:00Z
ARG BUILD_NUMBER=67
WORKDIR /app

# Copiar package.json e instalar dependencias
COPY package.json package-lock.json* ./
RUN npm install

# IMPORTANTE: Copiar dashboard.html ANTES que otros archivos para forzar actualización
COPY dashboard.html ./

# Verificar que dashboard.html tiene Build #63 (o superior)
RUN BUILD_NUM=$(grep -oP "DASHBOARD_BUILD_NUMBER = \K\d+" dashboard.html | head -1) && \
    echo "📦 Build Number en dashboard.html: #$BUILD_NUM" && \
    if [ "$BUILD_NUM" -lt 63 ]; then \
        echo "⚠️ ADVERTENCIA: Build Number es #$BUILD_NUM, se espera #63 o superior"; \
    else \
        echo "✅ Build Number correcto: #$BUILD_NUM"; \
    fi

# Forzar rebuild de server.js (fix 404 favicon/index): cambiar fecha abajo para invalidar caché
RUN echo "Rebuild 404 fix: 2026-01-24"
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
