# 🔧 Corregir Rutas NGINX - Puertos Correctos

## Problema Identificado

Los servicios WhatsApp están escuchando en:
- **Puerto 4001** → WhatsApp Instancia 1
- **Puerto 4002** → WhatsApp Instancia 2  
- **Puerto 4003** → WhatsApp Instancia 3
- **Puerto 4004** → WhatsApp Instancia 4

Pero las rutas NGINX están configuradas para:
- **Puerto 3001** → WhatsApp Instancia 1
- **Puerto 3002** → WhatsApp Instancia 2
- **Puerto 3003** → WhatsApp Instancia 3
- **Puerto 3004** → WhatsApp Instancia 4

## Solución: Actualizar Rutas NGINX en EasyPanel

### Paso 1: Ir a EasyPanel

1. Abre **EasyPanel** en tu navegador
2. Ve a **Servicios** → **whatsapp-api**
3. Busca la sección **"Rutas"** o **"Proxy Routes"** o **"NGINX Routes"**

### Paso 2: Actualizar las Rutas

Actualiza las rutas para que apunten a los puertos correctos:

**Ruta 1:**
- **Ruta:** `/api1/`
- **Target:** `127.0.0.1:4001` (cambiar de 3001 a 4001)

**Ruta 2:**
- **Ruta:** `/api2/`
- **Target:** `127.0.0.1:4002` (cambiar de 3002 a 4002)

**Ruta 3:**
- **Ruta:** `/api3/`
- **Target:** `127.0.0.1:4003` (cambiar de 3003 a 4003)

**Ruta 4:**
- **Ruta:** `/api4/`
- **Target:** `127.0.0.1:4004` (cambiar de 3004 a 4004)

### Paso 3: Guardar y Aplicar

1. Haz clic en **"Guardar"** o **"Aplicar"**
2. Espera a que se apliquen los cambios (puede tardar unos segundos)
3. El servicio debería recargar la configuración automáticamente

### Paso 4: Verificar

Prueba estas URLs en el navegador:

```
http://configwp.checkin24hs.com/api1/api/qr?card=1
http://configwp.checkin24hs.com/api2/api/qr?card=2
http://configwp.checkin24hs.com/api3/api/qr?card=3
http://configwp.checkin24hs.com/api4/api/qr?card=4
```

Deberías recibir respuestas JSON con los QR codes.

---

## Configuración NGINX Correcta (Referencia)

Si necesitas ver la configuración completa, debería verse así:

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

---

## Después de Actualizar

1. Prueba las URLs en el navegador
2. Prueba conectar WhatsApp desde el dashboard
3. Verifica que todas las 4 instancias funcionen correctamente

¡Con esto debería funcionar! 🎉


