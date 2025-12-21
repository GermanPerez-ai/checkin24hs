# 🔧 Corregir Configuración del Dominio Dashboard

## 🚨 Problema Detectado

En la configuración de EasyPanel, el dominio `dashboard.checkin24hs.com` tiene:
- `"port": 3000` ✅ (correcto)
- `"internalProtocol": "http"` ✅ (correcto)

Pero el servicio está publicado en:
- `"published": 3002` (puerto externo)
- `"target": 3000` (puerto interno)

**El problema puede ser que Traefik está intentando alcanzar el servicio pero hay un desajuste en la configuración.**

---

## ✅ Solución: Corregir la Configuración en EasyPanel

### Paso 1: Verificar la Configuración del Dominio

1. **En EasyPanel, haz clic en el servicio "dashboard"**
2. **Ve a "Domains" o "Dominios"**
3. **Haz clic en `dashboard.checkin24hs.com`**
4. **Verifica:**
   - **Puerto:** Debe ser `3000` (puerto interno del contenedor)
   - **Protocolo interno:** Debe ser `http`
   - **HTTPS:** Debe estar activado

### Paso 2: Si el Puerto Está Incorrecto

1. **Edita el dominio `dashboard.checkin24hs.com`**
2. **Cambia el puerto a `3000`** (si no lo está)
3. **Guarda los cambios**

### Paso 3: Verificar los Puertos del Servicio

1. **Ve a "Settings" o "Configuración" del servicio "dashboard"**
2. **Verifica los puertos:**
   - **Puerto interno:** `3000` (donde el servidor escucha)
   - **Puerto externo:** Puede ser `3002` o cualquier otro (no importa para Traefik)

**Importante:** Para Traefik, solo importa el puerto interno (`3000`), no el puerto externo.

### Paso 4: Reiniciar el Servicio

1. **Después de hacer cambios, reinicia el servicio "dashboard"**
2. **Espera 1-2 minutos**
3. **Prueba el dashboard:** `https://dashboard.checkin24hs.com` (Ctrl+F5)

---

## 🔧 Solución Alternativa: Verificar la Red

El servicio debe estar en la misma red que Traefik:

1. **En EasyPanel, ve a "Settings" del servicio "dashboard"**
2. **Verifica la red:**
   - Debe estar en la red `traefik` o la red por defecto de EasyPanel
   - Si no está, cámbiala y guarda

3. **Reinicia el servicio** después de cambiar la red

---

## 🚀 Solución Rápida (Recomendada)

**Haz esto en orden:**

1. ✅ **En EasyPanel, ve al servicio "dashboard"**
2. ✅ **Ve a "Domains" → Edita `dashboard.checkin24hs.com`**
3. ✅ **Verifica que el puerto sea `3000`**
4. ✅ **Guarda los cambios**
5. ✅ **Reinicia el servicio "dashboard"**
6. ✅ **Espera 1-2 minutos**
7. ✅ **Prueba el dashboard:** `https://dashboard.checkin24hs.com` (Ctrl+F5)

---

## 🔍 Verificación

Después de corregir:

1. **Verifica los logs del servicio:**
   - Debe seguir mostrando: `🚀 Servidor iniciado en http://0.0.0.0:3000`

2. **Prueba el dashboard en el navegador**

3. **Si sigue fallando:**
   - Verifica que Traefik esté corriendo
   - Reinicia Traefik si es necesario

---

## 📋 Configuración Correcta

La configuración del dominio debe ser:

```json
{
  "host": "dashboard.checkin24hs.com",
  "https": true,
  "port": 3000,  // ← Puerto interno del contenedor
  "path": "/",
  "internalProtocol": "http"  // ← Protocolo interno
}
```

**Importante:**
- El `port` debe ser el puerto interno donde el servidor escucha (`3000`)
- El `internalProtocol` debe ser `http` (no `https`)
- `https` debe ser `true` (para que Traefik maneje el HTTPS)

---

## 🆘 Si Sigue Fallando

**Verifica:**

1. **¿El servicio "traefik" está corriendo?**
   - Debe estar en verde 🟢
   - Si no está, inícialo

2. **¿La red del servicio "dashboard" es correcta?**
   - Debe estar en la misma red que Traefik

3. **¿Los logs del servicio siguen mostrando que está funcionando?**
   - Debe mostrar: `🚀 Servidor iniciado en http://0.0.0.0:3000`

---

## 💡 Recomendación

**Empieza por:**
1. Verificar y corregir la configuración del dominio
2. Reiniciar el servicio "dashboard"
3. Probar el dashboard

Si eso no funciona, verifica la red y reinicia Traefik.

---

## 📞 Próximos Pasos

**Por favor:**
1. Ve a EasyPanel → Servicio "dashboard" → "Domains"
2. Verifica que `dashboard.checkin24hs.com` tenga el puerto `3000`
3. Si no lo tiene, cámbialo y guarda
4. Reinicia el servicio "dashboard"
5. Prueba el dashboard y dime qué pasa

