# Dashboard con dashboard.html (Usuario + Contraseña).
# Construir desde la raíz del repo: docker build -f deploy/dashboard-html/Dockerfile -t checkin24hs-dashboard-html:latest .
# Para EasyPanel: Build from Git, Dockerfile path = deploy/dashboard-html/Dockerfile, Context = . (raíz del repo). Sin bind mounts.
# Build #77 - invalida caché si cambias BUILD_ID (compose) o el archivo deploy/dashboard-html/BUILD_ID (Git-only).

FROM node:18-alpine

ARG BUILD_ID=81
ARG BUILD_SOURCE=unknown
ARG BUILD_TIME=unknown
ENV BUILD_ID=${BUILD_ID}
# Labels para saber quién y cuándo construyó esta imagen (detectar si EasyPanel/cron la reemplazó)
LABEL checkin24hs.build_source="${BUILD_SOURCE}" \
      checkin24hs.build_time="${BUILD_TIME}"
# RUN con ARG invalida caché cuando pasás --build-arg BUILD_ID=78 desde compose
RUN echo "Build $BUILD_ID" > /tmp/build.txt

WORKDIR /app

# Copiar BUILD_ID (para deploy desde Git sin compose): al cambiar el archivo se invalida la caché
COPY deploy/dashboard-html/BUILD_ID ./
# Única fuente para deploy: deploy/dashboard.html (así no hay mezcla raíz vs deploy)
COPY deploy/dashboard.html ./dashboard.html
COPY supabase-client.js ./
COPY deploy/supabase-config.js ./supabase-config.js
COPY hotel-images ./hotel-images
COPY deploy/logo.png ./logo.png
COPY deploy/dashboard-html/server.js ./server.js
# Imagen promocional para /og-cotizar.jpg (WhatsApp / Open Graph). Fallback: main.jpg si no existe hotel-images/hotel-images/og-preview.jpg
COPY hotel-images/hotel-1-puyehue/main.jpg ./og-cotizar.jpg
# build_id.txt: para comprobar qué BUILD_ID sirve la URL (diagnóstico caché vs imagen)
RUN echo "$BUILD_ID" > /app/build_id.txt

EXPOSE 3000
CMD ["node", "server.js"]
