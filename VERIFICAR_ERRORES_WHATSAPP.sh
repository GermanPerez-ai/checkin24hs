#!/bin/bash
set -e

echo "=========================================="
echo "🔍 VERIFICANDO ERRORES EN SERVIDOR DE WHATSAPP"
echo "=========================================="

# Buscar contenedores de WhatsApp
WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))

if [ ${#WHATSAPP_CONTAINERS[@]} -eq 0 ]; then
    echo "❌ No se encontraron contenedores de WhatsApp corriendo"
    exit 1
fi

echo "✅ Se encontraron ${#WHATSAPP_CONTAINERS[@]} contenedores de WhatsApp"
echo ""

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "=== Contenedor: $CONTAINER ==="
    echo ""
    
    # Buscar errores relacionados con Supabase y mensajes
    echo "📋 Últimos errores relacionados con Supabase y mensajes:"
    docker logs "$CONTAINER" --tail 100 2>&1 | grep -i "error\|supabase\|whatsapp_messages\|guardando mensaje\|insert" | tail -20 || echo "   No se encontraron errores recientes"
    
    echo ""
    echo "📋 Últimas líneas de logs (últimas 30):"
    docker logs "$CONTAINER" --tail 30 2>&1 | tail -20
    
    echo ""
    echo "---"
    echo ""
done

echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🔍 Si ves errores de 'column does not exist' o 'invalid column',"
echo "   significa que la estructura de la tabla no coincide con el código."
echo ""
echo "📋 Para verificar la estructura de la tabla en Supabase:"
echo "   1. Ve a https://supabase.com/dashboard"
echo "   2. Selecciona tu proyecto"
echo "   3. Ve a 'Table Editor' -> 'whatsapp_messages'"
echo "   4. Haz clic en la pestaña 'Definition' (no 'Data')"
echo "   5. Verifica qué columnas tiene la tabla"
echo ""
echo "💡 La tabla debería tener estas columnas:"
echo "   - id (uuid)"
echo "   - chat_id (uuid) - referencia a whatsapp_chats"
echo "   - body (text) - contenido del mensaje"
echo "   - is_from_me (boolean) - si el mensaje fue enviado por nosotros"
echo "   - is_read (boolean) - si el mensaje fue leído"
echo "   - created_at (timestamp)"


