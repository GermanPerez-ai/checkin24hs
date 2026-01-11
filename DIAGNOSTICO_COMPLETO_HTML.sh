#!/bin/bash
# Script para extraer y analizar la estructura HTML completa de expenses-section
# Esto ayudará a entender por qué tiene dimensiones 0x0

echo "🔍 DIAGNÓSTICO COMPLETO DE ESTRUCTURA HTML"
echo "==========================================="
echo ""

# 1. Buscar contenedor
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor dashboard"
    exit 1
fi

echo "✅ Contenedor: $CONTAINER"
echo ""

# 2. Extraer estructura completa de expenses-section
echo "1️⃣ Extrayendo estructura HTML de expenses-section..."
docker exec $CONTAINER grep -A 200 'id="expenses-section"' /app/dashboard.html | head -250 > /tmp/expenses_section_structure.txt

if [ -s /tmp/expenses_section_structure.txt ]; then
    echo "✅ Estructura extraída"
    echo ""
    echo "📋 Primeras 50 líneas de expenses-section:"
    head -50 /tmp/expenses_section_structure.txt
    echo ""
    echo "📋 Buscando table-container dentro de expenses-section..."
    grep -n "table-container" /tmp/expenses_section_structure.txt | head -5
    echo ""
    echo "📋 Buscando estilos inline en expenses-section..."
    grep -n "style=" /tmp/expenses_section_structure.txt | head -5
else
    echo "❌ No se pudo extraer la estructura"
fi

echo ""
echo "2️⃣ Verificando CSS relacionado con expenses-section..."
docker exec $CONTAINER grep -n "#expenses-section\|\.expenses-section\|expenses-section" /app/dashboard.html | grep -E "style|display|width|height" | head -20

echo ""
echo "3️⃣ Verificando JavaScript que modifica expenses-section..."
docker exec $CONTAINER grep -n "expenses-section" /app/dashboard.html | grep -E "style|display|width|getElementById" | head -20

echo ""
echo "=========================================="
echo "📋 ARCHIVO COMPLETO GUARDADO EN:"
echo "/tmp/expenses_section_structure.txt"
echo "=========================================="
