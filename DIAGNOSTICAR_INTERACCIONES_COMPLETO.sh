#!/bin/bash
# Script completo para diagnosticar interacciones de Flor

echo "=========================================="
echo "DIAGNÓSTICO COMPLETO: INTERACCIONES DE FLOR"
echo "=========================================="
echo ""

# Buscar contenedor de WhatsApp
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️ No se encontró contenedor de WhatsApp corriendo"
    echo "   El servicio puede estar reiniciándose"
    CONTAINER_ID=$(docker ps -a | grep whatsapp | grep -v nginx | head -1 | awk '{print $1}')
    if [ -n "$CONTAINER_ID" ]; then
        echo "   Usando último contenedor: $CONTAINER_ID"
    fi
else
    echo "Contenedor: $CONTAINER_ID"
fi
echo ""

# 1. Verificar logs de guardado de interacciones
echo "=== PASO 1: LOGS DE GUARDADO DE INTERACCIONES ==="
echo ""
if [ -n "$CONTAINER_ID" ]; then
    echo "Últimas interacciones guardadas (últimas 20):"
    docker logs $CONTAINER_ID --tail 500 2>&1 | grep -iE "Interacción guardada|flor_interactions|guardarFlorInteraction" | tail -20
    echo ""
    
    echo "Errores al guardar interacciones:"
    ERRORES_INTER=$(docker logs $CONTAINER_ID --tail 500 2>&1 | grep -iE "Error guardando.*flor_interactions|Error.*flor_interactions" | tail -10)
    if [ -n "$ERRORES_INTER" ]; then
        echo "❌ Errores encontrados:"
        echo "$ERRORES_INTER"
    else
        echo "✅ No se encontraron errores al guardar interacciones"
    fi
    echo ""
else
    echo "⚠️ No se puede verificar logs (contenedor no encontrado)"
    echo ""
fi

# 2. Verificar función guardarFlorInteraction en el código
echo "=== PASO 2: VERIFICAR CÓDIGO DE GUARDADO ==="
echo ""
if [ -n "$CONTAINER_ID" ]; then
    echo "Buscando función guardarFlorInteraction:"
    docker exec $CONTAINER_ID grep -A 5 "async function guardarFlorInteraction" /app/whatsapp-server-baileys.js | head -10
    echo ""
    
    echo "Verificando que inserta en flor_interactions:"
    docker exec $CONTAINER_ID grep -A 2 "from('flor_interactions')" /app/whatsapp-server-baileys.js | head -5
    echo ""
else
    echo "⚠️ No se puede verificar código (contenedor no encontrado)"
    echo ""
fi

# 3. Verificar variables de entorno de Supabase
echo "=== PASO 3: VARIABLES DE ENTORNO SUPABASE ==="
echo ""
if [ -n "$CONTAINER_ID" ]; then
    echo "Variables relacionadas con Supabase:"
    docker exec $CONTAINER_ID env | grep -E "(SUPABASE|SAVE_TO_SUPABASE)" | grep -v "PASSWORD\|SECRET"
    echo ""
else
    echo "⚠️ No se puede verificar variables (contenedor no encontrado)"
    echo ""
fi

# 4. Verificar si hay mensajes siendo procesados
echo "=== PASO 4: MENSAJES PROCESADOS POR FLOR ==="
echo ""
if [ -n "$CONTAINER_ID" ]; then
    echo "Últimos mensajes procesados por Flor:"
    docker logs $CONTAINER_ID --tail 500 2>&1 | grep -iE "Flor respondió|procesando.*mensaje|procesarConFlor" | tail -10
    echo ""
else
    echo "⚠️ No se puede verificar mensajes (contenedor no encontrado)"
    echo ""
fi

echo "=========================================="
echo "VERIFICACIÓN EN SUPABASE"
echo "=========================================="
echo ""
echo "Para verificar directamente en Supabase:"
echo ""
echo "1. Accede a tu proyecto de Supabase: https://supabase.com"
echo "2. Ve a 'Table Editor'"
echo "3. Busca la tabla 'flor_interactions'"
echo "4. Verifica que tenga datos recientes"
echo ""
echo "O ejecuta esta consulta SQL en Supabase SQL Editor:"
echo ""
echo "-- Verificar que la tabla existe"
echo "SELECT EXISTS ("
echo "    SELECT FROM information_schema.tables"
echo "    WHERE table_schema = 'public'"
echo "    AND table_name = 'flor_interactions'"
echo ");"
echo ""
echo "-- Contar interacciones"
echo "SELECT COUNT(*) as total FROM flor_interactions;"
echo ""
echo "-- Ver últimas 10 interacciones"
echo "SELECT * FROM flor_interactions"
echo "ORDER BY created_at DESC"
echo "LIMIT 10;"
echo ""
echo "-- Verificar estructura de la tabla"
echo "SELECT column_name, data_type, is_nullable"
echo "FROM information_schema.columns"
echo "WHERE table_schema = 'public'"
echo "  AND table_name = 'flor_interactions'"
echo "ORDER BY ordinal_position;"
echo ""

echo "=========================================="
echo "VERIFICAR TABLAS ANTIGUAS DEL CRM"
echo "=========================================="
echo ""
echo "Si hay tablas antiguas del CRM, pueden estar causando confusión."
echo "Verifica en Supabase si existen estas tablas:"
echo ""
echo "✅ CORRECTA:"
echo "   - flor_interactions (debe usarse)"
echo ""
echo "❌ POSIBLES TABLAS ANTIGUAS (verificar si existen):"
echo "   - interactions"
echo "   - crm_interactions"
echo "   - chat_interactions"
echo "   - flor_chat_interactions"
echo ""
echo "Si existen tablas antiguas, pueden estar causando confusión."
echo "La tabla correcta es 'flor_interactions' con estas columnas:"
echo "   - id (uuid)"
echo "   - phone (varchar)"
echo "   - user_message (text)"
echo "   - bot_response (text)"
echo "   - intent (varchar)"
echo "   - success (boolean)"
echo "   - used_ai (boolean)"
echo "   - created_at (timestamp)"
echo "   - whatsapp_instance (integer)"
echo ""

echo "=========================================="
echo "VERIFICAR CONEXIÓN DESDE EL DASHBOARD"
echo "=========================================="
echo ""
echo "Para verificar desde el navegador:"
echo ""
echo "1. Abre el dashboard: http://72.61.58.240:3000"
echo "2. Abre la consola del navegador (F12)"
echo "3. Ve a la pestaña 'Interacciones'"
echo "4. Busca en la consola mensajes como:"
echo "   - '🌸 X interacciones cargadas desde Supabase'"
echo "   - '❌ Error obteniendo interacciones'"
echo "   - '⚠️ Supabase no está inicializado'"
echo ""
echo "5. También puedes ejecutar en la consola:"
echo "   window.supabaseClient.getFlorInteractions(10).then(console.log)"
echo ""
