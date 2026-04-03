#!/bin/bash

echo "=========================================="
echo "VERIFICACION DE RUTA DEL DASHBOARD"
echo "=========================================="
echo ""

# 1. Verificar ruta local
echo "1. RUTA LOCAL DEL ARCHIVO"
echo ""
if [ -f "dashboard.html" ]; then
    echo "OK Archivo encontrado: $(pwd)/dashboard.html"
    echo "  Tamaño: $(du -h dashboard.html | cut -f1)"
else
    echo "ERROR: No se encontró dashboard.html"
fi
echo ""

# 2. Verificar GitHub
echo "2. CONFIGURACION DE GITHUB"
echo ""
if [ -d ".git" ]; then
    echo "OK Repositorio Git detectado:"
    git remote get-url origin 2>/dev/null | xargs echo "  Remote:"
    git branch --show-current 2>/dev/null | xargs echo "  Rama:"
    git rev-parse HEAD 2>/dev/null | cut -c1-8 | xargs echo "  Commit:"
else
    echo "ADVERTENCIA: No se detectó repositorio Git"
fi
echo ""

# 3. Verificar servidor
echo "3. CONFIGURACION DEL SERVIDOR"
echo ""
if [ -f "serve-dashboard.js" ]; then
    echo "OK Archivo serve-dashboard.js encontrado"
    PORT=$(grep -oP "PORT.*?=\s*\K\d+" serve-dashboard.js 2>/dev/null | head -1 || echo "3000")
    echo "  Puerto: $PORT"
else
    echo "ADVERTENCIA: serve-dashboard.js no encontrado"
fi
echo ""

# 4. Procesos
echo "4. PROCESOS EN EJECUCION"
echo ""
if pgrep -f "serve-dashboard.js" > /dev/null 2>&1; then
    PID=$(pgrep -f "serve-dashboard.js" | head -1)
    echo "OK Proceso detectado (PID: $PID)"
else
    echo "ADVERTENCIA: No se detectó proceso"
fi
echo ""

# 5. Resumen
echo "5. RESUMEN DE RUTAS"
echo ""
echo "  Ruta local: $(pwd)/dashboard.html"
echo "  Ruta GitHub: https://github.com/GermanPerez-ai/checkin24hs/blob/main/dashboard.html"
echo "  Ruta EasyPanel: /app/dashboard.html (dentro del contenedor)"
echo "  URL pública: https://dashboard.checkin24hs.com"
echo ""
echo "=========================================="
echo "Verificacion completada"
echo "=========================================="
