#!/bin/bash
DASHBOARD_PATH="/root/checkin24hs/dashboard.html"

echo "=== Buscar signos '?' problemáticos ==="
echo ""

# Buscar "??" (doble signo)
echo "1. Signos '??' (doble):"
grep -n "\?\?" "$DASHBOARD_PATH" | head -15
echo ""

# Buscar en console.log con "?"
echo "2. Signos '?' en console.log:"
grep -n "console\." "$DASHBOARD_PATH" | grep "\?" | grep -v "http" | grep -v "query" | head -15
echo ""

# Buscar en texto visible (dentro de etiquetas)
echo "3. Signos '?' en texto visible:"
grep -n ">[^<]*\?[^<]*<" "$DASHBOARD_PATH" | grep -v "http" | grep -v "query" | grep -v "confirm" | grep -v "¿" | head -15
echo ""

# Buscar en placeholders
echo "4. Signos '?' en placeholders:"
grep -n "placeholder.*\?" "$DASHBOARD_PATH" | head -10
echo ""
