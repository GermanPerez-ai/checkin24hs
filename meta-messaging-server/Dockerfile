# Meta Messaging Server - Flor IA (Instagram + Facebook Messenger)
FROM node:20-slim

WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY server.js ./

EXPOSE 3010
ENV PORT=3010
CMD ["node", "server.js"]
