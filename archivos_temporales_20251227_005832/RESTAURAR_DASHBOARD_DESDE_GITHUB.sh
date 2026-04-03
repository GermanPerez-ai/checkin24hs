#!/bin/bash
# Restaurar dashboard desde GitHub

cd ~/checkin24hs

echo "=== Verificar estado de Git ==="
git status

echo ""
echo "=== Ver historial reciente de dashboard.html ==="
git log --oneline --all -10 -- dashboard.html

echo ""
echo "=== Ver si dashboard.html está en el repositorio ==="
git ls-files | grep dashboard.html

echo ""
echo "=== Ver tamaño del archivo en Git ==="
git ls-tree HEAD dashboard.html 2>/dev/null || echo "⚠️  dashboard.html no está en el repositorio"

echo ""
echo "=== Verificar si hay cambios locales ==="
git diff dashboard.html

echo ""
echo "=== Restaurar dashboard.html desde Git ==="
git checkout HEAD -- dashboard.html 2>/dev/null || git checkout main -- dashboard.html 2>/dev/null

echo ""
echo "=== Verificar que se restauró ==="
ls -lh dashboard.html
head -3 dashboard.html

echo ""
echo "=== Si el archivo sigue vacío, buscar en commits anteriores ==="
if [ ! -s dashboard.html ]; then
    echo "Buscando en commits anteriores..."
    git log --all --full-history --oneline -- dashboard.html | head -5
    echo ""
    echo "Para restaurar desde un commit específico:"
    echo "git checkout <commit-hash> -- dashboard.html"
fi

