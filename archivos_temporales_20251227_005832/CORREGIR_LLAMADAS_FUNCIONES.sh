#!/bin/bash
# Script para corregir las llamadas a funciones globales

cd /root/checkin24hs || exit 1

echo "=========================================="
echo "Corrigiendo llamadas a funciones"
echo "=========================================="
echo ""

# Backup
cp dashboard.html "dashboard.html.backup_antes_corregir_llamadas_$(date +%Y%m%d_%H%M%S)"
echo "Backup creado"
echo ""

# Aplicar correcciones con Python
python3 << 'PYTHON_EOF'
import re

file_path = '/root/checkin24hs/dashboard.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

print("1. Corrigiendo llamadas a loadAIConfigFromSupabase...")
# Cambiar loadAIConfigFromSupabase() a window.loadAIConfigFromSupabase()
# Pero solo donde NO es la definición
content = re.sub(
    r'(?<!window\.)(?<!function )loadAIConfigFromSupabase\(\)',
    'window.loadAIConfigFromSupabase()',
    content
)
print("   OK: Llamadas corregidas")

print("2. Corrigiendo llamadas a loadWhatsAppCards...")
# Cambiar loadWhatsAppCards() a window.loadWhatsAppCards()
# Pero solo donde NO es la definición
content = re.sub(
    r'(?<!window\.)(?<!function )loadWhatsAppCards\(\)',
    'window.loadWhatsAppCards()',
    content
)
print("   OK: Llamadas corregidas")

print("3. Corrigiendo posible error en linea 5168...")
# Buscar y corregir el console.log con espacio extra
content = re.sub(
    r"console\.log\(' Intentando iniciar sesión\.\.\.'\)",
    "console.log('Intentando iniciar sesion...')",
    content
)
print("   OK: Error de sintaxis corregido")

# Guardar
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("")
print("Correcciones aplicadas exitosamente")
PYTHON_EOF

echo ""
echo "Verificando correcciones..."
grep -n "window.loadAIConfigFromSupabase()" dashboard.html | head -3
grep -n "window.loadWhatsAppCards()" dashboard.html | head -3

echo ""
echo "=========================================="
echo "Correcciones aplicadas"
echo "=========================================="
echo ""
echo "Ahora aplica al contenedor:"
echo "  CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "  docker cp dashboard.html \${CONTAINER_ID}:/app/dashboard.html"
echo "  docker service update --force checkin24hs_dashboard"
echo "  sleep 30"
echo "  NEW_CONTAINER_ID=\$(docker ps | grep checkin24hs_dashboard | awk '{print \$1}' | head -1)"
echo "  docker cp dashboard.html \${NEW_CONTAINER_ID}:/app/dashboard.html"
echo ""


