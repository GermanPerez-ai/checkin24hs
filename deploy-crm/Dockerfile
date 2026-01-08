FROM nginx:alpine

# Versión para invalidar cache - cambiar este número para forzar rebuild
ARG CACHE_BUST=v2.1

# Copiar configuración de nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Invalidar cache y copiar archivos del CRM
RUN echo "Build version: ${CACHE_BUST}"
COPY crm.html /usr/share/nginx/html/crm.html
COPY crm.js /usr/share/nginx/html/crm.js
COPY logo.png /usr/share/nginx/html/logo.png

# Exponer puerto 80
EXPOSE 80

# Comando por defecto
CMD ["nginx", "-g", "daemon off;"]

