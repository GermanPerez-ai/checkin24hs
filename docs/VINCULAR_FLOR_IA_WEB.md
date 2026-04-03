# Vincular el chat de Flor (web) con la IA (Gemini)

El chat que se abre en la web (burbuja Flor) usa la misma configuración de IA que el Dashboard: se guarda en Supabase en la tabla **system_config**, clave **flor_ai_config**. Si esa configuración tiene la API key de Gemini y está habilitada, el chat de la web usará la IA.

---

## 1. Tabla `system_config` en Supabase

Si el Dashboard ya guarda configuración de Flor (General, Respuestas, IA), la tabla **system_config** ya existe. Si no:

- Ejecutá en Supabase → SQL Editor el script que crea las tablas (por ejemplo **VERIFICAR_Y_ACTUALIZAR_TABLAS_SUPABASE.sql**), o creá la tabla a mano:

```sql
CREATE TABLE IF NOT EXISTS public.system_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 2. Configurar la IA en el Dashboard

1. Entrá al **Dashboard**: https://dashboard.checkin24hs.com
2. En el menú, abrí **Flor IA**
3. Andá a la pestaña **🤖 IA** (Configuración de Inteligencia Artificial)
4. Configurá:
   - **Habilitar respuestas con IA**: activado
   - **Proveedor**: **Google Gemini**
   - **API Key**: tu clave de [Google AI Studio](https://aistudio.google.com/apikey)
   - **Modelo**: por ejemplo `gemini-2.5-flash` o `gemini-2.0-flash`
5. Clic en **Guardar** (o en **Guardar toda la configuración de Flor**).

Eso hace un **upsert** en `system_config` con `key = 'flor_ai_config'` y el JSON con `enabled`, `provider`, `apiKey`, `model`, etc.

---

## 3. Cómo lo usa el chat de la web

Cuando el usuario abre el chat en la web (burbuja Flor):

1. La web le pasa a la página del chat (iframe) la conexión a Supabase.
2. El chat pide a Supabase la fila `system_config.key = 'flor_ai_config'`.
3. Si existe y tiene `enabled: true` y `apiKey`, el chat habilita la IA y usa ese `apiKey` y `model` para llamar a Gemini desde el navegador.

Por tanto, **no hace falta configurar nada más en EasyPanel** para la web: la IA se “vincula” solo leyendo **flor_ai_config** desde Supabase después de que la guardás en el Dashboard.

---

## 4. Si el chat no usa la IA

- Revisá en el Dashboard que en **Flor IA → IA** esté **Habilitar respuestas con IA** y que la **API Key** esté guardada.
- Abrí la consola del navegador (F12) en la página del chat y buscá mensajes como `[Flor AI] ☁️ Configuración sincronizada desde Supabase` o `[Chatbot] ☁️ IA habilitada desde configuración de Supabase`. Si no aparecen, puede que no exista `flor_ai_config` en Supabase o que la clave anon no tenga permiso de lectura sobre `system_config`.
- Si la tabla `system_config` es nueva, asegurate de tener una política RLS que permita **SELECT** al rol **anon** (y si el Dashboard guarda con anon, también **INSERT/UPDATE** para ese registro).

Cuando **flor_ai_config** esté guardado en Supabase con Gemini habilitado y API key, el chat de la web quedará vinculado a la IA.
