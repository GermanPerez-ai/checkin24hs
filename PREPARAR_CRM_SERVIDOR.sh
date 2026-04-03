#!/bin/bash
# Script para preparar CRM en el servidor

cd /root/checkin24hs || exit 1

echo "=========================================="
echo "Preparando CRM para EasyPanel"
echo "=========================================="
echo ""

# Crear directorio CRM si no existe
mkdir -p crm
cd crm

echo "1. Copiando archivos necesarios..."

# Copiar archivos desde deploy si existen
if [ -d "../deploy" ]; then
    echo "   Copiando desde deploy/..."
    cp ../deploy/crm.html . 2>/dev/null && echo "   OK: crm.html" || echo "   ERROR: crm.html no encontrado"
    cp ../deploy/crm.js . 2>/dev/null && echo "   OK: crm.js" || echo "   ERROR: crm.js no encontrado"
    cp ../deploy/supabase-client.js . 2>/dev/null && echo "   OK: supabase-client.js" || echo "   ERROR: supabase-client.js no encontrado"
    cp ../deploy/supabase-config.js . 2>/dev/null && echo "   OK: supabase-config.js" || echo "   ERROR: supabase-config.js no encontrado"
    cp ../deploy/flor-*.js . 2>/dev/null && echo "   OK: archivos flor-*.js" || echo "   ERROR: archivos flor-*.js no encontrados"
    cp ../deploy/logo.png . 2>/dev/null && echo "   OK: logo.png" || echo "   ADVERTENCIA: logo.png no encontrado"
else
    echo "   ADVERTENCIA: directorio deploy/ no encontrado"
fi

# Copiar desde raíz si no están en deploy
if [ ! -f "supabase-client.js" ] && [ -f "../supabase-client.js" ]; then
    cp ../supabase-client.js . && echo "   OK: supabase-client.js (desde raiz)"
fi

if [ ! -f "supabase-config.js" ] && [ -f "../supabase-config.js" ]; then
    cp ../supabase-config.js . && echo "   OK: supabase-config.js (desde raiz)"
fi

# Copiar serve-crm.js si existe
if [ -f "../serve-crm.js" ]; then
    cp ../serve-crm.js . && echo "   OK: serve-crm.js"
else
    echo "   ERROR: serve-crm.js no encontrado"
fi

echo ""
echo "2. Verificando archivos..."
ls -lh

echo ""
echo "3. Verificando que crm.html tenga supabase..."
if grep -q "supabase-client.js" crm.html; then
    echo "   OK: supabase-client.js incluido en crm.html"
else
    echo "   ADVERTENCIA: supabase-client.js NO incluido en crm.html"
fi

echo ""
echo "=========================================="
echo "CRM preparado en: /root/checkin24hs/crm/"
echo "=========================================="
echo ""
echo "Archivos listos para usar en EasyPanel"
echo ""


