# 🔒 Solucionar Error de Certificado SSL - Paso a Paso

## ❌ Error Actual

`NET::ERR_CERT_AUTHORITY_INVALID` en `https://api1.checkin24hs.com`

---

## ✅ Solución Completa

### Paso 1: Verificar Configuración en EasyPanel

1. **Ve a EasyPanel** → **Servicios** → **`whatsapp`**
2. **Ve a "Dominios"** o **"Domains"**
3. **Haz clic en `api1.checkin24hs.com`**
4. **Verifica**:
   - ✅ **Pestaña "Detalles"**:
     - HTTPS: **Activado** (toggle en azul)
     - Host: `api1.checkin24hs.com`
     - Puerto Destino: **`3001`** (NO 80)
   - ✅ **Pestaña "SSL"**:
     - Resolutor de certificados: `letsencrypt`
     - Dominio comodín: **Desactivado** (off)
   - ✅ **Guarda** los cambios

### Paso 2: Verificar que el Servicio Esté Corriendo

1. En EasyPanel, verifica que el servicio `whatsapp` esté en **VERDE** (Running)
2. Si no está corriendo, **inícialo**

### Paso 3: Verificar Logs de Traefik

1. En EasyPanel, busca el servicio **"Traefik"** o **"Proxy"**
2. Ve a **"Logs"**
3. Busca mensajes relacionados con:
   - `api1.checkin24hs.com`
   - `certificate`
   - `acme`
   - `Let's Encrypt`
   - `error` o `failed`

**Si ves errores**, compártelos para ayudarte a solucionarlos.

### Paso 4: Esperar Generación del Certificado

Después de guardar la configuración SSL:

1. **Espera 2-5 minutos** (Let's Encrypt necesita tiempo para generar el certificado)
2. **Recarga la página** `https://api1.checkin24hs.com` (Ctrl+F5 o Cmd+Shift+R)
3. **Verifica** que aparezca el candado 🔒

### Paso 5: Verificar DNS

Asegúrate de que el DNS esté correctamente configurado:

```bash
# Desde tu computadora (PowerShell)
nslookup api1.checkin24hs.com
```

Debería mostrar: `72.61.58.240`

---

## 🔍 Verificación Rápida

### Checklist:

- [ ] Dominio `api1.checkin24hs.com` agregado en EasyPanel
- [ ] Puerto destino configurado como **`3001`** (NO 80)
- [ ] SSL/TLS activado en la pestaña "SSL"
- [ ] Resolutor de certificados: `letsencrypt`
- [ ] Servicio `whatsapp` está en VERDE (Running)
- [ ] Esperaste 2-5 minutos después de activar SSL
- [ ] DNS resuelve correctamente a `72.61.58.240`

---

## 🆘 Si Sigue Fallando

### Opción A: Forzar Regeneración

1. **Desactiva SSL** en EasyPanel
2. **Guarda** y espera 30 segundos
3. **Activa SSL** nuevamente
4. **Guarda** y espera 2-5 minutos

### Opción B: Verificar Puertos

Asegúrate de que los puertos 80 y 443 estén abiertos en el servidor:

```bash
# En el servidor (SSH)
sudo ufw status | grep -E "(80|443)"
```

Si no están abiertos:
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Opción C: Verificar Configuración de Traefik

Si Traefik no está generando certificados automáticamente, puede ser que:

1. **Traefik no tenga acceso a Let's Encrypt**
2. **El dominio no resuelva correctamente**
3. **Haya un problema con la configuración de Traefik**

---

## 📋 Información para Diagnosticar

Si el problema persiste, comparte:

1. **Captura de pantalla** de la configuración SSL en EasyPanel
2. **Logs de Traefik** (si puedes acceder)
3. **Resultado de** `nslookup api1.checkin24hs.com`
4. **Estado del servicio** `whatsapp` en EasyPanel

---

## 🎯 Mientras Tanto

Si necesitas que funcione YA, puedes usar HTTP temporalmente:

1. En el dashboard, configura la URL como: `http://72.61.58.240`
2. Esto funcionará, pero mostrará advertencias de Mixed Content
3. Una vez que SSL funcione, cambia a `https://api1.checkin24hs.com`

---

**¿Qué ves en los logs de Traefik? ¿Hay algún error relacionado con el certificado?**









