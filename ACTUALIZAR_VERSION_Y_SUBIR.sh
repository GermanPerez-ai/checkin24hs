#!/bin/bash
# Script completo: Incrementar versión, commit y push a GitHub

echo "=========================================="
echo "🚀 ACTUALIZAR VERSIÓN Y SUBIR A GITHUB"
echo "=========================================="
echo ""

# Paso 1: Incrementar versión
echo "[1/4] Incrementando build number..."
bash INCREMENTAR_VERSION.sh

if [ $? -ne 0 ]; then
    echo "❌ Error al incrementar versión"
    exit 1
fi
echo ""

# Paso 2: Agregar al staging
echo "[2/4] Agregando cambios a Git..."
git add deploy/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo agregado"
else
    echo "❌ Error al agregar archivo"
    exit 1
fi
echo ""

# Paso 3: Obtener nuevo build number para el commit message
NEW_BUILD=$(grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" deploy/dashboard.html | grep -oP "\d+" | head -1)
NEW_TIMESTAMP=$(grep -oP "window\.DASHBOARD_BUILD\s*=\s*'[^']+'" deploy/dashboard.html | grep -oP "'[^']+'" | tr -d "'" | head -1)

# Paso 4: Commit
echo "[3/4] Creando commit..."
COMMIT_MSG="Build #$NEW_BUILD: Actualizar versión del dashboard

- Build number: $NEW_BUILD
- Timestamp: $NEW_TIMESTAMP
- Correcciones de codificación UTF-8 aplicadas"

git commit -m "$COMMIT_MSG"

if [ $? -eq 0 ]; then
    echo "✅ Commit creado"
else
    echo "⚠️  No se pudo crear commit (puede que no haya cambios)"
fi
echo ""

# Paso 5: Push
echo "[4/4] Subiendo a GitHub..."
git push origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ ÉXITO: Versión actualizada y subida"
    echo "=========================================="
    echo ""
    echo "📋 PRÓXIMOS PASOS:"
    echo "1. Ve a EasyPanel → Servicio 'dashboard'"
    echo "2. Haz clic en 'Deploy' o 'Redeploy'"
    echo "3. Espera 2-5 minutos"
    echo "4. Recarga la página con Ctrl+F5"
    echo "5. Verifica que la versión se muestre en el sidebar"
    echo ""
    echo "Versión desplegada: Build #$NEW_BUILD"
    echo ""
else
    echo ""
    echo "❌ Error al subir cambios"
    echo "   Verifica tus credenciales de GitHub"
    exit 1
fi
