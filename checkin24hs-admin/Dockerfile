# Dockerfile para checkin24hs-admin (React App)
FROM node:18-alpine AS builder

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto de los archivos
COPY . .

# Construir la aplicación React
RUN npm run build

# Etapa de producción - servir archivos estáticos
FROM node:18-alpine

WORKDIR /app

# Copiar los archivos construidos desde la etapa anterior
COPY --from=builder /app/build ./build

# Copiar server.js real (con la ruta /og-cotizar.jpg)
COPY server.js ./server.js

# Nota: Las imágenes de hoteles se buscarán dinámicamente por el servidor
# desde múltiples ubicaciones posibles (../hotel-images o ./hotel-images)
# Si necesitas las imágenes, asegúrate de que estén disponibles en el contexto de build

# Exponer el puerto 3000
EXPOSE 3000

# Comando para iniciar el servidor
CMD ["node", "server.js"]
