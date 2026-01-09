FROM nginx:alpine

# Copiar configuración de nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Verificar configuración de nginx
RUN nginx -t

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
