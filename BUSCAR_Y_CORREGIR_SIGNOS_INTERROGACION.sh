#!/bin/bash
# Buscar y corregir signos "?" problemáticos en dashboard.html

DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "🔍 BUSCAR Y CORREGIR SIGNOS '?'"
echo "=========================================="
echo ""

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Buscar signos "?" problemáticos (excluyendo URLs, operadores ternarios, etc.)
echo "=== Buscar signos '?' problemáticos ==="
echo "Buscando en texto visible y console.log..."
echo ""

# Buscar en texto visible (dentro de etiquetas HTML)
echo "1. Signos '?' en texto visible (HTML):"
grep -n ">[^<]*\?[^<]*<" "$DASHBOARD_PATH" | grep -v "http" | grep -v "query" | grep -v "confirm" | head -10 || echo "   (no se encontraron)"
echo ""

# Buscar en console.log
echo "2. Signos '?' en console.log:"
grep -n "console\." "$DASHBOARD_PATH" | grep "\?" | head -10 || echo "   (no se encontraron)"
echo ""

# Buscar "??" (doble signo de interrogación)
echo "3. Signos '??' (doble):"
grep -n "\?\?" "$DASHBOARD_PATH" | head -10 || echo "   (no se encontraron)"
echo ""

# Buscar en atributos placeholder, title, alt
echo "4. Signos '?' en atributos (placeholder, title, alt):"
grep -n "placeholder=\".*\?\|title=\".*\?\|alt=\".*\?" "$DASHBOARD_PATH" | head -10 || echo "   (no se encontraron)"
echo ""

echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "Si encontraste signos '?' que deberían ser emojis o texto,"
echo "puedes corregirlos manualmente o usar un script de reemplazo."
echo ""
echo "Archivo: $DASHBOARD_PATH"
echo "Backup: $BACKUP_FILE"
echo ""
