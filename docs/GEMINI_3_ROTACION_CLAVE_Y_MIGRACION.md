# Migración Gemini 3.1 / apagado 2.0, thought signatures y clave expuesta

## Resumen para stakeholders

Google notificó el **apagado de modelos Gemini 2.0** (referencia interna del proyecto: `gen-lang-client-0800890358`). Plan recomendado:

1. **Modelo:** usar **Gemini 3.1 Flash Lite** (`gemini-3.1-flash-lite-preview` mientras el ID estable no esté documentado; revisar [modelos Gemini](https://ai.google.dev/gemini-api/docs/models) y actualizar cuando haya nombre GA).
2. **Thought signatures:** en **function calling** hay que **reenviar las partes del modelo tal cual** llegan de la API (incl. `thoughtSignature` / `thought_signature` en la primera `functionCall` del paso). Documentación: [Thought signatures](https://ai.google.dev/gemini-api/docs/thought-signatures).
3. **Código Checkin24hs:** el servidor WhatsApp (`whatsapp-server/whatsapp-server-baileys.js`) clona todas las `candidate.content.parts` en cada paso de herramientas antes de agregar `functionResponse`.
4. **Pruebas:** tras deploy, probar una consulta que dispare **consultarCatalogoHoteles** o **buscarHotel** y confirmar que no hay error **400** por firma faltante.

### Texto listo para responder al cliente / equipo

> Hola, ya estamos alineados con el mail de Google: migramos el flujo de Flor a **Gemini 3.1 Flash Lite** y ajustamos el servidor para cumplir **thought signatures** en las rondas con herramientas (requerido en Gemini 3). El proyecto afectado que mencionan (`gen-lang-client-0800890358`) coincide con nuestra cuenta de AI Studio.  
> **Ventana de prueba:** podemos hacer el switch en staging / un número de prueba en **[fecha que definan]** y validar el prompt de 10 puntos; en producción seguimos en cuanto confirmen ustedes.  
> **Seguridad:** la advertencia de **clave expuesta** la resolvemos rotando la API key (ver abajo); la nueva clave solo en variables de entorno del servidor, nunca en el repo.

---

## Clave API expuesta (“Advertencia” en AI Studio)

1. **Asumí que la clave filtrada quedó comprometida** (repo público, captura, log, etc.).
2. En [Google AI Studio → API keys](https://aistudio.google.com/apikey):
   - **Creá una clave nueva** (o usá la que ya tengan como “Gemini API Key” si no estuvo expuesta).
   - **Eliminá o rotá** la clave marcada como “Flor Nueva” / advertencia.
3. En **EasyPanel** (servicio WhatsApp y, si aplica, el que use `GEMINI_API_KEY`): pegá solo la **nueva** clave en `GEMINI_API_KEY` y reiniciá el servicio.
4. **No** subir la clave a Git, `.env` commiteado, ni capturas con el valor completo.
5. Opcional: en Google Cloud, revisar **restricciones de API** y **cuotas** de la clave.

---

## Variables de entorno

| Variable | Uso |
|----------|-----|
| `GEMINI_API_KEY` | Clave tras rotación |
| `GEMINI_MODEL` | Opcional; si no está, el default en código apunta a `gemini-3.1-flash-lite-preview` |

En **Supabase** `flor_ai_config.model` puede seguir definiendo modelo; tiene prioridad según cómo esté armado el servidor (env + Supabase).

---

## Archivos tocados en esta migración (referencia)

- `whatsapp-server/whatsapp-server-baileys.js` — modelo por defecto + `cloneModelPartsForToolFollowup` en el loop de tools.
- `server.js` — default `GEMINI_MODEL`.
- `dashboard.html` / `deploy/dashboard.html` — valores por defecto y textos de ayuda del campo modelo.
- `checkin24hs-web/public/flor-ai-service.js` — lista de modelos de respaldo.

---

## FAQs útiles (Google)

- Si hace falta un **placeholder** de firma en casos excepcionales (no recomendado): la documentación menciona valores dummy solo para escenarios especiales; el flujo normal es **devolver lo que devolvió la API**.
