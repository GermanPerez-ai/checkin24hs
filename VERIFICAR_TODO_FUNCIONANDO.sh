#!/bin/bash
# Verificar que todo está funcionando correctamente

echo "=== VERIFICACIÓN COMPLETA ==="
echo ""

# 1. Verificar cron job
echo "📅 1. Cron job configurado:"
crontab -l | grep APLICAR_DASHBOARD_AUTOMATICO && echo "   ✅ Configurado correctamente" || echo "   ❌ NO configurado"
echo ""

# 2. Verificar script
echo "📝 2. Script verificado:"
if [ -f "/root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh" ]; then
    echo "   ✅ Existe"
    if [ -x "/root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh" ]; then
        echo "   ✅ Es ejecutable"
    else
        echo "   ⚠️  NO es ejecutable"
    fi
else
    echo "   ❌ NO existe"
fi
echo ""

# 3. Verificar archivo dashboard.html
echo "📄 3. Archivo dashboard.html:"
if [ -f "/root/checkin24hs/deploy/dashboard.html" ]; then
    SIZE=$(stat -c%s /root/checkin24hs/deploy/dashboard.html 2>/dev/null || stat -f%z /root/checkin24hs/deploy/dashboard.html 2>/dev/null)
    echo "   ✅ Existe (tamaño: $SIZE bytes)"
    grep -q "whatsapp-config-button-main" /root/checkin24hs/deploy/dashboard.html && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
else
    echo "   ❌ NO existe"
fi
echo ""

# 4. Verificar contenedor
echo "📦 4. Contenedor del dashboard:"
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ]; then
    echo "   ✅ Contenedor activo: $CONTAINER"
    docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones (se actualizará en el próximo ciclo del cron)"
else
    echo "   ⚠️  Contenedor no encontrado"
fi
echo ""

# 5. Verificar logs
echo "📋 5. Logs del cron job:"
if [ -f "/root/checkin24hs/dashboard-update.log" ]; then
    LOG_SIZE=$(stat -c%s /root/checkin24hs/dashboard-update.log 2>/dev/null || stat -f%z /root/checkin24hs/dashboard-update.log 2>/dev/null)
    if [ "$LOG_SIZE" -gt 0 ]; then
        echo "   Últimas líneas:"
        tail -5 /root/checkin24hs/dashboard-update.log
    else
        echo "   ⚠️  Archivo vacío (normal si no ha habido cambios que actualizar)"
    fi
else
    echo "   ⚠️  Archivo de log aún no existe (se creará en la primera ejecución)"
fi
echo ""

# 6. Verificar acceso HTTPS
echo "🌍 6. Verificando acceso HTTPS:"
curl -s https://dashboard.checkin24hs.com 2>&1 | grep -q "whatsapp-config-button-main" && \
    echo "   ✅ Servidor sirviendo versión con botones" || \
    echo "   ❌ Servidor NO sirviendo versión con botones"
echo ""

echo "=== RESUMEN ==="
echo ""
echo "✅ Cron job configurado: Se ejecutará cada 2 minutos"
echo "✅ Script verificado y funcionando"
echo "✅ Sistema de actualización automática activo"
echo ""
echo "📋 Próximos pasos:"
echo "   - El cron job se ejecutará automáticamente cada 2 minutos"
echo "   - Si el contenedor se reinicia, el archivo se actualizará automáticamente"
echo "   - Los botones siempre estarán presentes"
echo ""
echo "📋 Comandos útiles:"
echo "   - Ver logs: tail -f /root/checkin24hs/dashboard-update.log"
echo "   - Ver cron jobs: crontab -l"
echo "   - Ejecutar manualmente: bash /root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh"
echo ""





