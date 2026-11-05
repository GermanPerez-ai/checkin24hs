# Instrucciones para Re-notificar Correos Filtrados

## 🧪 Prueba en Dry-Run (Servidor)

Antes de aplicar cualquier cambio permanente, ejecutar el monitor en modo dry-run para ver qué correos serían notificados con la nueva lógica:

```bash
cd /ruta/al/email-monitor
node monitor.js --dry-run
```

Esto mostrará:
- Cuántos correos serían notificados que antes fueron filtrados
- El desglose detallado de razones de filtrado
- Los nuevos emails que ahora pasarían el filtro (con señales fuertes)

**Nota:** El modo dry-run NO envía notificaciones de WhatsApp ni marca correos como procesados.

## 📊 Verificar Correos Filtrados Estos Días

Para ver cuántos correos fueron filtrados en los últimos días (por ejemplo, desde el 2026-11-01):

```sql
-- Consulta de análisis (READ-ONLY)
SELECT 
    status,
    COUNT(*) as cantidad,
    MIN(created_at) as primer_correo,
    MAX(created_at) as ultimo_correo
FROM email_monitor_notifications
WHERE created_at >= '2026-11-01'
GROUP BY status
ORDER BY cantidad DESC;
```

## 🔄 Re-notificar Correos Filtrados (SQL Propuesto - NO EJECUTAR)

⚠️ **IMPORTANTE:** Las siguientes queries SQL están PROPUESTAS para que German las revise y decida si aplicarlas. **NO las ejecutes sin su aprobación explícita.**

### Opción 1: Borrar registros de correos filtrados para que se reprocesen

Esta opción elimina los registros de la tabla `email_monitor_notifications` para correos que fueron marcados como filtrados. La próxima vez que corra el monitor, estos correos serán reprocesados con la nueva lógica.

```sql
-- ⚠️ NO EJECUTAR SIN APROBACIÓN DE GERMAN

-- Paso 1: Ver cuántos correos se borrarían (verificación)
SELECT COUNT(*) as total_a_borrar
FROM email_monitor_notifications
WHERE status = 'filtered'
  AND created_at >= '2026-11-01';  -- Ajustar fecha según necesidad

-- Paso 2: Si el número es razonable, proceder con el borrado
DELETE FROM email_monitor_notifications
WHERE status = 'filtered'
  AND created_at >= '2026-11-01';  -- Ajustar fecha según necesidad
```

**Ventajas:**
- Simple y directo
- El monitor reprocesará automáticamente con la nueva lógica

**Desventajas:**
- Pierdes el historial de que estos correos fueron filtrados antes
- Si hay muchos correos, puede generar muchas notificaciones de WhatsApp de golpe

### Opción 2: Cambiar el status a 'pending' para reprocesar de forma controlada

Esta opción NO borra los registros, sino que cambia su status a 'pending', permitiendo un reprocesamiento más controlado y manteniendo el historial.

```sql
-- ⚠️ NO EJECUTAR SIN APROBACIÓN DE GERMAN

-- Paso 1: Ver cuántos correos se actualizarían (verificación)
SELECT COUNT(*) as total_a_actualizar
FROM email_monitor_notifications
WHERE status = 'filtered'
  AND created_at >= '2026-11-01';  -- Ajustar fecha según necesidad

-- Paso 2: Si el número es razonable, actualizar status
UPDATE email_monitor_notifications
SET 
    status = 'pending',
    error_detail = 'Marcado para re-notificación post-fix filtrado'
WHERE status = 'filtered'
  AND created_at >= '2026-11-01';  -- Ajustar fecha según necesidad
```

**Ventajas:**
- Mantiene el historial
- Permite un control más fino (puedes filtrar por `error_detail`)

**Desventajas:**
- Requiere modificar el monitor para procesar registros con status 'pending'
- Más complejo de implementar

### Opción 3: Reprocesamiento manual selectivo (RECOMENDADA)

La opción más segura es hacer un reprocesamiento manual selectivo:

1. Exportar los `message_id` de correos filtrados que probablemente sean legítimos:

```sql
-- ⚠️ NO EJECUTAR SIN APROBACIÓN DE GERMAN

-- Identificar correos filtrados que probablemente sean movimientos de reserva
SELECT 
    message_id,
    from_addr,
    subject,
    created_at
FROM email_monitor_notifications
WHERE status = 'filtered'
  AND created_at >= '2026-11-01'
  -- Filtrar por patrones que sugieren señales fuertes:
  AND (
    subject ILIKE '%RE:%' OR
    subject ILIKE '%RV:%' OR
    subject ILIKE '%modificación%' OR
    subject ILIKE '%modificacion%' OR
    subject ILIKE '%anulación%' OR
    subject ILIKE '%anulacion%' OR
    subject ILIKE '%confirmamos%' OR
    subject ILIKE '%confirmó%'
  )
ORDER BY created_at DESC;
```

2. Revisar manualmente estos correos en el buzón IMAP
3. Decidir cuáles vale la pena re-notificar
4. Borrar solo esos registros específicos:

```sql
-- ⚠️ NO EJECUTAR SIN APROBACIÓN DE GERMAN

DELETE FROM email_monitor_notifications
WHERE message_id IN (
    '<message-id-1@example.com>',
    '<message-id-2@example.com>',
    -- ... lista de message_ids seleccionados
);
```

## 🎯 Recomendación Final

**Enfoque recomendado:**

1. **Primero:** Ejecutar `node monitor.js --dry-run` en el servidor para ver el impacto
2. **Segundo:** Usar la **Opción 3** (reprocesamiento selectivo) para re-notificar solo los correos más importantes que se perdieron
3. **Tercero:** Dejar que el monitor con la nueva lógica procese correos futuros normalmente
4. **Cuarto (opcional):** Si hay muchos correos filtrados y se quiere limpiar la base, borrarlos después de haber reprocesado los importantes

## 📝 Notas Adicionales

- Los correos duplicados NO se re-notificarán (la tabla tiene constraint único en `message_id`)
- Si un correo ya fue notificado, no se volverá a notificar aunque se borre y reprocese
- El monitor procesa correos de los últimos 7 días por defecto (configurable en `.env` con `IMAP_SINCE_DAYS`)
- Los correos internos (de `@checkin24hs.com`, etc.) siempre se filtrarán, sin importar las señales

## 🔍 Monitoreo Post-Cambios

Después de aplicar los cambios, verificar el log del monitor:

```bash
tail -f /var/log/email-monitor.log
```

El nuevo log mostrará:
- Desglose de razones de filtrado
- Si un correo fue aceptado por "señales fuertes" en lugar de headers de respuesta
- Detalles más precisos de por qué cada correo fue filtrado

Ejemplo de salida esperada:

```
📊 RESUMEN
============================================================
Total procesados: 138
✅ Notificados: 15  (antes: 0)
🔍 Filtrados: 96    (antes: 111)

   Desglose de filtrados:
   • Sin palabras clave de reserva: 80
   • Señales débiles (posible newsletter/spam): 16

🏢 Internos (excluidos): 3
♻️  Duplicados: 24
❌ Errores: 0
============================================================
```
