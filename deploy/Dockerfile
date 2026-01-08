FROM nginx:alpine

# Eliminar configuración por defecto
RUN rm -rf /usr/share/nginx/html/*
RUN rm /etc/nginx/conf.d/default.conf

# Copiar archivos del dashboard
COPY . /usr/share/nginx/html/

# Verificar que dashboard.html se copió (para debugging)
RUN ls -la /usr/share/nginx/html/ | head -10

# Copiar configuración de nginx (más completa)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
