# 🔧 Recrear Servicio WhatsApp API

## Pasos para Recrear el Servicio

### Paso 1: Crear Nuevo Servicio en EasyPanel

1. Ve a **EasyPanel** → **Proyecto "checkin24hs"**
2. Haz clic en **"+ Servicio"** (botón en la parte superior)
3. Selecciona el tipo de servicio: **"Proxy"** o **"NGINX"** o **"Aplicación"**
   - Si hay opción "Proxy", úsala
   - Si no, usa "Aplicación" y luego configura NGINX

---

### Paso 2: Configurar el Servicio

**Nombre del servicio:** `whatsapp-api`

**Configuración básica:**
- Tipo: Proxy/NGINX (o Aplicación si no hay Proxy)
- Imagen: Puedes usar una imagen base como `nginx:alpine` o dejar que EasyPanel la genere

---

### Paso 3: Configurar Dominio

1. Ve a la pestaña **"Dominios"**
2. Agrega el dominio: `configwp.checkin24hs.com`
3. Configura:
   - **HTTPS:** Habilitado
   - **Host:** `configwp.checkin24hs.com`
   - **Ruta:** `/`
   - **Destino:**
     - Protocolo: HTTP
     - Puerto: 80
     - Ruta: `/`

---

### Paso 4: Configurar Rutas NGINX

1. Ve a la pestaña **"NGINX"**
2. Habilita NGINX (toggle azul)
3. Documento raíz: `/code` (o deja el predeterminado)
4. Haz clic en **"Editar"** en **"Config"**
5. Pega esta configuración:

```nginx
# Ruta 1: WhatsApp Instancia 1
location /api1/ {
    proxy_pass http://127.0.0.1:4001/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}

# Ruta 2: WhatsApp Instancia 2
location /api2/ {
    proxy_pass http://127.0.0.1:4002/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}

# Ruta 3: WhatsApp Instancia 3
location /api3/ {
    proxy_pass http://127.0.0.1:4003/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}

# Ruta 4: WhatsApp Instancia 4
location /api4/ {
    proxy_pass http://127.0.0.1:4004/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}
```

6. Haz clic en **"Guardar"** o **"Listo"**

---

### Paso 5: Habilitar SSL

1. Ve a la pestaña **"Dominios"**
2. Haz clic en el dominio `configwp.checkin24hs.com`
3. Ve a la pestaña **"SSL"**
4. Habilita SSL (debería estar automáticamente si usas Let's Encrypt)
5. Resolver: `letsencrypt`
6. Guarda

---

### Paso 6: Guardar y Desplegar

1. Haz clic en **"Guardar"** o **"Desplegar"**
2. Espera a que el servicio se cree y despliegue
3. Verifica que el estado sea **"Running"** (verde)

---

### Paso 7: Verificar

```bash
# Ver el nuevo contenedor
docker ps | grep whatsapp-api

# Probar las rutas
curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1
curl -k https://configwp.checkin24hs.com/api2/api/qr?card=2
```

---

## Si Hay Problemas

### Problema: No hay opción "Proxy"

**Solución:** Usa "Aplicación" y luego configura NGINX manualmente en la pestaña NGINX.

### Problema: El servicio no inicia

**Solución:** 
- Verifica los logs del servicio en EasyPanel
- Verifica que el dominio esté configurado correctamente
- Verifica que las rutas NGINX estén guardadas

### Problema: Bad Gateway después de crear

**Solución:**
- Verifica que los servicios WhatsApp estén corriendo en los puertos 4001-4004
- Verifica que las rutas NGINX apunten a los puertos correctos
- Reinicia el servicio

---

## Resumen

1. Crear nuevo servicio `whatsapp-api`
2. Configurar dominio `configwp.checkin24hs.com`
3. Configurar rutas NGINX (4 rutas: /api1/, /api2/, /api3/, /api4/)
4. Habilitar SSL
5. Desplegar y verificar

¡Sigue estos pasos y el servicio debería funcionar! 🎉


