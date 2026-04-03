# 🔧 Agregar Rutas NGINX al Nuevo Contenedor

## Problema

La configuración NGINX se perdió cuando se recreó el contenedor. Solo tiene la configuración por defecto.

## Solución: Agregar Rutas de Nuevo

### Paso 1: Obtener IP del Gateway

```bash
# Ver IP del gateway desde el contenedor
docker exec checkin24hs_whatsapp-api.1.yuh9y9noygad9t40zt6is6rp1 ip route | grep default
```

---

### Paso 2: Agregar Configuración NGINX

Una vez que tengas la IP del gateway, ejecuta este comando (reemplaza `[GATEWAY_IP]` con la IP que obtengas):

```bash
# Modificar default.conf para agregar las rutas dentro del bloque server
docker exec checkin24hs_whatsapp-api.1.yuh9y9noygad9t40zt6is6rp1 sh -c 'cat > /etc/nginx/conf.d/default.conf << "EOF"
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    # Ruta 1: WhatsApp Instancia 1
    location /api1/ {
        proxy_pass http://[GATEWAY_IP]:4001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Ruta 2: WhatsApp Instancia 2
    location /api2/ {
        proxy_pass http://[GATEWAY_IP]:4002/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Ruta 3: WhatsApp Instancia 3
    location /api3/ {
        proxy_pass http://[GATEWAY_IP]:4003/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Ruta 4: WhatsApp Instancia 4
    location /api4/ {
        proxy_pass http://[GATEWAY_IP]:4004/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Ruta por defecto
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF'
```

---

### Paso 3: Recargar NGINX

```bash
# Verificar configuración
docker exec checkin24hs_whatsapp-api.1.yuh9y9noygad9t40zt6is6rp1 nginx -t

# Recargar NGINX
docker exec checkin24hs_whatsapp-api.1.yuh9y9noygad9t40zt6is6rp1 nginx -s reload
```

---

## Próximos Pasos

1. Ejecuta: `docker exec checkin24hs_whatsapp-api.1.yuh9y9noygad9t40zt6is6rp1 ip route | grep default`
2. Usa la IP del gateway en el comando de configuración
3. Ejecuta el comando completo para agregar las rutas
4. Recarga NGINX
5. Prueba: `curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1`

¡Con esto debería funcionar! 🎉


