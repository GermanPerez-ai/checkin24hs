# checkin24hs-web (www.checkin24hs.com)
# Build: Vite. Serve: nginx en puerto 80 (interno del contenedor).
# Traefik enlaza por host; no hay conflicto con cotizador/webmail (mismo puerto interno, distinto contenedor).

FROM node:18-alpine AS builder

# Cambiar BUILD_REV cuando quieras forzar rebuild sin caché (ej. 2, 3...)
ARG BUILD_REV=1
RUN echo "Build rev: $BUILD_REV"

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Verificar que el contexto de build incluye carruseles (detecta contexto vacío o viejo)
RUN test -f /app/src/components/AlojamientosCarousel.tsx && test -f /app/src/components/Novedades.tsx && grep -q "carousel" /app/src/components/Novedades.tsx || (echo "ERROR: En el build NO esta el codigo de carruseles. Revisar: (1) git pull en el servidor, (2) que el build use context ./checkin24hs-web." && exit 1)

# Variables de build: se inyectan en tiempo de build vía ARG (EasyPanel o CI)
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY
ARG VITE_COTIZADOR_URL
ARG VITE_FLOR_CHATBOT_URL
ARG VITE_FLOR_API_URL
ARG VITE_WHATSAPP_NUMBER
ENV VITE_SUPABASE_URL=$VITE_SUPABASE_URL
ENV VITE_SUPABASE_ANON_KEY=$VITE_SUPABASE_ANON_KEY
ENV VITE_COTIZADOR_URL=$VITE_COTIZADOR_URL
ENV VITE_FLOR_CHATBOT_URL=$VITE_FLOR_CHATBOT_URL
ENV VITE_FLOR_API_URL=$VITE_FLOR_API_URL
ENV VITE_WHATSAPP_NUMBER=$VITE_WHATSAPP_NUMBER

RUN npm run build

# Verificar que el bundle incluye carruseles (evita desplegar código viejo)
RUN grep -rqE "carousel|AlojamientosCarousel|alojamientos-layout" /app/dist || (echo "ERROR: dist no contiene carruseles; revisar checkin24hs-web" && exit 1)

# Etapa de producción: nginx sirve los estáticos
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html

RUN echo 'server { \
    listen 80; \
    listen [::]:80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    location ~* \.(js|css)$ { \
        expires 1d; \
        add_header Cache-Control "public, max-age=86400"; \
    } \
    location ~* \.(png|jpg|jpeg|gif|ico|svg|webp|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
    location / { \
        add_header Cache-Control "no-cache, no-store, must-revalidate"; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
