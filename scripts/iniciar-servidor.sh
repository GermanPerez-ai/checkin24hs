#!/bin/bash

# Script de inicio que asegura que las dependencias estén instaladas
# Este script se puede usar como punto de entrada del contenedor Docker

set -e

echo "🔧 Verificando dependencias..."

# Verificar si @supabase/supabase-js está instalado
if ! node -e "require('@supabase/supabase-js')" 2>/dev/null; then
    echo "📦 Instalando @supabase/supabase-js..."
    npm install @supabase/supabase-js
    echo "✅ @supabase/supabase-js instalado"
else
    echo "✅ @supabase/supabase-js ya está instalado"
fi

# Si existe package.json, instalar todas las dependencias (por si acaso)
if [ -f "package.json" ]; then
    echo "📦 Verificando todas las dependencias..."
    npm install --production --silent
fi

echo "🚀 Iniciando servidor..."
exec node server.js
