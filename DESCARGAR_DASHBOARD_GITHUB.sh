#!/bin/bash
# Descargar dashboard desde GitHub

echo "=== 1. Verificar si ya existe el repositorio ==="
cd ~/checkin24hs
if [ -d .git ]; then
    echo "✅ Repositorio Git existe"
    echo ""
    echo "=== 2. Hacer backup del dashboard.html actual ==="
    cp dashboard.html dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
    echo "✅ Backup creado"
    
    echo ""
    echo "=== 3. Hacer git pull para obtener los últimos cambios ==="
    git pull origin main
    
    echo ""
    echo "=== 4. Verificar que se descargó el dashboard correcto ==="
    ls -lh dashboard.html
    head -5 dashboard.html
else
    echo "❌ No es un repositorio Git"
    echo ""
    echo "=== Clonar el repositorio ==="
    echo "¿Cuál es la URL del repositorio?"
    echo "Ejemplo: https://github.com/GermanPerez-ai/checkin24hs"
fi

echo ""
echo "=== 5. Reiniciar el dashboard después de actualizar ==="
pm2 restart dashboard
sleep 3
pm2 logs dashboard --lines 5 --nostream

