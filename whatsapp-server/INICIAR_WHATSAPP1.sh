#!/bin/bash

# Script para iniciar solo WhatsApp 1 con PM2
# Ejecutar desde el directorio whatsapp-server

echo "🚀 Iniciando WhatsApp 1..."
echo ""

cd ~/whatsapp-server || cd /root/whatsapp-server || exit 1

# Verificar que existe whatsapp-server-baileys.js
if [ ! -f "whatsapp-server-baileys.js" ]; then
    echo "❌ Error: No se encuentra whatsapp-server-baileys.js"
    exit 1
fi

# Crear directorio de logs si no existe
mkdir -p logs

# Variables de entorno
SUPABASE_URL="https://lmoeuyasuvoqhtvhkyia.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4"

# Verificar si ya está corriendo
if pm2 list | grep -q "whatsapp-1"; then
    echo "⚠️  whatsapp-1 ya está corriendo. Reiniciando..."
    pm2 restart whatsapp-1
else
    echo "📱 Iniciando WhatsApp 1 (Puerto 3001)..."
    pm2 start whatsapp-server-baileys.js \
        --name whatsapp-1 \
        --env PORT=3001 \
        --env INSTANCE_NUMBER=1 \
        --env SUPABASE_URL="$SUPABASE_URL" \
        --env SUPABASE_ANON_KEY="$SUPABASE_KEY" \
        --env NODE_ENV=production \
        --error ./logs/whatsapp-1-error.log \
        --output ./logs/whatsapp-1-out.log \
        --log-date-format "YYYY-MM-DD HH:mm:ss Z" \
        --max-memory-restart 1G \
        --autorestart
fi

echo ""
echo "💾 Guardando configuración de PM2..."
pm2 save

echo ""
echo "=========================================="
echo "  ESTADO DE SERVICIOS"
echo "=========================================="
echo ""
pm2 list

echo ""
echo "✅ Para ver logs:"
echo "   pm2 logs whatsapp-1"
echo ""
echo "✅ Para ver logs en tiempo real:"
echo "   pm2 logs whatsapp-1 --lines 50"
echo ""
