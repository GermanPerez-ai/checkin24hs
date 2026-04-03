# 🌐 Configurar Dominio para WhatsApp en EasyPanel

## 📋 Pasos para Agregar el Dominio

### Paso 1: Ir a la Sección de Dominios

1. **Ve a EasyPanel** → Servicio `whatsapp`
2. **Haz clic en "Dominios"** o **"Domains"** (en el menú lateral)

---

### Paso 2: Agregar el Dominio

1. **Haz clic en "Agregar Dominio"** o **"Add Domain"**

2. **Ingresa el dominio**:
   ```
   whatsapp.checkin24hs.com
   ```

3. **Configuración**:
   - **Dominio**: `whatsapp.checkin24hs.com`
   - **HTTPS**: ✅ Habilitado (automático con Let's Encrypt)
   - **Redirección HTTP a HTTPS**: ✅ Habilitado (recomendado)

4. **Guarda** el dominio

---

### Paso 3: Verificar Labels de Traefik

Los labels de Traefik deben estar configurados para que el dominio funcione. Ve a la sección **"Labels"** o **"Etiquetas"** y verifica que tengas:

```yaml
traefik.enable: "true"
traefik.http.routers.whatsapp.rule: "Host(`whatsapp.checkin24hs.com`)"
traefik.http.routers.whatsapp.entrypoints: "websecure"
traefik.http.routers.whatsapp.tls.certresolver: "letsencrypt"
traefik.http.services.whatsapp.loadbalancer.server.port: "3001"
```

**Si no están**, agrégalos:

1. **Ve a "Labels"** o **"Etiquetas"**
2. **Agrega cada label** (uno por línea o usando el formato de EasyPanel)
3. **Guarda** los cambios

---

### Paso 4: Verificar DNS

Antes de que el dominio funcione, asegúrate de que el DNS esté configurado:

1. **Ve a tu proveedor de DNS** (donde gestionas los DNS de `checkin24hs.com`)

2. **Verifica que exista este registro**:
   ```
   Tipo: A
   Nombre: whatsapp
   Apunta a: 72.61.58.240
   TTL: 14400 (o el que prefieras)
   ```

3. **Espera a que el DNS se propague** (puede tardar unos minutos)

---

### Paso 5: Verificar que Funciona

1. **Espera 2-5 minutos** después de agregar el dominio (para que se genere el certificado SSL)

2. **Prueba el dominio**:
   ```
   https://whatsapp.checkin24hs.com/api/health
   ```

3. **Deberías ver**:
   ```json
   {
     "status": "ok",
     "instance": 1
   }
   ```

4. **Si ves un error de certificado SSL**, espera unos minutos más (Let's Encrypt puede tardar en generar el certificado)

---

## 🔍 Verificación del Certificado SSL

### Método 1: Desde el Navegador

1. **Abre**: `https://whatsapp.checkin24hs.com/api/health`
2. **Haz clic en el candado** (🔒) en la barra de direcciones
3. **Verifica** que el certificado sea válido y emitido por Let's Encrypt

### Método 2: Desde la Terminal

```bash
curl -I https://whatsapp.checkin24hs.com/api/health
```

**Deberías ver**:
```
HTTP/2 200
```

---

## ⚠️ Problemas Comunes

### El dominio no carga (ERR_NAME_NOT_RESOLVED)

**Causa**: El DNS no está configurado o no se ha propagado

**Solución**:
1. Verifica que el registro A existe en tu DNS
2. Espera 5-10 minutos para que se propague
3. Verifica con: `nslookup whatsapp.checkin24hs.com`

### Error de certificado SSL

**Causa**: El certificado aún no se ha generado

**Solución**:
1. Espera 5-10 minutos
2. Reinicia el servicio en EasyPanel
3. Verifica los logs de Traefik (si tienes acceso)

### Error 502 Bad Gateway

**Causa**: El servicio no está corriendo o el puerto está mal configurado

**Solución**:
1. Verifica que el servicio esté en estado "Running" (verde)
2. Verifica que el puerto en los labels sea `3001`
3. Verifica los logs del servicio

---

## 📝 Resumen de Configuración

### En EasyPanel:

1. **Dominio**: `whatsapp.checkin24hs.com`
2. **HTTPS**: ✅ Habilitado
3. **Labels Traefik**: Configurados
4. **Puerto**: `3001`

### En DNS:

1. **Tipo**: A
2. **Nombre**: `whatsapp`
3. **IP**: `72.61.58.240`

---

## ✅ Checklist Final

- [ ] Dominio agregado en EasyPanel
- [ ] Labels de Traefik configurados
- [ ] DNS configurado (registro A)
- [ ] Servicio en estado "Running"
- [ ] Certificado SSL generado (esperar 5-10 min)
- [ ] Dominio accesible por HTTPS

---

## 🎯 Próximo Paso

Una vez que el dominio esté funcionando, puedes:
1. Probar el endpoint: `https://whatsapp.checkin24hs.com/api/health`
2. Ver el QR: `https://whatsapp.checkin24hs.com/api/qr`
3. Crear la interfaz simple en el dashboard para conectar el teléfono
