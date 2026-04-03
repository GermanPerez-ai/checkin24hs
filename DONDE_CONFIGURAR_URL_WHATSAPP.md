# 📍 ¿Dónde Configuro la URL del Servidor WhatsApp?

## 🎯 Ubicación Exacta

### Paso 1: Abrir el Modal de Configuración

**Opción A: Desde la sección de Cotizaciones**
1. Abre el Dashboard
2. Ve a la sección **"Cotizaciones"** (menú lateral)
3. Busca el botón **"Configurar WhatsApp"** (botón gris)
4. Haz clic en ese botón

**Opción B: Buscar el botón directamente**
- Busca un botón que dice **"⚙️ Configurar WhatsApp"** o **"Configurar WhatsApp"**
- Está en la sección de Cotizaciones

### Paso 2: Configurar la URL

Una vez que se abre el modal, verás varios campos:

1. **Access Token** (puedes dejarlo vacío si no lo usas)
2. **Phone Number ID** (puedes dejarlo vacío si no lo usas)
3. **API Version** (puedes dejarlo como está)
4. **URL del Servidor (Opcional)** ← **ESTE ES EL CAMPO IMPORTANTE**

### Paso 3: Ingresar la URL

En el campo **"URL del Servidor (Opcional)"**:

1. Ingresa la URL base de tu servidor, **SIN puerto**
   - ✅ Correcto: `http://72.61.58.240`
   - ✅ Correcto: `https://whatsapp.checkin24hs.com`
   - ❌ Incorrecto: `http://72.61.58.240:3001` (no incluyas el puerto)

2. Haz clic en **"Guardar Configuración"**

3. Verás un mensaje: "✅ Configuración de WhatsApp guardada correctamente"

---

## 📸 Ubicación Visual

```
Dashboard
  └── Menú Lateral
      └── Cotizaciones
          └── [Botón: "Configurar WhatsApp"] ← Haz clic aquí
              └── Modal se abre
                  └── Campo: "URL del Servidor (Opcional)" ← Ingresa aquí
                      └── Ejemplo: http://72.61.58.240
```

---

## 🔍 Código del Campo

El campo está en la línea **4991-4997** del archivo `dashboard.html`:

```html
<div class="form-group">
    <label class="form-label">URL del Servidor (Opcional)</label>
    <input type="text" id="whatsappServerURL" class="form-input" 
           placeholder="https://api.checkin24hs.com">
    <small style="color: #666; margin-top: 5px; display: block;">
        Si tienes un servidor con endpoint de WhatsApp, ingresa su URL aquí
    </small>
</div>
```

---

## ✅ Después de Configurar

Una vez que guardes la configuración:

1. ✅ Se guarda en **Supabase (servidor)** → Todos los usuarios la ven
2. ✅ Se guarda en **localStorage** → Caché local rápido
3. ✅ Ya puedes usar las tarjetas de WhatsApp en **Flor IA → WhatsApp**

---

## 🎯 Ejemplo Completo

1. Abres el Dashboard
2. Vas a **Cotizaciones**
3. Haces clic en **"Configurar WhatsApp"**
4. En el campo **"URL del Servidor"** ingresas: `http://72.61.58.240`
5. Haces clic en **"Guardar Configuración"**
6. Listo ✅

Ahora cuando vayas a **Flor IA → WhatsApp** y hagas clic en "Conectar":
- WhatsApp 1 se conectará a `http://72.61.58.240:3001`
- WhatsApp 2 se conectará a `http://72.61.58.240:3002`
- WhatsApp 3 se conectará a `http://72.61.58.240:3003`
- WhatsApp 4 se conectará a `http://72.61.58.240:3004`

El puerto se agrega automáticamente según la tarjeta.

---

## ⚠️ Nota Importante

El campo dice **"(Opcional)"** pero **ES NECESARIO** si quieres usar las conexiones de WhatsApp con el servidor. Sin esta URL, las funciones intentarán conectarse a `localhost:3001` que no funcionará.










