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

# Copiar el servidor HTTP simple
COPY server.js ./

# Copiar los archivos construidos desde la etapa anterior
COPY --from=builder /app/build ./build

# Exponer el puerto 3000
EXPOSE 3000

# Comando para iniciar el servidor
CMD ["node", "server.js"]

