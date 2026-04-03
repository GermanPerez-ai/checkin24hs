# 🔧 Corregir Puerto del Dominio: 3000 → 80

## 🎯 Problema

El dominio `dashboard.checkin24hs.com` está configurado para usar el puerto **3000** (configuración antigua con Node.js), pero ahora nginx escucha en el puerto **80**.

## ✅ Solución: Cambiar Puerto del Dominio

### Paso 1: Editar el Dominio

1. En EasyPanel, ve a la pestaña **"Dominios"**
2. Haz clic en el icono de **lápiz** (editar) del dominio:
   - `https://dashboard.checkin24hs.com...`

### Paso 2: Cambiar el Puerto

1. Busca el campo **"Puerto"** o **"Port"** o **"Puerto interno"** o **"Internal Port"**
2. Actualmente debería decir: `3000` ❌
3. **Cámbialo a**: `80` ✅
4. Si hay un campo **"Destino"** o **"Destination"**, también debe ser `80`

### Paso 3: Guardar

1. Haz clic en **"Guardar"** o **"Save"**
2. Espera 10-20 segundos para que se apliquen los cambios

### Paso 4: Probar

1. Abre: `https://dashboard.checkin24hs.com/`
2. Debería cargar correctamente ahora

---

## 📋 Configuración Correcta

**ANTES (Incorrecto - Node.js):**
- Puerto interno: `3000` ❌
- Comando: `node server.js` ❌

**DESPUÉS (Correcto - Nginx):**
- Puerto interno: `80` ✅
- Comando: **(vacío)** ✅ (el Dockerfile ya lo define)

---

## 🔍 Verificación

Después de cambiar el puerto:

1. El servicio debería seguir en verde
2. El dashboard debería cargar en `https://dashboard.checkin24hs.com/`
3. No debería aparecer el error 404

---

¡Cambia el puerto del dominio de `3000` a `80` y el problema debería resolverse!
