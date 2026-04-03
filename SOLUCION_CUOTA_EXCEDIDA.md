# 🔧 SOLUCIÓN: Mensajes no se guardan por cuota excedida de Supabase

## Problema
- Los mensajes llegan a `whatsapp_chats_no_spam` pero NO a `whatsapp_messages`
- Estás usando el plan FREE de Supabase
- Estás **EXCEEDING USAGE LIMITS** (excediendo límites de uso)

## Causa
Cuando Supabase excede los límites de uso (cuota de egress, requests, o storage), las operaciones de escritura (INSERT) pueden fallar silenciosamente o ser rechazadas, mientras que las lecturas pueden seguir funcionando parcialmente.

## Verificación

Ejecuta en el servidor:

```bash
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)

# Ver errores de cuota
docker logs "$CONTAINER" --tail 500 | grep -i "CUOTA\|quota\|limit\|exceeded\|egress"

# Ver errores al guardar mensajes
docker logs "$CONTAINER" --tail 500 | grep -i "error.*guardando\|error.*mensaje"

# Monitorear en tiempo real
docker logs "$CONTAINER" -f | grep -i "mensaje\|cuota\|error"
```

## Soluciones

### Opción 1: Actualizar plan de Supabase (RECOMENDADO)
1. Ve a Supabase Dashboard → Settings → Billing
2. Actualiza al plan **Pro** ($25/mes)
3. Esto aumentará significativamente los límites

### Opción 2: Optimizar uso de Supabase
- Reducir queries innecesarias
- Usar caché cuando sea posible
- Limpiar datos antiguos

### Opción 3: Esperar al próximo ciclo
- Los límites se resetean cada mes
- Pero esto no es una solución permanente

### Opción 4: Guardar mensajes localmente temporalmente
Si no puedes actualizar el plan inmediatamente, puedes modificar el código para:
1. Guardar mensajes en un archivo local cuando Supabase falle
2. Intentar sincronizar después cuando la cuota se resetee

## Verificar si el código detecta el problema

El código ya tiene detección de cuota excedida. Verifica que esté funcionando:

```bash
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)
docker exec "$CONTAINER" grep -n "CUOTA DE SUPABASE EXCEDIDA" /app/whatsapp-server.js
```

Si no muestra nada, necesitas subir el código corregido al servidor.

## Próximos pasos

1. **Verifica los logs** para confirmar que es un problema de cuota
2. **Actualiza el plan de Supabase** si es posible
3. **Verifica que el código corregido esté en el servidor**
4. **Monitorea los logs** después de actualizar el plan



