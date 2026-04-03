# Guía: Configurar SSL en EasyPanel para WhatsApp

## Paso 1: Configurar Let's Encrypt en Traefik

1. **Accede al panel de EasyPanel**
   - Abre tu navegador y ve a la URL de EasyPanel
   - Inicia sesión con tus credenciales

2. **Ve a la configuración de Traefik**
   - Busca la sección "Traefik" o "Reverse Proxy" en el menú
   - O busca "SSL" o "Certificates" en la configuración

3. **Habilita Let's Encrypt**
   - Busca la opción "Let's Encrypt" o "ACME"
   - Actívala
   - Ingresa tu email (ejemplo: admin@checkin24hs.com)
   - Guarda los cambios

4. **Verifica que está activo**
   - Deberías ver un indicador de que Let's Encrypt está habilitado
   - Los certificados se generarán automáticamente cuando se configuren los servicios

## Paso 2: Configurar SSL para cada servicio de WhatsApp

Para cada servicio (WhatsApp 1, 2, 3, 4):

1. **Accede al servicio**
   - Ve a la lista de servicios en EasyPanel
   - Encuentra el servicio de WhatsApp (checkin24hs_whatsapp, checkin24hs_whatsapp2, etc.)

2. **Configura el dominio**
   - Busca la sección "Domains" o "Domain Configuration"
   - Agrega el dominio correspondiente:
     - WhatsApp 1: `api1.checkin24hs.com`
     - WhatsApp 2: `api2.checkin24hs.com`
     - WhatsApp 3: `api3.checkin24hs.com`
     - WhatsApp 4: `api4.checkin24hs.com`

3. **Habilita SSL/HTTPS**
   - Activa la opción "SSL" o "HTTPS"
   - Selecciona "Let's Encrypt" como proveedor de certificado
   - Guarda los cambios

4. **Repite para los otros servicios**
   - Haz lo mismo para WhatsApp 2, 3 y 4 con sus respectivos dominios

## Paso 3: Verificar la configuración

Después de configurar todos los servicios:

1. **Espera 2-5 minutos** para que Let's Encrypt genere los certificados

2. **Verifica desde el servidor SSH:**
   ```bash
   curl -I https://api1.checkin24hs.com
   curl -I https://api2.checkin24hs.com
   curl -I https://api3.checkin24hs.com
   curl -I https://api4.checkin24hs.com
   ```

3. **Deberías ver:**
   - `HTTP/2 200` o similar (no errores de certificado)
   - Sin mensajes de `ERR_CERT_AUTHORITY_INVALID`

## Paso 4: Actualizar configuración en el Dashboard

Una vez que los certificados SSL estén funcionando:

1. **Recarga el dashboard** con `Ctrl + Shift + R`
2. **Intenta conectar WhatsApp** nuevamente
3. **Deberías ver** que la conexión funciona sin errores de certificado SSL

## Notas importantes

- Los DNS ya están configurados correctamente (todos apuntan a 72.61.58.240)
- Los servicios de WhatsApp están corriendo correctamente
- Solo falta configurar SSL en EasyPanel

## Si tienes problemas

1. **Verifica los logs de Traefik:**
   ```bash
   docker service logs traefik --tail 50
   ```

2. **Verifica que los servicios tienen los labels correctos:**
   ```bash
   docker service inspect checkin24hs_whatsapp --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
   ```

3. **Si EasyPanel no tiene opción de SSL:**
   - Puedes usar el script manual: `bash CONFIGURAR_LETSENCRYPT_TRAEFIK.sh`
   - Luego aplicar labels: `bash APLICAR_LABELS_SSL_WHATSAPP.sh`






