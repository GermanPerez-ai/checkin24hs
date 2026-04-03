#!/bin/bash

echo "=========================================="
echo "📦 ACTUALIZAR DASHBOARD DESDE GITHUB"
echo "=========================================="
echo ""

# 1. Ir al directorio
echo "1️⃣ Cambiando al directorio del dashboard..."
cd ~/checkin24hs || {
    echo "❌ No se pudo acceder a ~/checkin24hs"
    exit 1
}
echo "✅ Directorio actual: $(pwd)"
echo ""

# 2. Verificar estado de git
echo "2️⃣ Verificando estado de Git..."
git status --short
echo ""

# 3. Hacer backup
echo "3️⃣ Creando backup de dashboard.html..."
if [ -f "dashboard.html" ]; then
    BACKUP_NAME="dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
    cp dashboard.html "$BACKUP_NAME"
    echo "✅ Backup creado: $BACKUP_NAME"
    ls -lh "$BACKUP_NAME"
else
    echo "⚠️ dashboard.html no existe en el directorio actual"
fi
echo ""

# 4. Verificar cambios remotos
echo "4️⃣ Verificando cambios en GitHub..."
git fetch origin main
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main)

echo "Commit local:  $LOCAL_COMMIT"
echo "Commit remoto: $REMOTE_COMMIT"
echo ""

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo "✅ Ya estás en la última versión"
else
    echo "📥 Hay cambios nuevos en GitHub"
    echo ""
    echo "Cambios en dashboard.html:"
    git log --oneline "$LOCAL_COMMIT..$REMOTE_COMMIT" -- dashboard.html
    echo ""
fi
echo ""

# 5. Hacer pull
echo "5️⃣ Descargando cambios desde GitHub..."
git pull origin main
PULL_EXIT=$?

if [ $PULL_EXIT -ne 0 ]; then
    echo "❌ Error al hacer pull"
    echo ""
    echo "Si hay conflictos, resuélvelos manualmente:"
    echo "  git status"
    echo "  # Resolver conflictos"
    echo "  git add dashboard.html"
    echo "  git commit -m 'Resolve conflicts'"
    exit 1
fi

echo "✅ Pull completado"
echo ""

# 6. Verificar archivo actualizado
echo "6️⃣ Verificando dashboard.html actualizado..."
if [ -f "dashboard.html" ]; then
    echo "✅ dashboard.html existe"
    ls -lh dashboard.html
    echo ""
    echo "Última modificación:"
    git log --oneline -1 -- dashboard.html
else
    echo "❌ dashboard.html no existe después del pull"
    exit 1
fi
echo ""

# 7. Reiniciar PM2
echo "7️⃣ Reiniciando servicio dashboard en PM2..."
pm2 restart dashboard
RESTART_EXIT=$?

if [ $RESTART_EXIT -ne 0 ]; then
    echo "❌ Error al reiniciar dashboard"
    echo ""
    echo "Verificar si el servicio existe:"
    echo "  pm2 list | grep dashboard"
    echo ""
    echo "Si no existe, iniciarlo:"
    echo "  cd ~/checkin24hs"
    echo "  pm2 start server.js --name dashboard"
    exit 1
fi

echo "✅ Dashboard reiniciado"
echo ""

# 8. Ver logs
echo "8️⃣ Verificando logs del dashboard..."
sleep 3
pm2 logs dashboard --lines 15 --nostream
echo ""

# 9. Verificar estado
echo "9️⃣ Estado final del servicio:"
pm2 status | grep dashboard
echo ""

# 10. Verificar que está corriendo
echo "🔟 Verificando que el puerto 3000 está activo..."
sleep 2
if netstat -tulpn 2>/dev/null | grep :3000 > /dev/null || ss -tulpn 2>/dev/null | grep :3000 > /dev/null; then
    echo "✅ Puerto 3000 está activo"
    echo ""
    echo "Probar acceso:"
    echo "  curl -I http://localhost:3000"
    curl -I http://localhost:3000 2>&1 | head -5
else
    echo "⚠️ Puerto 3000 no está activo"
fi
echo ""

echo "=========================================="
echo "✅ ACTUALIZACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Verificar en el navegador:"
echo "  https://dashboard.checkin24hs.com"
echo ""
echo "Si hay problemas, revisar logs:"
echo "  pm2 logs dashboard --lines 50"
echo ""

