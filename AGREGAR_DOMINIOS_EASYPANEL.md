# Agregar Dominios en EasyPanel

## 📍 Ubicación en la Imagen

En la imagen que compartiste, estás en la sección **"Dominios"** del servicio `whatsapp1`. 

En la parte inferior de la tarjeta blanca que muestra el dominio existente, hay un campo o botón que dice **"Agregar dominio"** (Add domain). Ahí es donde debes agregar los dominios personalizados.

---

## 🔧 Pasos para Agregar Dominios en EasyPanel

### Para WhatsApp 1:

1. **Estás en:** `checkin24hs / whatsapp1` → Sección **"Dominios"**
2. **Busca:** El campo/botón **"Agregar dominio"** (debajo del dominio existente)
3. **Agrega:** `whatsapp1.checkin24hs.com`
4. **Guarda**

### Para WhatsApp 2:

1. **Ve a:** Servicio `whatsapp2` (en el menú izquierdo)
2. **Clic en:** "Dominios" (en el menú lateral)
3. **Busca:** El campo/botón **"Agregar dominio"**
4. **Agrega:** `whatsapp2.checkin24hs.com`
5. **Guarda**

### Para WhatsApp 3:

1. **Ve a:** Servicio `whatsapp3` (en el menú izquierdo)
2. **Clic en:** "Dominios" (en el menú lateral)
3. **Busca:** El campo/botón **"Agregar dominio"**
4. **Agrega:** `whatsapp3.checkin24hs.com`
5. **Guarda**

### Para WhatsApp 4:

1. **Ve a:** Servicio `whatsapp4` (en el menú izquierdo)
2. **Clic en:** "Dominios" (en el menú lateral)
3. **Busca:** El campo/botón **"Agregar dominio"**
4. **Agrega:** `whatsapp4.checkin24hs.com`
5. **Guarda**

---

## 📋 Resumen de Dominios a Agregar

| Servicio | Dominio a Agregar |
|----------|-------------------|
| whatsapp1 | `whatsapp1.checkin24hs.com` |
| whatsapp2 | `whatsapp2.checkin24hs.com` |
| whatsapp3 | `whatsapp3.checkin24hs.com` |
| whatsapp4 | `whatsapp4.checkin24hs.com` |

---

## ⚠️ Importante

**Dos lugares donde configurar:**

1. **DNS Externo** (ya lo hiciste ✅):
   - Registros A en tu proveedor de dominio
   - `whatsapp1.checkin24hs.com` → `72.61.58.240`
   - `whatsapp2.checkin24hs.com` → `72.61.58.240`
   - etc.

2. **EasyPanel - Dominios** (lo que debes hacer ahora):
   - En cada servicio, sección "Dominios"
   - Agregar el dominio personalizado
   - Esto le dice a Traefik que debe enrutar ese dominio a ese servicio

**Ambos son necesarios:**
- DNS externo → Resuelve el nombre a la IP
- EasyPanel Dominios → Le dice a Traefik qué servicio usar

---

## 🎯 Ubicación Exacta en la Interfaz

En la imagen que compartiste:

1. **Menú izquierdo:** Selecciona el servicio (whatsapp1, whatsapp2, etc.)
2. **Menú lateral:** Clic en **"Dominios"** (ya estás ahí)
3. **Área principal:** Busca el campo/botón **"Agregar dominio"** debajo del dominio existente
4. **Escribe:** El dominio completo (ej: `whatsapp1.checkin24hs.com`)
5. **Guarda**

---

## ✅ Después de Agregar

Una vez que agregues los 4 dominios en EasyPanel:

1. EasyPanel configurará automáticamente Traefik
2. Traefik generará certificados SSL automáticamente
3. Los servicios estarán accesibles vía HTTPS

**Nota:** Puede tardar unos minutos en que Traefik detecte los cambios y genere los certificados SSL.


















