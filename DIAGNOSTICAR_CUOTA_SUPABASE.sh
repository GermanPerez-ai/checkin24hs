#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNOSTICANDO PROBLEMA DE CUOTA SUPABASE"
echo "=========================================="
echo ""

CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor de WhatsApp 1"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# 1. Verificar errores de cuota en logs recientes
echo "1️⃣ ERRORES DE CUOTA EN LOGS (últimas 500 líneas):"
echo "=========================================="
docker logs "$CONTAINER" --tail 500 2>&1 | grep -i "CUOTA\|quota\|limit\|exceeded\|egress\|429\|rate limit" | tail -30
if [ $? -ne 0 ]; then
    echo "⚠️ No se encontraron errores de cuota explícitos en los logs"
fi
echo ""

# 2. Verificar errores al guardar mensajes
echo "2️⃣ ERRORES AL GUARDAR MENSAJES:"
echo "=========================================="
docker logs "$CONTAINER" --tail 500 2>&1 | grep -i "error.*guardando\|error.*supabase\|error.*mensaje\|error.*whatsapp_messages" | tail -20
if [ $? -ne 0 ]; then
    echo "⚠️ No se encontraron errores explícitos al guardar mensajes"
fi
echo ""

# 3. Verificar si hay mensajes guardados exitosamente
echo "3️⃣ MENSAJES GUARDADOS EXITOSAMENTE:"
echo "=========================================="
docker logs "$CONTAINER" --tail 500 2>&1 | grep -i "✅.*mensaje\|mensaje guardado\|message saved" | tail -10
if [ $? -ne 0 ]; then
    echo "❌ NO se encontraron mensajes guardados exitosamente"
fi
echo ""

# 4. Verificar código de detección de cuota
echo "4️⃣ VERIFICANDO CÓDIGO DE DETECCIÓN DE CUOTA:"
echo "=========================================="
docker exec "$CONTAINER" grep -n "CUOTA DE SUPABASE EXCEDIDA" /app/whatsapp-server.js 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ El código tiene detección de cuota"
else
    echo "❌ El código NO tiene detección de cuota - Necesitas subir el código corregido"
fi
echo ""

# 5. Verificar configuración SAVE_TO_SUPABASE
echo "5️⃣ VERIFICANDO CONFIGURACIÓN:"
echo "=========================================="
docker exec "$CONTAINER" grep -n "SAVE_TO_SUPABASE" /app/whatsapp-server.js | head -3
echo ""

# 6. Ver logs completos de una operación reciente
echo "6️⃣ ÚLTIMOS LOGS COMPLETOS (últimas 50 líneas):"
echo "=========================================="
docker logs "$CONTAINER" --tail 50 2>&1 | tail -50
echo ""

echo "=========================================="
echo "📋 DIAGNÓSTICO Y SOLUCIONES:"
echo "=========================================="
echo ""
echo "Si ves '⚠️ CUOTA DE SUPABASE EXCEDIDA' en los logs:"
echo "  ✅ El código está detectando el problema correctamente"
echo "  ❌ Los mensajes NO se guardarán hasta resolver la cuota"
echo "  💡 Soluciones:"
echo "     1. Actualizar plan de Supabase (Pro plan)"
echo "     2. Esperar al próximo ciclo de facturación"
echo "     3. Optimizar uso de Supabase (reducir queries)"
echo ""
echo "Si NO ves errores pero tampoco mensajes guardados:"
echo "  - Los errores pueden estar siendo silenciados"
echo "  - Verifica que SAVE_TO_SUPABASE esté en true"
echo "  - Verifica que el código corregido esté en el servidor"
echo ""
echo "Para probar en tiempo real:"
echo "  1. Ejecuta: docker logs \"$CONTAINER\" -f"
echo "  2. Envía un mensaje de prueba desde WhatsApp"
echo "  3. Observa los logs para ver qué error aparece"
echo ""



