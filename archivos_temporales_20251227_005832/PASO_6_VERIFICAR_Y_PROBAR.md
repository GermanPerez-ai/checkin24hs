# 📋 Paso 6: Verificar DNS y Probar Configuración

## 🎯 Objetivo
Verificar que el DNS esté configurado y probar que las rutas funcionen correctamente.

---

## 📝 Paso 6.1: Verificar Configuración DNS

### ¿Ya tienes el DNS configurado?

Si **NO** tienes el DNS configurado aún, necesitas crear un registro DNS:

**Tipo de registro:** `A` o `CNAME`
**Nombre/Host:** `configwp`
**Valor/Destino:** IP de tu servidor (ej: `72.61.58.240`)
**TTL:** `3600` (o el valor por defecto)

### Verificar DNS desde tu computadora

Abre PowerShell o CMD y ejecuta:

```powershell
nslookup configwp.checkin24hs.com
```

**Resultado esperado:**
- Debería mostrar la IP de tu servidor
- Si muestra "No se puede resolver", el DNS aún no está propagado

**⏱️ Nota:** La propagación DNS puede tardar de 5 minutos a 24 horas, pero generalmente es rápido (5-30 minutos).

---

## 📝 Paso 6.2: Probar SSL y Rutas

### Probar SSL del Dominio

1. Abre tu navegador
2. Visita: `https://configwp.checkin24hs.com`
3. Deberías ver:
   - ✅ Candado verde 🔒 (SSL válido)
   - ✅ Sin errores de certificado
   - ⚠️ Posiblemente una página de error o "502 Bad Gateway" (eso está bien por ahora)

### Probar Rutas Individuales

Prueba cada ruta en el navegador:

**Ruta 1:**
```
https://configwp.checkin24hs.com/api1/api/qr?card=1
```

**Ruta 2:**
```
https://configwp.checkin24hs.com/api2/api/qr?card=2
```

**Ruta 3:**
```
https://configwp.checkin24hs.com/api3/api/qr?card=3
```

**Ruta 4:**
```
https://configwp.checkin24hs.com/api4/api/qr?card=4
```

**Resultado esperado:**
- ✅ Sin errores SSL
- ✅ Respuesta JSON o imagen QR (dependiendo del estado de WhatsApp)
- ✅ O un error 502/503 si WhatsApp no está corriendo (eso está bien, significa que la ruta funciona)

---

## 🆘 Solución de Problemas

### Problema: DNS no resuelve
**Solución:**
1. Verifica que el registro DNS esté creado correctamente
2. Espera 5-30 minutos para propagación
3. Prueba desde otro dispositivo o red

### Problema: Error SSL "NET::ERR_CERT_AUTHORITY_INVALID"
**Solución:**
1. Espera 2-5 minutos más para que se genere el certificado
2. Verifica en EasyPanel que SSL esté activo
3. Intenta en modo incógnito

### Problema: Error 502 Bad Gateway en las rutas
**Solución:**
- Esto puede ser normal si WhatsApp no está corriendo
- Verifica que los puertos 3001-3004 estén activos en el servidor
- Revisa los logs de NGINX en EasyPanel

### Problema: Error 404 Not Found en las rutas
**Solución:**
1. Verifica que la configuración NGINX se haya guardado correctamente
2. Asegúrate de que NGINX esté habilitado
3. Revisa que las rutas terminen con `/` (ej: `/api1/`)

---

## ✅ Checklist de Verificación

- [ ] DNS configurado y propagado
- [ ] SSL funciona (candado verde)
- [ ] Ruta `/api1/` responde (aunque sea con error 502)
- [ ] Ruta `/api2/` responde
- [ ] Ruta `/api3/` responde
- [ ] Ruta `/api4/` responde

---

## ➡️ Siguiente Paso

Una vez que hayas verificado que las rutas funcionan, avísame y pasamos al **Paso 7: Actualizar el Dashboard**.

---

## 📸 Comandos Útiles

### Desde PowerShell (Windows)

```powershell
# Verificar DNS
nslookup configwp.checkin24hs.com

# Probar SSL (requiere curl)
curl -I https://configwp.checkin24hs.com

# Probar rutas
curl https://configwp.checkin24hs.com/api1/api/qr?card=1
```

### Desde el Navegador

Abre la consola del navegador (F12) y ejecuta:

```javascript
// Probar ruta 1
fetch('https://configwp.checkin24hs.com/api1/api/qr?card=1')
  .then(r => r.json())
  .then(console.log)
  .catch(console.error)
```


