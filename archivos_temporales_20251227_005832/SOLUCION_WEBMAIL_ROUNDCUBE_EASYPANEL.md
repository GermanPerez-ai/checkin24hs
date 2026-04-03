# 🔧 Solución Error 503 - Webmail Roundcube en EasyPanel

## 📸 Basado en tu Configuración Actual

Veo que **webmail** está configurado con la imagen Docker `roundcube/roundcubemail:1.6.11-apache`.

## 🎯 Solución Inmediata

### Paso 1: Desplegar/Reiniciar el Servicio

1. **Haz clic en el botón verde "Implementar" (Deploy)**
   - Esto desplegará o actualizará el servicio
   - Espera a que termine el proceso (puede tardar 1-2 minutos)

2. **O si el servicio ya está corriendo:**
   - Haz clic en el botón de **refresh/restart** (flecha circular)
   - Espera 10-15 segundos

### Paso 2: Verificar Variables de Entorno

1. En la configuración de webmail, busca la pestaña **"Variables de entorno"** o **"Environment Variables"**
2. Verifica que tengas estas variables configuradas (como en roundcube):

```
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
```

### Paso 3: Verificar la Configuración de Puertos

1. En la configuración de webmail, busca la sección **"Ports"** o **"Puertos"**
2. O busca una pestaña que diga **"Network"** o **"Red"**
3. Verifica que haya un puerto configurado (ej: `80`, `8080`)

### Paso 4: Verificar la Configuración de Nginx

1. En webmail, busca una pestaña o sección que diga:
   - **"Nginx"** o **"Configuration"**
   - **"Domain"** o **"Dominio"**
   - **"Settings"** o **"Configuración"**

2. Verifica que el dominio esté configurado:
   - `webmail.checkin24hs.com`
   - O `mail.checkin24hs.com`

## 🔍 Diagnóstico Detallado

### Si el Botón "Implementar" Está Visible

Esto puede significar:
- El servicio no está desplegado
- Hay cambios pendientes que no se han aplicado
- El servicio se detuvo

**Solución:**
1. Haz clic en **"Implementar"**
2. Espera a que termine (verás un indicador de progreso)
3. Verifica que el estado cambie a "Running" o "Activo"

### Verificar el Estado del Servicio

1. Después de hacer clic en "Implementar", espera 1-2 minutos
2. Verifica que:
   - El CPU y Memoria muestren valores (no 0.0%)
   - El estado sea verde
   - No haya errores en los logs

### Ver los Logs

1. Haz clic en el icono de **terminal** (`>_`) o busca **"Logs"**
2. Revisa los últimos mensajes
3. Busca errores como:
   - `Connection refused`
   - `Port already in use`
   - `Cannot start container`

## 🛠️ Configuración Recomendada

### Variables de Entorno Necesarias

En la pestaña **"Variables de entorno"**, asegúrate de tener:

```env
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
ROUNDCUBEMAIL_PLUGINS=archive,zipdownload
ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE=5M
```

### Configuración de Dominio

1. Busca la sección **"Domain"** o **"Dominio"** en webmail
2. Verifica que esté configurado:
   - `webmail.checkin24hs.com`
   - O el dominio que uses para el webmail

## ✅ Pasos de Verificación

1. ✅ **Haz clic en "Implementar"** y espera
2. ✅ **Verifica que el servicio esté en verde** (Running)
3. ✅ **Revisa los logs** para ver si hay errores
4. ✅ **Intenta acceder a webmail.checkin24hs.com**

## 🆘 Si "Implementar" No Funciona

1. **Haz clic en el botón de stop** (cuadrado) para detener el servicio
2. **Espera 5 segundos**
3. **Haz clic en el botón de play** (▶️) para iniciarlo
4. **O haz clic en "Implementar"** de nuevo

## 📋 Checklist Completo

- [ ] Hice clic en "Implementar" y esperé a que termine
- [ ] El servicio muestra estado "Running" o verde
- [ ] CPU y Memoria muestran valores (no 0.0%)
- [ ] Verifiqué las variables de entorno
- [ ] Verifiqué la configuración del dominio
- [ ] Revisé los logs y no hay errores críticos
- [ ] Intenté acceder a webmail.checkin24hs.com

## 💡 Nota Importante

Si tienes **DOS servicios** (roundcube y webmail) ambos usando Roundcube:
- Puede haber un conflicto de puertos
- Considera usar solo uno de ellos
- O configura puertos diferentes para cada uno

