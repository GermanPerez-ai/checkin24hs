# Verificar si el prompt de Flor IA en Supabase es el mismo que el actual

El prompt de Flor se guarda en Supabase así:

- **Tabla:** `system_config`
- **Clave:** `key = 'flor_general_config'`
- **Valor:** columna `value` = JSON. El texto del prompt está en **`promptGeneral`** dentro de ese JSON.

---

## 1. Ver qué hay en Supabase (SQL Editor)

En **Supabase → SQL Editor** ejecutá:

```sql
SELECT key, value
FROM system_config
WHERE key = 'flor_general_config';
```

En `value` vas a ver un JSON. Si querés ver solo el texto del prompt:

```sql
SELECT key,
       value::json->>'promptGeneral' AS prompt_general
FROM system_config
WHERE key = 'flor_general_config';
```

(O en Supabase a veces el tipo es `jsonb`, entonces: `value->>'promptGeneral'`.)

---

## 2. Cómo saber si es el mismo prompt

El **prompt actual/unificado** empieza exactamente así:

```
Eres Flor IA 🌸, asistente virtual de Checkin24hs. Tono de lujo: amable, profesional y fluido.

**Identidad:** Solo actuás como capa de lenguaje. NUNCA inventes hoteles.
```

- Si en Supabase **no hay fila** con `key = 'flor_general_config'` → el servidor WhatsApp usa el prompt por defecto del código (que ya es este mismo texto).
- Si **hay fila** y `promptGeneral` empieza con ese párrafo y habla de **consultarCatalogoHoteles** y **"Por el momento no trabajamos directamente con ese hotel"** → está alineado con el prompt único.
- Si **hay fila** pero el texto es distinto (por ejemplo habla de "base de hoteles proporcionada" o "Propósito: Sos el primer punto de contacto" sin mencionar la función) → es una versión vieja; conviene reemplazarlo por el texto de `docs/FLOR_IA_PROMPT_UNICO_PEGAR.md`.

---

## 3. Verificar desde el Dashboard (consola del navegador)

Con el **Dashboard** abierto (y logueado, con Supabase inicializado):

1. Ir a **Flor IA → Configuración** (donde está el textarea del Prompt General).
2. Abrir la **consola** del navegador (F12 → pestaña Console).
3. Pegar y ejecutar:

```javascript
(async () => {
  const { data, error } = await window.supabaseClient.client
    .from('system_config')
    .select('value')
    .eq('key', 'flor_general_config')
    .single();
  if (error) {
    console.log('Error o sin datos:', error.message);
    return;
  }
  const config = typeof data.value === 'string' ? JSON.parse(data.value) : data.value;
  const prompt = config.promptGeneral || '';
  const esperado = 'Eres Flor IA 🌸, asistente virtual de Checkin24hs. Tono de lujo:';
  const coincide = prompt.trim().startsWith(esperado);
  console.log('Longitud prompt en Supabase:', prompt.length);
  console.log('¿Coincide con prompt unificado?', coincide ? 'Sí' : 'No');
  console.log('Inicio del prompt:', prompt.substring(0, 120) + '...');
})();
```

Si dice **"¿Coincide con prompt unificado? Sí"** y el inicio se ve igual al del doc, entonces en Supabase está lo mismo que el prompt de Flor IA actual.

---

## 4. Dejar Supabase igual al prompt actual

Si verificaste y **no** coincide:

1. Abrí **Dashboard → Flor IA → Configuración**.
2. En **Prompt General** pegá el texto completo de `docs/FLOR_IA_PROMPT_UNICO_PEGAR.md`.
3. Guardá (el dashboard hace upsert en `system_config` con `key = 'flor_general_config'` y `value` = JSON con `promptGeneral`).

Después podés repetir la consulta SQL o el script de la consola para confirmar.
