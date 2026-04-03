#!/bin/bash
# Script para verificar interacciones de Flor en Supabase

echo "=========================================="
echo "VERIFICAR INTERACCIONES EN SUPABASE"
echo "=========================================="
echo ""

# Buscar contenedor de WhatsApp
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "⚠️ No se encontró contenedor de WhatsApp corriendo"
    echo "   Esto es normal si el servicio está reiniciándose"
    echo ""
else
    echo "Contenedor: $CONTAINER_ID"
    echo ""
    
    # Verificar logs de guardado de interacciones
    echo "=== LOGS DE GUARDADO DE INTERACCIONES ==="
    echo ""
    echo "Últimas interacciones guardadas:"
    docker logs $CONTAINER_ID --tail 200 | grep -iE "Interacción guardada|flor_interactions|guardarFlorInteraction" | tail -10
    echo ""
    
    # Verificar errores al guardar
    echo "=== ERRORES AL GUARDAR INTERACCIONES ==="
    echo ""
    ERRORES=$(docker logs $CONTAINER_ID --tail 200 | grep -iE "Error guardando.*flor_interactions|Error.*flor_interactions" | tail -5)
    if [ -n "$ERRORES" ]; then
        echo "❌ Errores encontrados:"
        echo "$ERRORES"
    else
        echo "✅ No se encontraron errores al guardar interacciones"
    fi
    echo ""
fi

echo "=========================================="
echo "VERIFICACIÓN EN SUPABASE"
echo "=========================================="
echo ""
echo "Para verificar en Supabase directamente:"
echo ""
echo "1. Accede a tu proyecto de Supabase"
echo "2. Ve a 'Table Editor'"
echo "3. Busca la tabla 'flor_interactions'"
echo "4. Verifica que tenga datos recientes"
echo ""
echo "O ejecuta esta consulta SQL en Supabase SQL Editor:"
echo ""
echo "SELECT COUNT(*) as total FROM flor_interactions;"
echo "SELECT * FROM flor_interactions ORDER BY created_at DESC LIMIT 10;"
echo ""
echo "=========================================="
echo "VERIFICAR TABLAS ANTIGUAS DEL CRM"
echo "=========================================="
echo ""
echo "Si hay tablas antiguas del CRM, pueden estar causando confusión."
echo "Verifica en Supabase si existen estas tablas:"
echo ""
echo "- flor_interactions (CORRECTA - debe usarse)"
echo "- interactions (posible tabla antigua)"
echo "- crm_interactions (posible tabla antigua)"
echo "- chat_interactions (posible tabla antigua)"
echo ""
echo "La tabla correcta es 'flor_interactions' con estas columnas:"
echo "- id (uuid, auto-generado)"
echo "- phone (text)"
echo "- user_message (text)"
echo "- bot_response (text)"
echo "- intent (text)"
echo "- success (boolean)"
echo "- used_ai (boolean)"
echo "- created_at (timestamp)"
echo "- whatsapp_instance (integer)"
echo ""
