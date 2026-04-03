# 🔍 Verificar Configuración de Traefik para WhatsApp

## 🎯 Objetivo
Verificar que Traefik esté configurado correctamente para enrutar `https://whatsapp.checkin24hs.com` al servicio WhatsApp.

---

## 📋 Verificación en EasyPanel

### Paso 1: Verificar Dominio Configurado

En EasyPanel → Servicios → `whatsapp` → **Dominios**:

✅ **Debe estar configurado:**
- **Dominio:** `whatsapp.checkin24hs.com`
- **Puerto interno:** `3001`
- **Protocolo:** `https` (con Let's Encrypt)

### Paso 2: Verificar Etiquetas de Traefik

En EasyPanel → Servicios → `whatsapp` → **Entorno** (Environment Variables):

Busca estas variables de entorno o etiquetas:

```
traefik.enable=true
traefik.http.routers.whatsapp.rule=Host(`whatsapp.checkin24hs.com`)
traefik.http.routers.whatsapp.entrypoints=websecure
traefik.http.routers.whatsapp.tls.certresolver=letsencrypt
traefik.http.services.whatsapp.loadbalancer.server.port=3001
```

**O si están como labels en Docker:**

En EasyPanel, busca una sección de **"Labels"** o **"Etiquetas"** y verifica que tengan:

```
traefik.enable=true
traefik.http.routers.whatsapp.rule=Host(`whatsapp.checkin24hs.com`)
traefik.http.routers.whatsapp.entrypoints=websecure
traefik.http.routers.whatsapp.tls=true
traefik.http.routers.whatsapp.tls.certresolver=letsencrypt
traefik.http.services.whatsapp.loadbalancer.server.port=3001
```

---

## 🔧 Configurar Traefik Manualmente (Si no está configurado)

### Opción 1: Desde EasyPanel (Recomendado)

1. Ve a EasyPanel → Servicios → `whatsapp` → **Dominios**
2. Verifica que `whatsapp.checkin24hs.com` esté agregado
3. Si no está, haz clic en **"Agregar dominio"**
4. Ingresa: `whatsapp.checkin24hs.com`
5. Selecciona **HTTPS** y **Let's Encrypt**
6. Guarda y reinicia el servicio

### Opción 2: Desde SSH (Si tienes acceso)

```bash
# Ver servicios Docker
docker service ls | grep whatsapp

# Ver etiquetas del servicio
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.Labels}}' | jq

# Agregar etiquetas de Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  checkin24hs_whatsapp
```

---

## 🧪 Pruebas de Traefik

### Test 1: Verificar que Traefik Vea el Servicio

Si tienes acceso al dashboard de Traefik:

1. Accede a: `http://[tu-servidor]:8080` (puerto del dashboard de Traefik)
2. Ve a **HTTP** → **Routers**
3. Busca `whatsapp` o `whatsapp.checkin24hs.com`
4. Verifica que esté en estado **"UP"**

### Test 2: Verificar Certificado SSL

```bash
# Verificar certificado SSL
openssl s_client -connect whatsapp.checkin24hs.com:443 -servername whatsapp.checkin24hs.com

# O desde navegador:
# Abre https://whatsapp.checkin24hs.com
# Verifica que el certificado sea válido (candado verde)
```

### Test 3: Ver Logs de Traefik

Si tienes acceso SSH:

```bash
# Ver logs de Traefik
docker logs traefik --tail 100 | grep whatsapp

# Buscar errores
docker logs traefik --tail 100 | grep -i error
```

---

## 🔍 Diagnóstico de Problemas Comunes

### Problema 1: Traefik No Encuentra el Servicio

**Síntomas:**
- 404 en todos los endpoints
- El servicio está corriendo pero Traefik no lo ve

**Solución:**
1. Verifica que las etiquetas de Traefik estén configuradas
2. Reinicia el servicio WhatsApp
3. Reinicia Traefik (si es posible)

### Problema 2: Certificado SSL No Se Genera

**Síntomas:**
- HTTP funciona pero HTTPS da error
- Certificado inválido

**Solución:**
1. Verifica que el DNS apunte correctamente a tu servidor
2. Verifica que Let's Encrypt esté configurado
3. Espera unos minutos para que se genere el certificado

### Problema 3: Puerto Incorrecto

**Síntomas:**
- Traefik enruta pero el servicio no responde
- Timeout o conexión rechazada

**Solución:**
1. Verifica que el puerto interno sea `3001`
2. Verifica que el servicio esté escuchando en `0.0.0.0:3001`
3. Verifica que no haya firewall bloqueando

---

## 📊 Verificación Completa

### Checklist Traefik:

- [ ] Dominio `whatsapp.checkin24hs.com` configurado en EasyPanel
- [ ] Etiquetas de Traefik configuradas (`traefik.enable=true`, etc.)
- [ ] Puerto interno correcto (3001)
- [ ] Certificado SSL válido (candado verde en navegador)
- [ ] Servicio visible en dashboard de Traefik (si está disponible)
- [ ] DNS apunta correctamente al servidor

### Checklist Servicio:

- [ ] Servicio en estado "Running" (verde)
- [ ] Logs muestran `✅ Servidor iniciado en puerto 3001`
- [ ] CPU y Memoria tienen valores (no NaN)
- [ ] El servicio responde directamente al puerto (si es posible probar)

---

## 🆘 Si Traefik Está Bien pero Sigue el 404

Si Traefik está configurado correctamente pero sigues viendo 404, el problema es que **el servidor HTTP no está iniciando**.

En ese caso:
1. Revisa los logs completos del servicio
2. Busca errores al iniciar
3. Haz un Rebuild completo
4. Verifica que `link-preview-js` se instaló correctamente

---

## 💡 Próximos Pasos

1. **Verifica la configuración de Traefik** en EasyPanel → Dominios
2. **Revisa las etiquetas/labels** del servicio
3. **Haz un Rebuild** del servicio para asegurar que todo esté actualizado
4. **Revisa los logs completos** desde el inicio

**¿Qué ves en la configuración de Dominios en EasyPanel? ¿Está `whatsapp.checkin24hs.com` configurado correctamente?**
