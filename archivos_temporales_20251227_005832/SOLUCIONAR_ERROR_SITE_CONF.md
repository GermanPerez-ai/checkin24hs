# 🔧 Solucionar Error: site.conf No Existe

## Error Detectado

```
invalid mount config for type "bind": bind source path does not exist: 
/etc/easypanel/projects/checkin24hs/whatsapp-api/generated/site.conf
```

Este archivo es necesario para que NGINX funcione correctamente.

## Solución

### Opción 1: Crear el Directorio y Archivo Manualmente

Ejecuta estos comandos en el servidor:

```bash
# Crear el directorio si no existe
mkdir -p /etc/easypanel/projects/checkin24hs/whatsapp-api/generated

# Crear el archivo site.conf con la configuración básica
cat > /etc/easypanel/projects/checkin24hs/whatsapp-api/generated/site.conf << 'EOF'
server {
    listen 80;
    server_name configwp.checkin24hs.com;

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
}
EOF

# Dar permisos correctos
chmod 644 /etc/easypanel/projects/checkin24hs/whatsapp-api/generated/site.conf
chown root:root /etc/easypanel/projects/checkin24hs/whatsapp-api/generated/site.conf
```

### Opción 2: Reconstruir el Servicio en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Haz clic en el botón **"Reconstruir"** o **"Redeploy"**
3. Espera a que termine el proceso
4. EasyPanel debería generar el archivo automáticamente

---

## Después de Crear el Archivo

### 1. Reiniciar el Servicio en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Haz clic en el botón **"Reiniciar"** o **"Restart"**
3. Espera 30 segundos

### 2. Verificar que el Error Desaparezca

El error rojo debería desaparecer de la interfaz de EasyPanel.

### 3. Probar las Rutas

```bash
# Probar desde el servidor
curl http://configwp.checkin24hs.com/api1/api/qr?card=1
curl http://configwp.checkin24hs.com/api2/api/qr?card=2
curl http://configwp.checkin24hs.com/api3/api/qr?card=3
curl http://configwp.checkin24hs.com/api4/api/qr?card=4
```

Deberías recibir respuestas JSON con QR codes.

---

## Si el Archivo se Elimina Automáticamente

Si EasyPanel elimina el archivo automáticamente, significa que EasyPanel debería generarlo. En ese caso:

1. **Verifica las rutas en EasyPanel:**
   - Ve a **Servicios** → **whatsapp-api** → **Rutas**
   - Asegúrate de que las 4 rutas estén configuradas correctamente

2. **Reconstruye el servicio:**
   - Haz clic en **"Reconstruir"** o **"Redeploy"**
   - Esto debería generar el archivo automáticamente

---

## Próximos Pasos

1. Ejecuta los comandos para crear el archivo `site.conf`
2. Reinicia el servicio en EasyPanel
3. Prueba las rutas con `curl`
4. Comparte los resultados

¡Con esto debería funcionar! 🎉


