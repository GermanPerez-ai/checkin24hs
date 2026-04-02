# EasyPanel: el contexto suele ser la raíz del repo clonado.
# Si GitHub extrae en una subcarpeta (ej. checkin24hs-main), en EasyPanel:
# - poné "Ruta de compilación" = esa carpeta, O
# - build-arg: REPO_DIR=checkin24hs-main
#
# ARG antes de FROM no aplica tras FROM; hay que redeclarar ARG aquí o COPY falla (/flor-web-api/...).
FROM node:20-alpine
ARG REPO_DIR=.
WORKDIR /app
COPY ${REPO_DIR}/flor-web-api/package*.json ./
RUN npm install --production
COPY ${REPO_DIR}/flor-web-api/server.js ./
EXPOSE 8080
ENV PORT=8080
CMD ["node", "server.js"]
