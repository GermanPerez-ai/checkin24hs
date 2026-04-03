#!/bin/bash
# 🔍 Buscar el archivo whatsapp-server-baileys.js

echo "=============================================================="
echo "🔍 BUSCANDO ARCHIVO whatsapp-server-baileys.js"
echo "=============================================================="
echo ""

# 1. Buscar en directorio actual y subdirectorios
echo "1️⃣  Buscando en /root..."
find /root -name "whatsapp-server-baileys.js" 2>/dev/null
echo ""

# 2. Buscar en /home
echo "2️⃣  Buscando en /home..."
find /home -name "whatsapp-server-baileys.js" 2>/dev/null
echo ""

# 3. Buscar en directorio actual
echo "3️⃣  Buscando en directorio actual ($(pwd))..."
find . -name "whatsapp-server-baileys.js" 2>/dev/null
echo ""

# 4. Ver archivos en directorio actual
echo "4️⃣  Archivos en directorio actual:"
ls -la *.js 2>/dev/null || echo "   No hay archivos .js aquí"
echo ""

# 5. Ver estructura de directorios
echo "5️⃣  Estructura de directorios:"
ls -la
echo ""

# 6. Buscar en todo el sistema (puede tardar)
echo "6️⃣  Buscando en todo el sistema (esto puede tardar)..."
find / -name "whatsapp-server-baileys.js" 2>/dev/null | head -10
echo ""

echo "=============================================================="
echo "✅ BÚSQUEDA COMPLETADA"
echo "=============================================================="
echo ""
