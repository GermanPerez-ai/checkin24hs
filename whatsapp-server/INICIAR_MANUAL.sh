#!/bin/bash

# Script para iniciar servicios de WhatsApp manualmente con PM2
# Ejecutar desde el directorio whatsapp-server

echo "🚀 Iniciando servicios de WhatsApp manualmente..."
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

sleep 2

echo "📱 Iniciando WhatsApp 2 (Puerto 3002)..."
pm2 start whatsapp-server-baileys.js \
    --name whatsapp-2 \
    --env PORT=3002 \
    --env INSTANCE_NUMBER=2 \
    --env SUPABASE_URL="$SUPABASE_URL" \
    --env SUPABASE_ANON_KEY="$SUPABASE_KEY" \
    --env NODE_ENV=production \
    --error ./logs/whatsapp-2-error.log \
    --output ./logs/whatsapp-2-out.log \
    --log-date-format "YYYY-MM-DD HH:mm:ss Z" \
    --max-memory-restart 1G \
    --autorestart

sleep 2

echo "📱 Iniciando WhatsApp 3 (Puerto 3003)..."
pm2 start whatsapp-server-baileys.js \
    --name whatsapp-3 \
    --env PORT=3003 \
    --env INSTANCE_NUMBER=3 \
    --env SUPABASE_URL="$SUPABASE_URL" \
    --env SUPABASE_ANON_KEY="$SUPABASE_KEY" \
    --env NODE_ENV=production \
    --error ./logs/whatsapp-3-error.log \
    --output ./logs/whatsapp-3-out.log \
    --log-date-format "YYYY-MM-DD HH:mm:ss Z" \
    --max-memory-restart 1G \
    --autorestart

sleep 2

echo "📱 Iniciando WhatsApp 4 (Puerto 3004)..."
pm2 start whatsapp-server-baileys.js \
    --name whatsapp-4 \
    --env PORT=3004 \
    --env INSTANCE_NUMBER=4 \
    --env SUPABASE_URL="$SUPABASE_URL" \
    --env SUPABASE_ANON_KEY="$SUPABASE_KEY" \
    --env NODE_ENV=production \
    --error ./logs/whatsapp-4-error.log \
    --output ./logs/whatsapp-4-out.log \
    --log-date-format "YYYY-MM-DD HH:mm:ss Z" \
    --max-memory-restart 1G \
    --autorestart

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
echo "✅ Para ver logs de una instancia:"
echo "   pm2 logs whatsapp-1"
echo ""
echo "✅ Para ver todos los logs:"
echo "   pm2 logs"
echo ""
