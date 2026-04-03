#!/bin/bash
# Restaurar dashboard completo desde GitHub

cd ~/checkin24hs

echo "=== 1. Restaurar dashboard.html desde Git ==="
git checkout HEAD -- dashboard.html 2>/dev/null || git checkout main -- dashboard.html 2>/dev/null

# Si sigue vacío, buscar en commits anteriores
if [ ! -s dashboard.html ]; then
    echo "Buscando en commits anteriores..."
    COMMIT=$(git log --all --full-history --oneline -- dashboard.html | head -1 | cut -d' ' -f1)
    if [ -n "$COMMIT" ]; then
        echo "Restaurando desde commit: $COMMIT"
        git checkout $COMMIT -- dashboard.html
    fi
fi

echo ""
echo "=== 2. Verificar archivos de Supabase ==="
ls -la supabase-config.js supabase-client.js 2>/dev/null

# Si no existen, restaurarlos desde Git
if [ ! -f "supabase-config.js" ]; then
    echo "Restaurando supabase-config.js..."
    git checkout HEAD -- supabase-config.js 2>/dev/null || git checkout main -- supabase-config.js 2>/dev/null
fi

if [ ! -f "supabase-client.js" ]; then
    echo "Restaurando supabase-client.js..."
    git checkout HEAD -- supabase-client.js 2>/dev/null || git checkout main -- supabase-client.js 2>/dev/null
fi

echo ""
echo "=== 3. Verificar archivos restaurados ==="
ls -lh dashboard.html supabase-config.js supabase-client.js 2>/dev/null

echo ""
echo "=== 4. Verificar contenido de dashboard.html ==="
if [ -s dashboard.html ]; then
    echo "✅ dashboard.html tiene contenido ($(wc -l < dashboard.html) líneas)"
    head -3 dashboard.html
else
    echo "❌ dashboard.html sigue vacío"
fi

echo ""
echo "=== 5. Verificar configuración de Supabase ==="
if [ -f "supabase-config.js" ]; then
    grep -E "url:|anonKey:" supabase-config.js | head -2
fi

