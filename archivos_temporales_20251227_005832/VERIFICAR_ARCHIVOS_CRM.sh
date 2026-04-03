#!/bin/bash

# Script para verificar que todos los archivos necesarios para CRM estén presentes

echo "=== Verificando archivos necesarios para CRM ==="

ERRORS=0

# Archivos en la raíz
echo ""
echo "1. Archivos en la raíz:"
for file in "Dockerfile.crm" "serve-crm.js" "package.json" "supabase-config.js" "supabase-client.js" "flor-knowledge-base.js" "flor-ai-service.js" "flor-learning-system.js" "flor-agent.js"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (FALTANTE)"
        ERRORS=$((ERRORS + 1))
    fi
done

# Archivos en deploy/
echo ""
echo "2. Archivos en deploy/:"
for file in "deploy/crm.html" "deploy/crm.js"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (FALTANTE)"
        ERRORS=$((ERRORS + 1))
    fi
done

# Verificar package.json tiene express
echo ""
echo "3. Verificando package.json:"
if [ -f "package.json" ]; then
    if grep -q '"express"' package.json; then
        echo "  ✅ package.json contiene express"
    else
        echo "  ❌ package.json NO contiene express"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  ❌ package.json no existe"
    ERRORS=$((ERRORS + 1))
fi

# Verificar Dockerfile.crm
echo ""
echo "4. Verificando Dockerfile.crm:"
if [ -f "Dockerfile.crm" ]; then
    if grep -q "serve-crm.js" Dockerfile.crm; then
        echo "  ✅ Dockerfile.crm incluye serve-crm.js"
    else
        echo "  ❌ Dockerfile.crm NO incluye serve-crm.js"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "crm.html" Dockerfile.crm; then
        echo "  ✅ Dockerfile.crm incluye crm.html"
    else
        echo "  ❌ Dockerfile.crm NO incluye crm.html"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  ❌ Dockerfile.crm no existe"
    ERRORS=$((ERRORS + 1))
fi

# Resumen
echo ""
echo "=== Resumen ==="
if [ $ERRORS -eq 0 ]; then
    echo "✅ Todos los archivos están presentes"
    echo ""
    echo "Siguiente paso:"
    echo "  1. git add ."
    echo "  2. git commit -m 'Agregar CRM completo'"
    echo "  3. git push"
    echo "  4. Crear servicio en EasyPanel con Dockerfile.crm"
else
    echo "❌ Faltan $ERRORS archivo(s)"
    echo ""
    echo "Por favor, crea los archivos faltantes antes de continuar"
fi

