# Ajustes de calidad – Flor IA

Cambios aplicados en el servidor (whatsapp-server-baileys.js) para pulir la experiencia de usuario.

## 1. Menos spam del link de cotización

- **Antes:** Flor podía incluir el link de cotización en muchos mensajes.
- **Ahora:** El prompt indica que el link https://cotizar.checkin24hs.com/ solo se debe enviar cuando:
  - Pregunten explícitamente por **precios**, **cotización** o **reserva**, o
  - Al **cerrar un tema de venta** (oferta de cierre).
- No se incluye en saludos ni en respuestas informativas (ej. info de un hotel).

**Si usás prompt desde Supabase (flor_general_config):** Revisá que el texto no diga “enviá SIEMPRE el link”. Reemplazalo por una instrucción del tipo: “Solo enviá el link de cotización cuando pregunten por precios, cotización o reserva, o al ofrecer cierre de venta.”

---

## 2. Lógica de catálogo (“qué hoteles tienen”)

- **Antes:** Si el usuario preguntaba “qué hoteles tienen” sin dar ubicación, la función podía devolver “necesito ubicación”.
- **Ahora:**
  - Si se llama `consultarCatalogoHoteles` **sin** ubicación ni hotel_especifico, se devuelve el **listado completo** de hoteles activos de la tabla `hotels`.
  - Las reglas y la descripción de la herramienta indican a Gemini que, ante “qué hoteles tienen” o “qué opciones hay”, llame la función sin parámetros para listar todos.
  - No se responde “necesito ubicación” en ese caso.

---

## 3. Fluidez (saludos y transiciones)

- **Antes:** Los saludos (hola, buen día, etc.) se respondían con una plantilla fija de `flor_responses.saludo`, que sonaba robótica.
- **Ahora:** Esos mensajes **no** se interceptan: llegan a Gemini y Flor responde con saludos y transiciones generadas por la IA, más naturales.

---

## 4. Búsqueda por ubicación (ej. Patagonia)

- **Antes:** La búsqueda por ubicación solo miraba la columna `location` (y podía ser estricta).
- **Ahora:** `buscarHotelesPorUbicacion` busca el término también en:
  - `location`
  - `name`
  - `flor_info.description`
  - `flor_info.narrativa_poetica`
  - `flor_info.region` (si existe)

Así, si “Patagonia” está en la descripción o en la ubicación, el hotel aparece. Si en la tabla `hotels` la ubicación no tiene “Patagonia”, conviene:
- Agregar “Patagonia” (o la región que corresponda) en `location` o en `flor_info.description` / `flor_info.region` para cada hotel de esa zona.

---

## Despliegue

- Subir los cambios del servidor (whatsapp-server-baileys.js) y hacer **redeploy** del servicio WhatsApp en EasyPanel.
- Si el prompt de Flor se edita en Supabase (`flor_general_config`), actualizarlo allí también según el punto 1.
