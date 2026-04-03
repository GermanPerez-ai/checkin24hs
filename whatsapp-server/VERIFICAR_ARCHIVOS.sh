#!/bin/bash

# Script para verificar qué archivos hay en el directorio whatsapp-server

echo "🔍 Verificando archivos en el directorio..."
echo ""

cd ~/whatsapp-server || cd /root/whatsapp-server || exit 1

echo "📁 Directorio actual: $(pwd)"
echo ""
echo "📋 Archivos .js en el directorio:"
ls -la *.js 2>/dev/null || echo "   No hay archivos .js aquí"
echo ""

echo "📋 Todos los archivos en el directorio:"
ls -la
echo ""

echo "🔍 Buscando archivos relacionados con WhatsApp:"
find . -maxdepth 1 -name "*whatsapp*" -type f
echo ""
