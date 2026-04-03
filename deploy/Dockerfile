FROM nginx:alpine

# Eliminar configuración por defecto
RUN rm -rf /usr/share/nginx/html/*
RUN rm /etc/nginx/conf.d/default.conf

# Copiar archivos del dashboard
COPY . /usr/share/nginx/html/

# Verificar que dashboard.html se copió (para debugging)
RUN ls -la /usr/share/nginx/html/ | head -10 && \
    test -f /usr/share/nginx/html/dashboard.html && echo "✅ dashboard.html encontrado" || echo "❌ dashboard.html NO encontrado"

# Copiar configuración de nginx (más completa)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Verificar configuración de nginx
RUN nginx -t

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
