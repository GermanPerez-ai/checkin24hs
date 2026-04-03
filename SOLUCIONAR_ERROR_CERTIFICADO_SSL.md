# 🔒 Solucionar Error de Certificado SSL

## ❌ Error Actual

`NET::ERR_CERT_AUTHORITY_INVALID` - El certificado SSL no es válido o no se ha generado.

---

## ✅ Solución Paso a Paso

### Paso 1: Verificar Configuración en EasyPanel

1. **Ve a EasyPanel** → **Servicios**
2. **Haz clic en el servicio `whatsapp`** (o el que corresponda a api1)
3. **Ve a la sección "Dominios"** o **"Domains"**

### Paso 2: Verificar el Dominio

Verifica que tengas configurado:

- ✅ **Dominio**: `api1.checkin24hs.com`
- ✅ **Puerto**: `3001`
- ✅ **SSL/TLS**: ✅ **DEBE estar ACTIVADO** (marcado)

### Paso 3: Si SSL NO está Activado

1. **Haz clic en el dominio** `api1.checkin24hs.com`
2. **Activa SSL/TLS** (marca la casilla)
3. **Guarda** los cambios
4. **Espera 2-3 minutos** para que Traefik genere el certificado

### Paso 4: Si SSL YA está Activado pero Sigue el Error

#### Opción A: Forzar Regeneración del Certificado

1. **Desactiva SSL** temporalmente
2. **Guarda** los cambios
3. **Espera 30 segundos**
4. **Activa SSL** nuevamente
5. **Guarda** y espera 2-3 minutos

#### Opción B: Verificar Logs de Traefik

1. En EasyPanel, busca el servicio **"Traefik"** o **"Proxy"**
2. Ve a **"Logs"**
3. Busca errores relacionados con:
   - `Let's Encrypt`
   - `certificate`
   - `acme`
   - `api1.checkin24hs.com`

#### Opción C: Verificar que el Puerto 80 y 443 Estén Abiertos

El certificado SSL necesita que el puerto 80 esté abierto para la validación de Let's Encrypt.

**En el servidor (SSH):**
```bash
# Verificar que los puertos estén abiertos
sudo ufw status | grep -E "(80|443)"
# O
sudo netstat -tuln | grep -E "(80|443)"
```

Si no están abiertos:
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

---

## 🔍 Verificar DNS

Asegúrate de que el DNS esté correctamente configurado:

```bash
# Verificar desde tu computadora
nslookup api1.checkin24hs.com
```

Debería mostrar: `72.61.58.240`

---

## ⏱️ Tiempo de Espera

Después de activar SSL:
- ⏰ **Espera 2-5 minutos** para que Let's Encrypt genere el certificado
- 🔄 **Recarga la página** después de esperar
- 🔒 El certificado debería aparecer automáticamente

---

## 🆘 Si Nada Funciona

### Verificar Configuración Manual

1. **Verifica que el dominio esté correctamente escrito**: `api1.checkin24hs.com` (sin espacios, sin errores)
2. **Verifica que el puerto sea correcto**: `3001` para api1
3. **Verifica que el servicio esté corriendo**: Debe estar en VERDE (Running)

### Alternativa: Usar HTTP Temporalmente

Si necesitas que funcione YA mientras solucionas SSL:

1. En el dashboard, configura la URL como: `http://72.61.58.240` (sin HTTPS)
2. Esto funcionará, pero mostrará advertencias de Mixed Content
3. Una vez que SSL funcione, cambia a HTTPS

---

## 📋 Checklist de Verificación

Antes de probar nuevamente:

- [ ] DNS configurado correctamente (`api1.checkin24hs.com` → `72.61.58.240`)
- [ ] Dominio agregado en EasyPanel para el servicio `whatsapp`
- [ ] Puerto configurado: `3001`
- [ ] SSL/TLS **ACTIVADO** en EasyPanel
- [ ] Servicio `whatsapp` está en VERDE (Running)
- [ ] Esperaste 2-5 minutos después de activar SSL
- [ ] Puertos 80 y 443 están abiertos en el servidor

---

## 🎯 Próximos Pasos

1. **Verifica la configuración en EasyPanel** (Paso 1-3)
2. **Espera 2-5 minutos** después de activar SSL
3. **Prueba nuevamente** en el navegador
4. **Si sigue fallando**, revisa los logs de Traefik

---

**¿Qué ves en la configuración de dominios en EasyPanel para el servicio `whatsapp`?**









