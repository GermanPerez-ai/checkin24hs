# 🔍 Verificar Configuración NGINX en el Contenedor

## Contenedor Encontrado

El contenedor es: `checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm`

## Verificaciones Necesarias

### 1. Ver Configuración NGINX Dentro del Contenedor

```bash
# Ver archivos de configuración NGINX
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm ls -la /etc/nginx/conf.d/

# Ver configuración por defecto
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm cat /etc/nginx/conf.d/default.conf

# Ver configuración principal
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm cat /etc/nginx/nginx.conf
```

---

### 2. Verificar si las Rutas Están Configuradas

Si no ves las rutas `/api1/`, `/api2/`, etc. en la configuración, necesitas agregarlas.

---

### 3. Agregar Configuración NGINX Manualmente (Temporal)

Si EasyPanel no tiene opción para editar NGINX, puedes agregar la configuración manualmente:

```bash
# Crear archivo de configuración con las rutas
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm sh -c 'cat > /etc/nginx/conf.d/rutas.conf << EOF
# Ruta 1: WhatsApp Instancia 1
location /api1/ {
    proxy_pass http://host.docker.internal:4001/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \"upgrade\";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_cache_bypass \$http_upgrade;
}

# Ruta 2: WhatsApp Instancia 2
location /api2/ {
    proxy_pass http://host.docker.internal:4002/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \"upgrade\";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_cache_bypass \$http_upgrade;
}

# Ruta 3: WhatsApp Instancia 3
location /api3/ {
    proxy_pass http://host.docker.internal:4003/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \"upgrade\";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_cache_bypass \$http_upgrade;
}

# Ruta 4: WhatsApp Instancia 4
location /api4/ {
    proxy_pass http://host.docker.internal:4004/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \"upgrade\";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_cache_bypass \$http_upgrade;
}
EOF'

# Recargar NGINX
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm nginx -s reload
```

**NOTA:** `host.docker.internal` permite que el contenedor acceda a servicios en el host. Si no funciona, prueba con la IP del host: `172.17.0.1` o la IP de la red Docker.

---

### 4. Verificar Dominio en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Ve a la pestaña **"Dominios"**
3. Verifica que `configwp.checkin24hs.com` esté configurado
4. Si no está, agrégalo

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm cat /etc/nginx/conf.d/default.conf`
2. `docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm ls -la /etc/nginx/conf.d/`
3. Verifica en EasyPanel que el dominio esté configurado

Con esta información podremos identificar exactamente qué está fallando.


