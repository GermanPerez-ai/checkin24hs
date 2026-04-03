#!/bin/bash

# Script para iniciar servicios de WhatsApp con PM2
# Ejecutar desde el directorio whatsapp-server

echo "🚀 Iniciando servicios de WhatsApp..."
echo ""

cd ~/whatsapp-server || cd /root/whatsapp-server || exit 1

# Verificar que existe ecosystem.config.js
if [ ! -f "ecosystem.config.js" ]; then
    echo "❌ Error: No se encuentra ecosystem.config.js"
    exit 1
fi

# Verificar que existe whatsapp-server-baileys.js
if [ ! -f "whatsapp-server-baileys.js" ]; then
    echo "❌ Error: No se encuentra whatsapp-server-baileys.js"
    exit 1
fi

# Crear directorio de logs si no existe
mkdir -p logs

echo "📋 Iniciando servicios con PM2..."
echo ""

# Iniciar todos los servicios usando ecosystem.config.js
pm2 start ecosystem.config.js

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
echo "✅ Para reiniciar todos los servicios:"
echo "   pm2 restart all"
echo ""
