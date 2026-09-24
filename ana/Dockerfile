FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY collect.js server.js mail.js notify.js proposals.js jobs.js ads.js copilot.js sales-control.js ./
COPY public ./public
EXPOSE 8080
ENV PORT=8080
CMD ["node", "server.js"]
