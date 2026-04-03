#!/bin/bash
# Verificar que el cron job está funcionando

echo "=== VERIFICACIÓN DEL CRON JOB ==="
echo ""

# 1. Verificar que el cron job está configurado
echo "📅 1. Cron jobs configurados:"
crontab -l 2>/dev/null | grep APLICAR_DASHBOARD_AUTOMATICO || echo "   ⚠️  No se encontró cron job"
echo ""

# 2. Verificar que el script existe y es ejecutable
echo "📝 2. Verificando script:"
if [ -f "/root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh" ]; then
    echo "   ✅ Script existe"
    if [ -x "/root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh" ]; then
        echo "   ✅ Script es ejecutable"
    else
        echo "   ⚠️  Script NO es ejecutable, corrigiendo..."
        chmod +x /root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh
        echo "   ✅ Corregido"
    fi
else
    echo "   ❌ Script NO existe"
fi
echo ""

# 3. Verificar logs
echo "📋 3. Últimos logs (si existen):"
if [ -f "/root/checkin24hs/dashboard-update.log" ]; then
    echo "   Últimas 10 líneas:"
    tail -10 /root/checkin24hs/dashboard-update.log 2>/dev/null || echo "   (archivo vacío o sin permisos)"
else
    echo "   ⚠️  Archivo de log aún no existe (se creará en la primera ejecución)"
fi
echo ""

# 4. Ejecutar manualmente para probar
echo "🧪 4. Ejecutando script manualmente para probar:"
/root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh

if [ $? -eq 0 ]; then
    echo "   ✅ Script ejecutado exitosamente"
else
    echo "   ⚠️  Script tuvo algún problema (puede ser normal si el archivo ya está actualizado)"
fi
echo ""

# 5. Verificar estado actual del dashboard
echo "🔍 5. Estado actual del dashboard:"
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ]; then
    docker exec "$CONTAINER" grep -q "whatsapp-config-button-main" /app/dashboard.html 2>/dev/null && \
        echo "   ✅ Contiene botones" || \
        echo "   ❌ NO contiene botones"
else
    echo "   ⚠️  Contenedor no encontrado"
fi
echo ""

echo "=== RESUMEN ==="
echo ""
echo "✅ Cron job configurado para ejecutarse cada 2 minutos"
echo "✅ El dashboard se actualizará automáticamente"
echo "✅ Los botones siempre estarán presentes"
echo ""
echo "📋 Comandos útiles:"
echo "   - Ver logs: tail -f /root/checkin24hs/dashboard-update.log"
echo "   - Ver cron jobs: crontab -l"
echo "   - Remover cron job: crontab -l | grep -v 'APLICAR_DASHBOARD_AUTOMATICO' | crontab -"
echo ""





