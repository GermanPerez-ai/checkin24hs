#!/bin/bash

# ============================================
# SCRIPT: Verificar Código del Dashboard
# ============================================
# Este script verifica que no haya código suelto
# y que todo funcione correctamente

echo "🔍 VERIFICACIÓN COMPLETA DEL CÓDIGO DEL DASHBOARD"
echo "=================================================="
echo ""

DASHBOARD_FILE="dashboard.html"

if [ ! -f "$DASHBOARD_FILE" ]; then
    echo "❌ ERROR: No se encontró el archivo $DASHBOARD_FILE"
    exit 1
fi

echo "✅ Archivo encontrado: $DASHBOARD_FILE"
echo ""

# ============================================
# 1. VERIFICAR CÓDIGO SUELTO
# ============================================
echo "📋 1. Verificando código suelto (fuera de funciones)..."
echo ""

# Buscar líneas que parecen código suelto (con indentación pero no dentro de funciones)
SUELTO_COUNT=$(grep -n "^            const\|^            if\|^            }" "$DASHBOARD_FILE" | grep -v "function\|async function\|=>" | wc -l)

if [ "$SUELTO_COUNT" -gt 0 ]; then
    echo "⚠️  ADVERTENCIA: Se encontraron $SUELTO_COUNT líneas que podrían ser código suelto"
    echo ""
    echo "   Líneas sospechosas:"
    grep -n "^            const\|^            if\|^            }" "$DASHBOARD_FILE" | grep -v "function\|async function\|=>" | head -10 | sed 's/^/      /'
    echo ""
else
    echo "✅ No se encontró código suelto obvio"
fi
echo ""

# ============================================
# 2. VERIFICAR FUNCIONES CRÍTICAS
# ============================================
echo "📋 2. Verificando funciones críticas..."
echo ""

# Verificar handleLogin
if grep -q "window\.handleLogin\|function handleLogin" "$DASHBOARD_FILE"; then
    echo "✅ handleLogin definida"
else
    echo "❌ ERROR: handleLogin NO está definida"
fi

# Verificar searchUsers
if grep -q "window\.searchUsers\|function searchUsers" "$DASHBOARD_FILE"; then
    echo "✅ searchUsers definida"
else
    echo "❌ ERROR: searchUsers NO está definida"
fi

# Verificar showSection
if grep -q "window\.showSection\|function showSection" "$DASHBOARD_FILE"; then
    echo "✅ showSection definida"
else
    echo "❌ ERROR: showSection NO está definida"
fi

# Verificar allUsersData
if grep -q "window\.allUsersData\|var allUsersData\|let allUsersData\|const allUsersData" "$DASHBOARD_FILE"; then
    echo "✅ allUsersData definida"
else
    echo "❌ ERROR: allUsersData NO está definida"
fi

# Verificar saveHotelChanges (solo una vez)
SAVE_COUNT=$(grep -c "function saveHotelChanges\|async function saveHotelChanges" "$DASHBOARD_FILE" || echo "0")
if [ "$SAVE_COUNT" -eq 1 ]; then
    echo "✅ saveHotelChanges definida una sola vez"
elif [ "$SAVE_COUNT" -gt 1 ]; then
    echo "❌ ERROR: saveHotelChanges está duplicada ($SAVE_COUNT veces)"
else
    echo "⚠️  ADVERTENCIA: saveHotelChanges no encontrada"
fi
echo ""

# ============================================
# 3. VERIFICAR DECLARACIONES DUPLICADAS
# ============================================
echo "📋 3. Verificando declaraciones duplicadas..."
echo ""

# Buscar funciones duplicadas
DUPLICADAS=$(grep -o "function [a-zA-Z_][a-zA-Z0-9_]*" "$DASHBOARD_FILE" | sort | uniq -d)

if [ -z "$DUPLICADAS" ]; then
    echo "✅ No se encontraron funciones duplicadas obvias"
else
    echo "⚠️  ADVERTENCIA: Posibles funciones duplicadas:"
    echo "$DUPLICADAS" | sed 's/^/      /'
fi
echo ""

# ============================================
# 4. VERIFICAR SINTAXIS BÁSICA
# ============================================
echo "📋 4. Verificando sintaxis básica..."
echo ""

# Contar llaves abiertas y cerradas
OPEN_BRACES=$(grep -o "{" "$DASHBOARD_FILE" | wc -l)
CLOSE_BRACES=$(grep -o "}" "$DASHBOARD_FILE" | wc -l)

if [ "$OPEN_BRACES" -eq "$CLOSE_BRACES" ]; then
    echo "✅ Llaves balanceadas: $OPEN_BRACES abiertas, $CLOSE_BRACES cerradas"
else
    echo "❌ ERROR: Llaves desbalanceadas: $OPEN_BRACES abiertas, $CLOSE_BRACES cerradas"
fi

# Contar paréntesis
OPEN_PARENS=$(grep -o "(" "$DASHBOARD_FILE" | wc -l)
CLOSE_PARENS=$(grep -o ")" "$DASHBOARD_FILE" | wc -l)

if [ "$OPEN_PARENS" -eq "$CLOSE_PARENS" ]; then
    echo "✅ Paréntesis balanceados: $OPEN_PARENS abiertos, $CLOSE_PARENS cerrados"
else
    echo "❌ ERROR: Paréntesis desbalanceados: $OPEN_PARENS abiertos, $CLOSE_PARENS cerrados"
fi
echo ""

# ============================================
# 5. VERIFICAR CÓDIGO DESPUÉS DE COMENTARIOS
# ============================================
echo "📋 5. Verificando código después de comentarios de eliminación..."
echo ""

# Buscar código después de comentarios que indican eliminación
if grep -A 5 "Fin del código eliminado\|TODO: El código suelto" "$DASHBOARD_FILE" | grep -q "^            const\|^            if\|^            let\|^            var"; then
    echo "❌ ERROR: Se encontró código después de comentarios de eliminación"
    echo ""
    echo "   Líneas problemáticas:"
    grep -A 5 "Fin del código eliminado\|TODO: El código suelto" "$DASHBOARD_FILE" | grep -n "^            const\|^            if\|^            let\|^            var" | head -5 | sed 's/^/      /'
else
    echo "✅ No hay código después de comentarios de eliminación"
fi
echo ""

# ============================================
# 6. VERIFICAR QUE LAS FUNCIONES GLOBALES ESTÉN AL INICIO
# ============================================
echo "📋 6. Verificando que las funciones globales estén al inicio..."
echo ""

# Verificar que handleLogin esté en las primeras 2000 líneas
if head -2000 "$DASHBOARD_FILE" | grep -q "window\.handleLogin"; then
    LINE_NUM=$(head -2000 "$DASHBOARD_FILE" | grep -n "window\.handleLogin" | head -1 | cut -d: -f1)
    echo "✅ handleLogin está al inicio (línea $LINE_NUM)"
else
    echo "⚠️  ADVERTENCIA: handleLogin no está en las primeras 2000 líneas"
fi

# Verificar que searchUsers esté en las primeras 2000 líneas
if head -2000 "$DASHBOARD_FILE" | grep -q "window\.searchUsers"; then
    LINE_NUM=$(head -2000 "$DASHBOARD_FILE" | grep -n "window\.searchUsers" | head -1 | cut -d: -f1)
    echo "✅ searchUsers está al inicio (línea $LINE_NUM)"
else
    echo "⚠️  ADVERTENCIA: searchUsers no está en las primeras 2000 líneas"
fi

# Verificar que showSection esté en las primeras 2000 líneas
if head -2000 "$DASHBOARD_FILE" | grep -q "window\.showSection"; then
    LINE_NUM=$(head -2000 "$DASHBOARD_FILE" | grep -n "window\.showSection" | head -1 | cut -d: -f1)
    echo "✅ showSection está al inicio (línea $LINE_NUM)"
else
    echo "⚠️  ADVERTENCIA: showSection no está en las primeras 2000 líneas"
fi
echo ""

# ============================================
# 7. VERIFICAR ESTRUCTURA HTML BÁSICA
# ============================================
echo "📋 7. Verificando estructura HTML básica..."
echo ""

if grep -q "<!DOCTYPE html>" "$DASHBOARD_FILE"; then
    echo "✅ DOCTYPE HTML presente"
else
    echo "❌ ERROR: DOCTYPE HTML no encontrado"
fi

if grep -q "<html" "$DASHBOARD_FILE"; then
    echo "✅ Etiqueta <html> presente"
else
    echo "❌ ERROR: Etiqueta <html> no encontrada"
fi

if grep -q "</html>" "$DASHBOARD_FILE"; then
    echo "✅ Etiqueta </html> presente"
else
    echo "❌ ERROR: Etiqueta </html> no encontrada"
fi

if grep -q "<head>" "$DASHBOARD_FILE"; then
    echo "✅ Etiqueta <head> presente"
else
    echo "❌ ERROR: Etiqueta <head> no encontrada"
fi

if grep -q "<body>" "$DASHBOARD_FILE"; then
    echo "✅ Etiqueta <body> presente"
else
    echo "❌ ERROR: Etiqueta <body> no encontrada"
fi
echo ""

# ============================================
# 8. VERIFICAR ERRORES COMUNES
# ============================================
echo "📋 8. Verificando errores comunes..."
echo ""

# Verificar console.log sin punto y coma (no es error pero puede indicar problemas)
UNCLOSED_LOGS=$(grep -n "console\.log" "$DASHBOARD_FILE" | grep -v ";" | wc -l)
if [ "$UNCLOSED_LOGS" -gt 0 ]; then
    echo "⚠️  ADVERTENCIA: $UNCLOSED_LOGS console.log sin punto y coma (puede ser normal)"
fi

# Verificar await sin async
AWAIT_WITHOUT_ASYNC=$(grep -n "await " "$DASHBOARD_FILE" | grep -v "async function" | wc -l)
if [ "$AWAIT_WITHOUT_ASYNC" -gt 0 ]; then
    echo "⚠️  ADVERTENCIA: Se encontraron usos de 'await' que podrían no estar en funciones async"
fi

# Verificar return fuera de funciones (código suelto)
RETURN_SUELTO=$(grep -n "^            return" "$DASHBOARD_FILE" | wc -l)
if [ "$RETURN_SUELTO" -gt 0 ]; then
    echo "⚠️  ADVERTENCIA: Se encontraron $RETURN_SUELTO 'return' con indentación sospechosa"
fi
echo ""

# ============================================
# 9. RESUMEN FINAL
# ============================================
echo "=================================================="
echo "📊 RESUMEN DE VERIFICACIÓN"
echo "=================================================="
echo ""

ERRORS=0
WARNINGS=0

# Contar errores y advertencias
if grep -q "❌ ERROR" <<< "$(bash "$0" 2>&1)"; then
    ERRORS=$(grep -c "❌ ERROR" <<< "$(bash "$0" 2>&1)" || echo "0")
fi

if grep -q "⚠️" <<< "$(bash "$0" 2>&1)"; then
    WARNINGS=$(grep -c "⚠️" <<< "$(bash "$0" 2>&1)" || echo "0")
fi

echo "📋 Total de líneas en el archivo: $(wc -l < "$DASHBOARD_FILE")"
echo ""

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "✅ VERIFICACIÓN COMPLETA: No se encontraron problemas críticos"
    echo ""
    echo "🎯 El código parece estar listo para desplegar"
else
    echo "⚠️  Se encontraron algunos problemas:"
    echo "   - Errores: $ERRORS"
    echo "   - Advertencias: $WARNINGS"
    echo ""
    echo "💡 Revisa los detalles arriba para corregirlos"
fi
echo ""

# ============================================
# 10. VERIFICAR INICIO NORMAL
# ============================================
echo "📋 10. Verificando que el código pueda iniciar normalmente..."
echo ""

# Verificar que no haya errores de sintaxis obvios al inicio
FIRST_SCRIPT=$(grep -n "<script>" "$DASHBOARD_FILE" | head -1 | cut -d: -f1)
if [ -n "$FIRST_SCRIPT" ]; then
    echo "✅ Primer script encontrado en línea $FIRST_SCRIPT"
    
    # Verificar que las primeras líneas de script sean válidas
    head -2000 "$DASHBOARD_FILE" | tail -n +$FIRST_SCRIPT | head -50 | grep -q "function\|const\|let\|var\|window\." && echo "✅ Las primeras líneas de script parecen válidas"
else
    echo "⚠️  ADVERTENCIA: No se encontró etiqueta <script>"
fi
echo ""

echo "=================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=================================================="
echo ""
echo "📋 Próximos pasos:"
echo "   1. Si hay errores, corrígelos antes de desplegar"
echo "   2. Si solo hay advertencias, revisa si son relevantes"
echo "   3. Despliega el código desde GitHub usando EasyPanel"
echo "   4. Verifica que el login funcione correctamente"
echo ""

