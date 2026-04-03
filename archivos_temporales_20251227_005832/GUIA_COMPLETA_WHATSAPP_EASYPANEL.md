# 📱 Guía Completa: Configurar 4 Servicios de WhatsApp en EasyPanel

## 🎯 Objetivo

Configurar 4 servicios de WhatsApp independientes en EasyPanel, cada uno con su propio dominio y puerto, para poder conectar hasta 4 números de WhatsApp diferentes.

---

## 📋 Resumen de Configuración

| Servicio | Puerto | Dominio | INSTANCE_NUMBER |
|----------|--------|---------|-----------------|
| whatsapp1 | 3001 | whatsapp1.checkin24hs.com | 1 |
| whatsapp2 | 3002 | whatsapp2.checkin24hs.com | 2 |
| whatsapp3 | 3003 | whatsapp3.checkin24hs.com | 3 |
| whatsapp4 | 3004 | whatsapp4.checkin24hs.com | 4 |

---

## 🔧 PARTE 1: Crear Servicios en EasyPanel

### Paso 1.1: Crear Servicio WhatsApp 1

1. **Abre EasyPanel** y ve a tu proyecto
2. **Haz clic en "New Service"** o **"Crear Servicio"**
3. **Selecciona tipo**: `Node.js` o `Docker`
4. **Configuración básica**:
   - **Nombre del servicio**: `whatsapp1`
   - **Puerto interno**: `3001`
   - **Comando de inicio**: `node whatsapp-server.js`
   - **Directorio de trabajo**: `/app` o donde esté tu código

5. **Variables de Entorno** (Environment Variables):
   ```
   INSTANCE_NUMBER=1
   PORT=3001
   SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
   GEMINI_API_KEY=tu_api_key_aqui  # Opcional
   ```

6. **Dominio**:
   - **Agregar dominio**: `whatsapp1.checkin24hs.com`
   - **Habilitar SSL**: ✅ Sí (Let's Encrypt)

7. **Guardar y esperar** a que el servicio inicie (estado verde)

---

### Paso 1.2: Crear Servicio WhatsApp 2

Repite el Paso 1.1 pero con estos valores:

- **Nombre del servicio**: `whatsapp2`
- **Puerto interno**: `3002`
- **INSTANCE_NUMBER**: `2`
- **PORT**: `3002`
- **Dominio**: `whatsapp2.checkin24hs.com`

---

### Paso 1.3: Crear Servicio WhatsApp 3

Repite el Paso 1.1 pero con estos valores:

- **Nombre del servicio**: `whatsapp3`
- **Puerto interno**: `3003`
- **INSTANCE_NUMBER**: `3`
- **PORT**: `3003`
- **Dominio**: `whatsapp3.checkin24hs.com`

---

### Paso 1.4: Crear Servicio WhatsApp 4

Repite el Paso 1.1 pero con estos valores:

- **Nombre del servicio**: `whatsapp4`
- **Puerto interno**: `3004`
- **INSTANCE_NUMBER**: `4`
- **PORT**: `3004`
- **Dominio**: `whatsapp4.checkin24hs.com`

---

## 🌐 PARTE 2: Configurar DNS

Necesitas crear 4 registros DNS tipo **A** en tu panel de DNS:

### Paso 2.1: Acceder a Panel DNS

1. Ve a tu proveedor de dominio (donde compraste `checkin24hs.com`)
2. Accede a la sección de **DNS** o **Zona DNS**
3. Busca la opción **"Agregar Registro"** o **"Add Record"**

### Paso 2.2: Crear Registros A

Crea estos 4 registros uno por uno:

**Registro 1:**
- **Tipo**: `A`
- **Nombre**: `whatsapp1`
- **Valor/IP**: `72.61.58.240`
- **TTL**: `3600` (o el que prefieras)

**Registro 2:**
- **Tipo**: `A`
- **Nombre**: `whatsapp2`
- **Valor/IP**: `72.61.58.240`
- **TTL**: `3600`

**Registro 3:**
- **Tipo**: `A`
- **Nombre**: `whatsapp3`
- **Valor/IP**: `72.61.58.240`
- **TTL**: `3600`

**Registro 4:**
- **Tipo**: `A`
- **Nombre**: `whatsapp4`
- **Valor/IP**: `72.61.58.240`
- **TTL**: `3600`

### Paso 2.3: Verificar DNS

Espera 5-10 minutos y verifica que los DNS estén propagados:

```bash
# Desde tu terminal local
nslookup whatsapp1.checkin24hs.com
nslookup whatsapp2.checkin24hs.com
nslookup whatsapp3.checkin24hs.com
nslookup whatsapp4.checkin24hs.com
```

Todos deben apuntar a `72.61.58.240`.

---

## 🔒 PARTE 3: Configurar Traefik (Si EasyPanel no lo hace automáticamente)

Si EasyPanel no configura Traefik automáticamente, ejecuta estos comandos en el servidor:

### Paso 3.1: Conectarse al Servidor

```bash
ssh root@72.61.58.240
```

### Paso 3.2: Ejecutar Script de Configuración

```bash
cd /root/checkin24hs
bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
```

O configura manualmente cada servicio:

```bash
# WhatsApp 1
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp1.rule=Host(\`whatsapp1.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp1.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp1.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp1.loadbalancer.server.port=3001" \
  whatsapp1

# WhatsApp 2
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp2.rule=Host(\`whatsapp2.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp2.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp2.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp2.loadbalancer.server.port=3002" \
  whatsapp2

# WhatsApp 3
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp3.rule=Host(\`whatsapp3.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp3.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp3.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp3.loadbalancer.server.port=3003" \
  whatsapp3

# WhatsApp 4
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp4.rule=Host(\`whatsapp4.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp4.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp4.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp4.loadbalancer.server.port=3004" \
  whatsapp4
```

---

## ✅ PARTE 4: Verificar que Todo Funciona

### Paso 4.1: Verificar Servicios en EasyPanel

1. En EasyPanel, verifica que los 4 servicios estén en estado **verde** (Running)
2. Revisa los logs de cada servicio para asegurarte de que no hay errores

### Paso 4.2: Verificar Acceso Web

Abre en tu navegador (deberían mostrar el QR de WhatsApp):

- ✅ https://whatsapp1.checkin24hs.com/
- ✅ https://whatsapp2.checkin24hs.com/
- ✅ https://whatsapp3.checkin24hs.com/
- ✅ https://whatsapp4.checkin24hs.com/

### Paso 4.3: Verificar desde el Dashboard

1. Ve a tu Dashboard: https://dashboard.checkin24hs.com/
2. Ve a **Flor IA** → **WhatsApp**
3. Deberías ver 4 iframes con los QR de cada WhatsApp
4. Escanea cada QR con un número de WhatsApp diferente

### Paso 4.4: Ejecutar Script de Verificación

En el servidor:

```bash
cd /root/checkin24hs
chmod +x VERIFICAR_WHATSAPP_COMPLETO.sh
bash VERIFICAR_WHATSAPP_COMPLETO.sh
```

---

## 🐛 Solución de Problemas

### Problema: "Servicio no inicia"

**Solución:**
1. Verifica que el archivo `whatsapp-server.js` esté en el directorio correcto
2. Verifica las variables de entorno
3. Revisa los logs del servicio en EasyPanel

### Problema: "404 Not Found" al acceder al dominio

**Solución:**
1. Verifica que los DNS estén propagados (espera 10-15 minutos)
2. Verifica que Traefik tenga las etiquetas correctas
3. Reinicia Traefik: `docker service update --force traefik`

### Problema: "SSL no funciona"

**Solución:**
1. Espera 2-5 minutos para que Let's Encrypt genere el certificado
2. Verifica que el dominio apunte correctamente a `72.61.58.240`
3. Verifica que Traefik tenga `traefik.http.routers.whatsappX.tls.certresolver=letsencrypt`

### Problema: "QR no aparece"

**Solución:**
1. Revisa los logs del servicio para ver errores
2. Verifica que `SUPABASE_URL` y `SUPABASE_ANON_KEY` sean correctos
3. Verifica que el puerto esté correcto en las variables de entorno

---

## 📝 Checklist Final

- [ ] Servicio `whatsapp1` creado y corriendo
- [ ] Servicio `whatsapp2` creado y corriendo
- [ ] Servicio `whatsapp3` creado y corriendo
- [ ] Servicio `whatsapp4` creado y corriendo
- [ ] Variables de entorno configuradas en los 4 servicios
- [ ] DNS configurado para los 4 dominios
- [ ] Traefik configurado para los 4 servicios
- [ ] SSL funcionando en los 4 dominios
- [ ] QR visible en los 4 dominios
- [ ] Dashboard muestra los 4 iframes correctamente

---

## 🎉 ¡Listo!

Una vez completados todos los pasos, tendrás 4 servicios de WhatsApp funcionando independientemente, cada uno con su propio dominio y QR. Puedes conectar hasta 4 números de WhatsApp diferentes, cada uno usando Flor IA para responder automáticamente.

---

## 📚 Archivos Relacionados

- `CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh` - Script para configurar Traefik
- `VERIFICAR_WHATSAPP_COMPLETO.sh` - Script de verificación
- `CREAR_SERVICIOS_WHATSAPP_COMPLETO.sh` - Script de diagnóstico
- `whatsapp-server/whatsapp-server.js` - Código del servidor WhatsApp

---

¿Necesitas ayuda con algún paso específico? ¡Pregunta!

