# Ver y editar el prompt de Flor en Supabase

El prompt de Flor que usa el servidor WhatsApp se lee desde **Supabase**, tabla **`system_config`**, con la clave **`flor_general_config`**.

---

## Dónde verlo en Supabase

1. Entrá a **Supabase** → tu proyecto.
2. Menú izquierdo → **Table Editor**.
3. Abrí la tabla **`system_config`**.
4. Buscá la fila donde la columna **`key`** sea **`flor_general_config`**.
5. En la columna **`value`** vas a ver un JSON. El texto del prompt está en la propiedad **`promptGeneral`**.

Ejemplo de `value`:

```json
{
  "promptGeneral": "Eres Flor IA 🌸, asistente virtual de Checkin24hs. Tono de lujo: amable, profesional..."
}
```

Ese texto es el que usa Flor como instrucción de sistema en Gemini. Si lo cambiaste en el Dashboard, ese cambio se guarda ahí (o debería guardarse ahí, según cómo esté implementado el panel).

---

## Refuerzo del prompt: única fuente de verdad

Para que Flor no intente adivinar si la búsqueda falla, podés agregar al **promptGeneral** en Supabase (al inicio o después del rol) este párrafo:

> La única fuente de verdad para datos de hoteles y destinos es la función consultarCatalogoHoteles. No inventes ni adivines datos. Si la búsqueda falla o devuelve vacío, ofrece alternativas sin nombrar competencia; nunca inventes hoteles ni información.

El servidor ya inyecta reglas similares en código (`FLOR_REGLAS_PRIORIDAD`); sumar esto en el promptGeneral refuerza el comportamiento.

---

## Si no existe la fila `flor_general_config`

Podés crearla desde **SQL Editor** en Supabase. Ejecutá (reemplazá el texto entre comillas por tu prompt):

```sql
INSERT INTO system_config (key, value, description, updated_at)
VALUES (
  'flor_general_config',
  '{"promptGeneral": "Eres Flor IA 🌸, asistente virtual de Checkin24hs. Escribí aquí todo tu prompt..."}',
  'Prompt general de Flor IA para Gemini',
  NOW()
)
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  updated_at = NOW();
```

Para **solo actualizar** el prompt en una fila que ya existe:

```sql
UPDATE system_config
SET value = jsonb_set(
  COALESCE(value::jsonb, '{}'::jsonb),
  '{promptGeneral}',
  '"Tu nuevo texto de prompt aquí (escapá las comillas dobles con \")"'
),
updated_at = NOW()
WHERE key = 'flor_general_config';
```

O, si preferís editar el JSON a mano: en Table Editor, clic en la celda **`value`** de la fila `flor_general_config` y editá el JSON; asegurate de que la clave sea **`promptGeneral`** y el valor sea el texto del prompt (entre comillas).

---

## Otras claves de Flor en `system_config`

| key                 | Uso                                      |
|---------------------|------------------------------------------|
| `flor_general_config` | Prompt general de Flor (Gemini). Campo: `promptGeneral`. |
| `flor_responses`    | Respuestas predefinidas (saludo, noEntendido, etc.). JSON con claves por tipo. |
| `flor_ai_config`    | Config de IA (modelo, temperatura, etc.). |

---

## Después de cambiar el prompt

- El servidor WhatsApp **cachea el prompt** unos 5 minutos. Para ver el cambio enseguida: reiniciá el servicio WhatsApp (o esperá ~5 min).
- Si lo editás desde el **Dashboard** de Checkin24hs, ese dashboard debería estar guardando en `system_config` con clave `flor_general_config` y propiedad `promptGeneral`; si no, hay que revisar que el guardado apunte a esa tabla y clave.
