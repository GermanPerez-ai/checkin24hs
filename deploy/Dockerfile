FROM nginx:alpine

# Copiar archivos estáticos
COPY . /usr/share/nginx/html/

# Configuración de nginx para SPA
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html dashboard.html; \
    \
    location / { \
        try_files $uri $uri/ /dashboard.html; \
    } \
    \
    # Cache para archivos estáticos \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ { \
        expires 1d; \
        add_header Cache-Control "public, immutable"; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
