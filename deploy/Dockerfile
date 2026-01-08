FROM nginx:alpine

# Eliminar configuración por defecto
RUN rm -rf /usr/share/nginx/html/*
RUN rm /etc/nginx/conf.d/default.conf

# Copiar archivos del dashboard desde deploy/
# Build Path es / (raíz), entonces copiar desde deploy/ relativo a la raíz
COPY deploy/ /usr/share/nginx/html/

# Crear configuración de nginx
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index dashboard.html index.html;\n\
    \n\
    location / {\n\
        try_files $uri $uri/ /dashboard.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
