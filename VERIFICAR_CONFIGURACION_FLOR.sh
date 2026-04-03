#!/bin/bash
# Script para verificar la configuración de Flor IA en el servidor

echo "=========================================="
echo "VERIFICANDO CONFIGURACION DE FLOR IA"
echo "=========================================="
echo ""

# 1. Verificar que los archivos mejorados estén en el servidor
echo "=== 1. Verificando archivos ==="
FILES=(
    "/root/checkin24hs/flor-ai-service.js"
    "/root/checkin24hs/deploy/flor-ai-service.js"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file existe"
        # Verificar que tenga las mejoras de enseñanza
        if grep -q "TU MISIÓN PRINCIPAL" "$file"; then
            echo "   ✅ Contiene mejoras de enseñanza"
        else
            echo "   ⚠️ No contiene mejoras de enseñanza (archivo antiguo)"
        fi
    else
        echo "❌ $file NO existe"
    fi
done

echo ""

# 2. Verificar configuración en Supabase (desde el servidor)
echo "=== 2. Verificando configuración de IA ==="
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)

if [ -n "$CONTAINER" ]; then
    echo "✅ Contenedor WhatsApp encontrado: $CONTAINER"
    
    # Verificar que el servidor esté usando Gemini
    echo ""
    echo "Verificando configuración de Gemini..."
    docker logs "$CONTAINER" --tail 100 | grep -i "gemini\|GEMINI_API_KEY\|USE_GEMINI" | tail -5
    
    # Verificar que la IA esté habilitada
    echo ""
    echo "Verificando estado de Flor IA..."
    docker logs "$CONTAINER" --tail 100 | grep -i "FLOR_ENABLED\|AUTO_REPLY" | tail -3
else
    echo "❌ No se encontró contenedor de WhatsApp"
fi

echo ""

# 3. Probar respuesta de la IA (si está configurada)
echo "=== 3. Probando respuesta de IA ==="
echo "Para probar, envía un mensaje de WhatsApp y verifica los logs:"
echo ""
echo "  CONTAINER=\$(docker ps --filter \"name=whatsapp.1\" --format \"{{.Names}}\" | head -1)"
echo "  docker logs \"\$CONTAINER\" -f | grep -i \"gemini\|flor\|respuesta\""
echo ""

# 4. Verificar base de conocimiento en Supabase
echo "=== 4. Base de Conocimiento ==="
echo "Para verificar la base de conocimiento:"
echo "1. Ve al dashboard: https://dashboard.checkin24hs.com"
echo "2. Flor IA → Pestaña 'Conocimiento'"
echo "3. Verifica que cada hotel tenga información completa"
echo ""

echo "=========================================="
echo "VERIFICACION COMPLETA"
echo "=========================================="


