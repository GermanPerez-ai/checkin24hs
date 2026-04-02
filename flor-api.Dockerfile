# EasyPanel: al bajar el repo como archive, GitHub extrae en una carpeta
# tipo checkin24hs-main. Opciones:
# A) En EasyPanel "Ruta de compilación" = checkin24hs-main (y este ARG no hace falta)
# B) Si dejás "Ruta de compilación" = / , en EasyPanel añadí build-arg REPO_DIR=checkin24hs-main
ARG REPO_DIR=.
FROM node:20-alpine
WORKDIR /app
COPY ${REPO_DIR}/flor-web-api/package*.json ./
RUN npm install --production
COPY ${REPO_DIR}/flor-web-api/server.js ./
EXPOSE 8080
ENV PORT=8080
CMD ["node", "server.js"]
