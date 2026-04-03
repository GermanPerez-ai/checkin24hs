# 🔒 Configurar HTTPS - Opción Más Fácil

## 🎯 Opción Recomendada: Usar EasyPanel/Traefik (5 minutos)

Si tienes EasyPanel, esta es la opción **más fácil** porque Traefik ya maneja HTTPS automáticamente.

### Paso 1: Agregar Registros DNS

En tu panel de DNS de Hostinger, agrega estos 4 registros:

```
Tipo: A | Nombre: api1 | Apunta a: 72.61.58.240 | TTL: 14400
Tipo: A | Nombre: api2 | Apunta a: 72.61.58.240 | TTL: 14400
Tipo: A | Nombre: api3 | Apunta a: 72.61.58.240 | TTL: 14400
Tipo: A | Nombre: api4 | Apunta a: 72.61.58.240 | TTL: 14400
```

Espera 5-10 minutos para que se propaguen.

---

### Paso 2: Configurar en EasyPanel

Para cada servicio de WhatsApp (`whatsapp`, `whatsapp2`, `whatsapp3`, `whatsapp4`):

1. **Ve a EasyPanel** → **Servicios** → Selecciona el servicio (ej: `whatsapp`)
2. **Haz clic en "Dominios"** o **"Domains"** en el menú lateral
3. **Haz clic en "Agregar Dominio"** o **"Add Domain"**
4. **Configura**:
   - **Dominio**: 
     - Para `whatsapp`: `api1.checkin24hs.com`
     - Para `whatsapp2`: `api2.checkin24hs.com`
     - Para `whatsapp3`: `api3.checkin24hs.com`
     - Para `whatsapp4`: `api4.checkin24hs.com`
   - **Puerto**: `3001` (o 3002, 3003, 3004 según el servicio)
   - **SSL/TLS**: ✅ **Activar** (marca la casilla)
5. **Guarda** los cambios
6. **Espera 1-2 minutos** para que Traefik obtenga el certificado SSL automáticamente

---

### Paso 3: Verificar

Después de configurar, verifica que HTTPS funcione:

```bash
curl -I https://api1.checkin24hs.com
curl -I https://api2.checkin24hs.com
curl -I https://api3.checkin24hs.com
curl -I https://api4.checkin24hs.com
```

Deberías ver `HTTP/2 200` o similar.

---

### Paso 4: Actualizar Dashboard

1. Ve a **Flor IA** → **WhatsApp**
2. Haz clic en **"⚙️ Configurar Servidor"**
3. Cambia la URL base de `http://72.61.58.240` a `https://api1.checkin24hs.com`
4. **Nota**: El código del dashboard necesitará una pequeña modificación para usar los diferentes subdominios según la tarjeta (api1, api2, api3, api4)

---

## 🔧 Alternativa: Si NO tienes EasyPanel o prefieres Nginx

Si prefieres usar Nginx directamente, ejecuta este script en el servidor:

```bash
# Subir script al servidor
scp CONFIGURAR_HTTPS_SIMPLE.sh root@72.61.58.240:/root/

# Ejecutar en el servidor
ssh root@72.61.58.240
cd /root
chmod +x CONFIGURAR_HTTPS_SIMPLE.sh
bash CONFIGURAR_HTTPS_SIMPLE.sh
```

---

## ✅ Ventajas de Usar EasyPanel

- ✅ **Automático**: Traefik obtiene y renueva certificados SSL automáticamente
- ✅ **Sin comandos**: Todo se hace desde la interfaz web
- ✅ **Sin conflictos**: No interfiere con otros servicios
- ✅ **Fácil**: Solo agregar dominios y activar SSL

---

## 📝 Nota Importante

Después de configurar HTTPS, necesitarás actualizar el código del dashboard para que use las URLs HTTPS correctas según la tarjeta (1, 2, 3, 4).

¿Quieres que te ayude a modificar el código del dashboard para usar estas URLs HTTPS?









