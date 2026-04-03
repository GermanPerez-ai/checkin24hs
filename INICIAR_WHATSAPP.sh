#!/bin/bash

# Script para iniciar todas las instancias de WhatsApp
# Ejecutar: bash INICIAR_WHATSAPP.sh

echo "=========================================="
echo "  INICIANDO INSTANCIAS DE WHATSAPP"
echo "=========================================="
echo ""

# Ir al directorio del servidor
cd /root/checkin24hs/whatsapp-server || {
    echo "❌ Error: No se encontró el directorio /root/checkin24hs/whatsapp-server"
    exit 1
}

echo "📁 Directorio actual: $(pwd)"
echo ""

# Verificar que existe el archivo del servidor
if [ ! -f "whatsapp-server.js" ]; then
    echo "❌ Error: No se encontró whatsapp-server.js"
    exit 1
fi

# Verificar que existe ecosystem.config.js
if [ -f "ecosystem.config.js" ]; then
    echo "✅ Encontrado ecosystem.config.js"
    echo "🚀 Iniciando todas las instancias con PM2..."
    pm2 start ecosystem.config.js
    
    if [ $? -eq 0 ]; then
        echo "✅ Instancias iniciadas correctamente"
        echo ""
        echo "📊 Estado actual:"
        pm2 list
        echo ""
        echo "💾 Guardando configuración PM2..."
        pm2 save
        echo ""
        echo "✅ ¡Completado! Las instancias están iniciando."
        echo ""
        echo "📋 Próximos pasos:"
        echo "   1. Ver logs: pm2 logs whatsapp-1"
        echo "   2. Escanear el código QR que aparece en los logs"
        echo "   3. Repetir para whatsapp-2, whatsapp-3, whatsapp-4"
        echo ""
    else
        echo "❌ Error al iniciar con ecosystem.config.js"
        echo "🔄 Intentando iniciar manualmente..."
    fi
else
    echo "⚠️  No se encontró ecosystem.config.js"
    echo "🔄 Iniciando manualmente..."
fi

# Si no se pudo iniciar con ecosystem, iniciar manualmente
if ! pm2 list | grep -q "whatsapp-1"; then
    echo ""
    echo "🚀 Iniciando instancias manualmente..."
    
    SUPABASE_URL="https://lmoeuyasuvoqhtvhkyia.supabase.co"
    SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4"
    
    # WhatsApp 1
    echo "📱 Iniciando WhatsApp 1 (Puerto 4001)..."
    pm2 start whatsapp-server.js --name whatsapp-1 \
        --env PORT=4001 --env INSTANCE_NUMBER=1 \
        --env SUPABASE_URL="$SUPABASE_URL" \
        --env SUPABASE_ANON_KEY="$SUPABASE_KEY" \
        --env NODE_ENV=production
    
    sleep 2
    
    # WhatsApp 2
    echo "📱 Iniciando WhatsApp 2 (Puerto 4002)..."
    pm2 start whatsapp-server.js --name whatsapp-2 \
        --env PORT=4002 --env INSTANCE_NUMBER=2 \
        --env SUPABASE_URL="$SUPABASE_URL" \
        --env SUPABASE_ANON_KEY="$SUPABASE_KEY" \
        --env NODE_ENV=production
    
    sleep 2
    
    # WhatsApp 3
    echo "📱 Iniciando WhatsApp 3 (Puerto 4003)..."
    pm2 start whatsapp-server.js --name whatsapp-3 \
        --env PORT=4003 --env INSTANCE_NUMBER=3 \
        --env SUPABASE_URL="$SUPABASE_URL" \
        --env SUPABASE_ANON_KEY="$SUPABASE_KEY" \
        --env NODE_ENV=production
    
    sleep 2
    
    # WhatsApp 4
    echo "📱 Iniciando WhatsApp 4 (Puerto 4004)..."
    pm2 start whatsapp-server.js --name whatsapp-4 \
        --env PORT=4004 --env INSTANCE_NUMBER=4 \
        --env SUPABASE_URL="$SUPABASE_URL" \
        --env SUPABASE_ANON_KEY="$SUPABASE_KEY" \
        --env NODE_ENV=production
    
    echo ""
    echo "💾 Guardando configuración PM2..."
    pm2 save
fi

echo ""
echo "=========================================="
echo "  VERIFICACION FINAL"
echo "=========================================="
echo ""
pm2 list
echo ""
echo "✅ Para ver los códigos QR, ejecuta:"
echo "   pm2 logs whatsapp-1"
echo "   pm2 logs whatsapp-2"
echo "   pm2 logs whatsapp-3"
echo "   pm2 logs whatsapp-4"
echo ""




