#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO MENSAJES DE WHATSAPP"
echo "=========================================="
echo ""

# Obtener contenedores de WhatsApp
CONTAINERS=$(docker ps --filter "name=whatsapp" --format "{{.Names}}")

if [ -z "$CONTAINERS" ]; then
    echo "❌ No se encontraron contenedores de WhatsApp"
    exit 1
fi

echo "📋 Contenedores encontrados:"
echo "$CONTAINERS"
echo ""

# Verificar logs de cada contenedor
for CONTAINER in $CONTAINERS; do
    echo "=========================================="
    echo "📋 Logs de $CONTAINER (últimos 50 mensajes relacionados):"
    echo "=========================================="
    
    docker logs "$CONTAINER" --tail 100 2>&1 | grep -E "(Mensaje|mensaje|guardando|Supabase|Error|error|CUOTA|quota|exceeded|egress|✅|❌|⚠️)" | tail -50
    
    echo ""
    echo "🔍 Verificando errores de cuota de Supabase..."
    docker logs "$CONTAINER" --tail 200 2>&1 | grep -i "cuota\|quota\|exceeded\|egress\|limit" | tail -10
    
    echo ""
done

echo "=========================================="
echo "📊 RESUMEN:"
echo "=========================================="
echo ""
echo "Si ves mensajes como:"
echo "  ⚠️ CUOTA DE SUPABASE EXCEDIDA"
echo "  Error: quota exceeded"
echo "  Error: egress limit"
echo ""
echo "Entonces el problema es que Supabase está bloqueando las operaciones."
echo ""
echo "💡 SOLUCIONES:"
echo "1. Actualizar el plan de Supabase (recomendado)"
echo "2. Esperar al próximo ciclo de facturación (28 de enero)"
echo "3. Reducir el uso de Egress (menos consultas a Supabase)"
echo ""
