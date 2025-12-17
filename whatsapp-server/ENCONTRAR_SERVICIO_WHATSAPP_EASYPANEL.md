# 🔍 Cómo Encontrar el Servicio de WhatsApp en Easypanel

## Pasos para Encontrar tu Servicio de WhatsApp

### Paso 1: Identificar el Servicio Correcto

En Easypanel, busca servicios con estos nombres comunes:
- `whatsapp`
- `whatsapp-server`
- `whatsapp-flor`
- `whatsapp-bot`
- `flor-whatsapp`
- O cualquier servicio que use el puerto **3001**

### Paso 2: Verificar en el Panel

1. **Ve a tu proyecto/aplicación** en Easypanel
2. **Mira la lista de servicios** (puede estar en "Services", "Apps", o "Containers")
3. **Busca el servicio de WhatsApp** (no Roundcube/webmail)

### Paso 3: Identificar por Puerto o URL

- El servicio de WhatsApp probablemente esté en el puerto **3001**
- O puede tener una URL como `whatsapp.checkin24hs.com`

## Una Vez que Encuentres el Servicio

### Opción A: Si Tiene Terminal/Shell

1. Haz clic en el servicio de WhatsApp
2. Busca la pestaña **"Terminal"**, **"Shell"**, o **"Execute"**
3. Ejecuta:
   ```bash
   rm -rf .wwebjs_auth
   ```
4. Reinicia el servicio

### Opción B: Si Tiene File Manager

1. Haz clic en el servicio de WhatsApp
2. Ve a **"Files"** o **"Storage"**
3. Busca la carpeta `.wwebjs_auth`
4. Elimínala
5. Reinicia el servicio

### Opción C: Reiniciar Directamente

1. Haz clic en el servicio de WhatsApp
2. Busca el botón **"Restart"** o **"Reiniciar"**
3. Haz clic en reiniciar
4. Ve a **"Logs"** para ver si aparece el QR

## Preguntas para Identificar

¿Qué servicios ves en tu proyecto de Easypanel?

- ¿Hay algún servicio con "whatsapp" en el nombre?
- ¿Hay algún servicio en el puerto 3001?
- ¿Hay algún servicio que no sea Roundcube/webmail?

## Si No Encuentras el Servicio

1. **Revisa todos los proyectos** en Easypanel
2. **Busca por dominio**: `whatsapp.checkin24hs.com`
3. **Revisa los logs** de todos los servicios para encontrar el que muestra errores de WhatsApp

