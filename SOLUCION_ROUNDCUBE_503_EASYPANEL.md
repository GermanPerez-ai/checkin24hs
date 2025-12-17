# 🔧 Solución Error 503 - Roundcube en EasyPanel

## 📸 Basado en tu Pantalla Actual

Veo que roundcube está corriendo pero muestra error 503. Esto significa que **Nginx no puede conectarse a roundcube**.

## 🎯 Solución Paso a Paso

### Paso 1: Verificar el Puerto de Roundcube

1. En la pantalla de roundcube, busca una sección que diga:
   - **"Ports"** o **"Puertos"**
   - **"Network"** o **"Red"**
   - **"Exposed Ports"** o **"Puertos Expuestos"**

2. Anota el puerto interno (ej: `80`, `8080`, `3000`)

### Paso 2: Ver los Logs de Roundcube

1. Haz clic en el icono de **terminal/consola** (`>_`) en la barra de botones
2. O busca la sección **"Logs"** o **"Registros"**
3. Revisa los últimos mensajes buscando errores

### Paso 3: Verificar la Configuración de Nginx (Webmail)

1. **Vuelve a la lista de servicios** (haz clic en "SERVICIOS" o el menú lateral)
2. Haz clic en **"webmail"**
3. Ve a **"Configuration"** o **"Nginx Config"**
4. Verifica que tenga una configuración como:

```nginx
server {
    listen 80;
    server_name webmail.checkin24hs.com;
    
    location / {
        proxy_pass http://localhost:PUERTO_DE_ROUNDCUBE;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**IMPORTANTE**: El `PUERTO_DE_ROUNDCUBE` debe coincidir con el puerto que viste en el Paso 1.

### Paso 4: Si No Encuentras el Puerto

Si roundcube está en Docker (que parece ser el caso), el puerto suele estar en:

1. En la pantalla de roundcube, busca:
   - **"Docker"** o **"Container"**
   - **"Port Mapping"** o **"Mapeo de Puertos"**
   - Algo como `8080:80` significa que el puerto interno es `80` y el externo es `8080`

2. O usa la terminal:
   - Haz clic en el icono de terminal (`>_`)
   - Ejecuta: `docker ps | grep roundcube`
   - Verás algo como `0.0.0.0:8080->80/tcp`

### Paso 5: Reiniciar Roundcube

1. En la pantalla de roundcube
2. Haz clic en el botón de **refresh/restart** (flecha circular)
3. Espera 10-15 segundos
4. Verifica que el estado vuelva a verde

### Paso 6: Verificar que Webmail Apunte Correctamente

1. Ve a **"webmail"** en la lista de servicios
2. Verifica la configuración de Nginx
3. Asegúrate de que `proxy_pass` apunte al puerto correcto

**Ejemplo si roundcube está en puerto 8080:**
```nginx
proxy_pass http://localhost:8080;
```

**Ejemplo si roundcube está en puerto 80 (interno de Docker):**
```nginx
proxy_pass http://roundcube:80;
# O si está en la misma red Docker:
proxy_pass http://checkin24hs-roundcube:80;
```

## 🔍 Diagnóstico con Terminal

1. Haz clic en el icono de **terminal** (`>_`) en roundcube
2. Ejecuta estos comandos:

```bash
# Ver si roundcube está respondiendo
curl http://localhost:PUERTO
# Reemplaza PUERTO con el puerto que encontraste

# Ver logs de roundcube
docker logs roundcube
# O
docker logs checkin24hs-roundcube

# Verificar puertos en uso
netstat -tulpn | grep LISTEN
```

## 🛠️ Soluciones Comunes

### Solución 1: Roundcube no está escuchando en el puerto correcto

1. En roundcube, ve a **"Settings"** o **"Configuración"**
2. Verifica que el puerto esté configurado correctamente
3. Reinicia roundcube

### Solución 2: Nginx no puede conectarse

1. Verifica que **webmail** tenga la configuración correcta
2. Asegúrate de que el `proxy_pass` use el nombre del contenedor o `localhost` según corresponda
3. Recarga Nginx (en webmail, busca "Reload" o "Recargar")

### Solución 3: Variables de Entorno Incorrectas

Veo que tienes estas variables:
- `ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com`
- `ROUNDCUBEMAIL_DEFAULT_PORT=993`

Estas están bien para la configuración de correo, pero no afectan el error 503.

## ✅ Verificación Final

1. **Reinicia roundcube** (botón refresh)
2. **Espera 15 segundos**
3. **Recarga la configuración de webmail** (si hiciste cambios)
4. **Intenta acceder a webmail.checkin24hs.com**

## 🆘 Si Aún No Funciona

1. **Haz clic en el icono de terminal** (`>_`) en roundcube
2. **Ejecuta**: `docker logs roundcube --tail 50`
3. **Copia los últimos logs** y compártelos
4. También verifica los logs de Nginx:
   - Ve a **"webmail"**
   - Ve a **"Logs"**
   - Busca errores recientes

## 📋 Checklist

- [ ] Identifiqué el puerto de roundcube
- [ ] Verifiqué la configuración de Nginx en webmail
- [ ] El `proxy_pass` apunta al puerto correcto
- [ ] Reinicié roundcube
- [ ] Recargué la configuración de webmail/Nginx
- [ ] Revisé los logs de roundcube
- [ ] Revisé los logs de Nginx

