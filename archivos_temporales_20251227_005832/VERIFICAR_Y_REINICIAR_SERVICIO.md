# ✅ Verificar Archivo y Reiniciar Servicio

## Paso 1: Verificar que el Archivo Esté Completo

Ejecuta este comando para verificar que el archivo `site.conf` esté completo:

```bash
cat /etc/easypanel/projects/checkin24hs/whatsapp-api/generated/site.conf
```

**Deberías ver las 4 rutas completas** (`/api1/`, `/api2/`, `/api3/`, `/api4/`).

Si el archivo está incompleto, ejecuta este comando completo:

```bash
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

chmod 644 /etc/easypanel/projects/checkin24hs/whatsapp-api/generated/site.conf
```

---

## Paso 2: Reiniciar el Servicio en EasyPanel

**IMPORTANTE:** El servicio necesita reiniciarse para que tome la nueva configuración.

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Busca el botón **"Reiniciar"** o **"Restart"** (icono de recarga circular)
3. Haz clic para reiniciar el servicio
4. Espera 30-60 segundos a que termine

**Alternativa:** Si no hay botón de reiniciar, busca **"Reconstruir"** o **"Redeploy"**.

---

## Paso 3: Verificar que el Error Desaparezca

Después de reiniciar, el error rojo debería desaparecer de EasyPanel.

---

## Paso 4: Probar las Rutas

Después de reiniciar, ejecuta estos comandos:

```bash
# Probar con HTTP (debería funcionar ahora)
curl http://configwp.checkin24hs.com/api1/api/qr?card=1
curl http://configwp.checkin24hs.com/api2/api/qr?card=2
curl http://configwp.checkin24hs.com/api3/api/qr?card=3
curl http://configwp.checkin24hs.com/api4/api/qr?card=4

# Si sigue redirigiendo a HTTPS, probar con HTTPS
curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1
```

**Resultado esperado:** Deberías recibir respuestas JSON con QR codes.

---

## Si Sigue "Moved Permanently"

Si sigue redirigiendo a HTTPS, significa que hay otra configuración (probablemente Traefik) que está forzando HTTPS. En ese caso:

1. Prueba con HTTPS directamente:
   ```bash
   curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1
   ```

2. O verifica la configuración SSL en EasyPanel:
   - Ve a **Servicios** → **whatsapp-api** → **SSL**
   - Verifica si está habilitado y si está causando la redirección

---

## Próximos Pasos

1. Verifica que el archivo `site.conf` esté completo
2. Reinicia el servicio en EasyPanel
3. Prueba las rutas con `curl`
4. Comparte los resultados

¡Con esto debería funcionar! 🎉


