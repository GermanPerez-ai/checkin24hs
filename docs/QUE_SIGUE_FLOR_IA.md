# Qué sigue ahora (Flor IA)

Después de la implementación de la ficha Flor, alias de búsqueda, varios hoteles y mensaje de bienvenida, estos son los pasos sugeridos.

---

## Inmediato (para que Flor use todo lo nuevo)

1. **Ejecutar la migración en Supabase**  
   En Supabase → SQL Editor, ejecutar el contenido de:
   - `supabase-migrations/008_hotels_flor_info_jsonb.sql`  
   Así la tabla `hotels` tiene la columna `flor_info` (JSONB) si aún no existe.

2. **Sincronizar el saludo oficial en Supabase**  
   Para que el servidor use el mensaje de bienvenida oficial aunque se reinicie:
   - Dashboard → Flor IA → Respuestas predefinidas (o Configuración)  
   - Guardar el **Saludo** con el texto oficial (ya está por defecto en el Dashboard).  
   O en Supabase: tabla `system_config`, clave `flor_responses`, en el JSON asegurar que `saludo` tenga el texto de Patagonia / Puyehue / Huilo Huilo.

3. **Cargar al menos un hotel con la ficha Flor**  
   En Dashboard → Hotels → Editar un hotel:
   - Completar **Alias de búsqueda** (ej. "Puyehue, Guilo, Wilo").
   - Opcional: programas, gastronomía, tips, URLs de imágenes/PDFs.
   - Guardar.  
   Así podés probar búsqueda por alias y que Flor tenga datos ricos.

4. **Probar en WhatsApp**  
   - Mensaje "hola" → debe responder con el saludo oficial.
   - Mensaje con alias (ej. "wilo") → debe encontrar el hotel si está en alias.
   - Si hay dos hoteles que coinciden → Flor debe preguntar "¿Te referís a A o a B?".

---

## Opcional (mejoras siguientes)

| Prioridad | Tarea | Descripción |
|-----------|--------|-------------|
| Alta | **Transcripción de audios** | Usar Gemini (o otro) para convertir audio del cliente en texto y pasar ese texto a la misma lógica de Flor. Hoy se responde "envíame por escrito". |
| Media | **Envío nativo de PDF/imagen** | Cuando el usuario pida "en PDF" o "imagen", descargar la URL desde la ficha y enviar por Baileys como archivo (imagen/documento), no solo el link. |
| Baja | **Subir imágenes/PDFs a Supabase Storage** | En el formulario de Hotels, permitir subir archivos a Storage y guardar la URL en `flor_info` en lugar de pegar URLs externas. |

---

## Resumen de estado

- **Hecho:** Baileys + Gemini, Composing, Alerta humano, Cierre con link cotización, Búsqueda por alias, Varios hoteles ("¿A o B?"), Protocolo PDF/Imagen/Texto (reglas + URLs en tool), Ficha rica en Hotels, Mensaje de bienvenida oficial.
- **Pendiente:** Transcripción de audios, envío nativo de archivos (opcional), subida a Storage (opcional).

Cuando tengas la migración ejecutada y un hotel con alias cargado, Flor ya puede usar todo lo implementado. El siguiente paso más impactante es la **transcripción de audios** para que los clientes puedan hablar y Flor responder igual.
