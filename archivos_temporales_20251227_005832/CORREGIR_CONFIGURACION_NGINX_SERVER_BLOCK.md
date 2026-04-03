# 🔧 Corregir Configuración NGINX - Bloque Server

## Problema

Las directivas `location` deben estar dentro de un bloque `server`, no directamente en el archivo.

## Solución: Modificar default.conf

Necesitamos agregar las rutas dentro del bloque `server` existente en `default.conf`.

## Comandos para Corregir

```bash
# Primero, eliminar el archivo incorrecto
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm rm /etc/nginx/conf.d/rutas.conf

# Modificar default.conf para agregar las rutas dentro del bloque server
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm sh -c 'cat > /etc/nginx/conf.d/default.conf << "EOF"
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    # Ruta 1: WhatsApp Instancia 1
    location /api1/ {
        proxy_pass http://172.18.0.1:4001/;
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
        proxy_pass http://172.18.0.1:4002/;
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
        proxy_pass http://172.18.0.1:4003/;
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
        proxy_pass http://172.18.0.1:4004/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Ruta por defecto (opcional, para otras peticiones)
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

# Verificar la configuración
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm nginx -t

# Si la configuración es correcta, recargar NGINX
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm nginx -s reload
```

---

## Después de Ejecutar

Prueba las rutas:

```bash
curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1
curl -k https://configwp.checkin24hs.com/api2/api/qr?card=2
curl -k https://configwp.checkin24hs.com/api3/api/qr?card=3
curl -k https://configwp.checkin24hs.com/api4/api/qr?card=4
```

---

## Nota

Usé la IP `172.18.0.1` (gateway del contenedor) que obtuviste del comando `ip route`. Esto debería permitir que el contenedor acceda a los servicios en el host.


