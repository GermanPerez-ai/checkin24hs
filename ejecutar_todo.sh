#!/bin/bash

echo "=========================================="
echo "🚀 SCRIPT MAESTRO - Reparación Completa"
echo "=========================================="
echo ""
echo "Este script ejecutará:"
echo "  1. Arreglar webmail"
echo "  2. Arreglar EasyPanel"
echo "  3. Actualizar dashboard desde GitHub"
echo ""
read -p "¿Continuar? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Cancelado"
    exit 1
fi
echo ""

# 1. Arreglar webmail
echo "=========================================="
echo "📧 PASO 1: ARREGLAR WEBMAIL"
echo "=========================================="
bash arreglar_webmail.sh
echo ""
read -p "Presiona Enter para continuar al siguiente paso..."
echo ""

# 2. Arreglar EasyPanel
echo "=========================================="
echo "⚙️ PASO 2: ARREGLAR EASYPANEL"
echo "=========================================="
bash arreglar_easypanel.sh
echo ""
read -p "Presiona Enter para continuar al siguiente paso..."
echo ""

# 3. Actualizar dashboard
echo "=========================================="
echo "📦 PASO 3: ACTUALIZAR DASHBOARD"
echo "=========================================="
bash actualizar_dashboard_github.sh
echo ""

echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "Verificaciones finales:"
echo "  1. Webmail: https://webmail.checkin24hs.com"
echo "  2. EasyPanel: https://hpanel.hostinger.com/vps/1152402/overview → Gestionar panel"
echo "  3. Dashboard: https://dashboard.checkin24hs.com"
echo ""

