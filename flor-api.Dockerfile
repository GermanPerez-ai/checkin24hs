# Proxy Flor (flor-web-api). Compatible con:
# - Raíz del repo: ./flor-web-api/...
# - ZIP de GitHub: ./<carpeta>-main/flor-web-api/... (nombre variable)
#
# Etapa 1: localizar flor-web-api aunque venga anidada una carpeta.
FROM node:20-alpine AS prep
WORKDIR /ctx
COPY . .
RUN S=$(find . -type f -path '*/flor-web-api/server.js' | head -n1) && \
    if [ -z "$S" ]; then \
      echo "ERROR: No se encontró flor-web-api/server.js en el contexto de build."; \
      echo "Contenido (máx. 3 niveles):"; \
      find . -maxdepth 3 -type d 2>/dev/null || ls -laR; \
      exit 1; \
    fi && \
    D=$(dirname "$S") && \
    echo "Usando: $D" && \
    mkdir -p /out && \
    cp "$D/package.json" /out/ && \
    cp "$D/server.js" /out/

FROM node:20-alpine
WORKDIR /app
COPY --from=prep /out/package.json ./
RUN npm install --production
COPY --from=prep /out/server.js ./
EXPOSE 8080
ENV PORT=8080
CMD ["node", "server.js"]
