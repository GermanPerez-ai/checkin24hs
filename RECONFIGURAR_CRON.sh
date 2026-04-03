#!/bin/bash
# Reconfigurar cron job correctamente

echo "=== RECONFIGURANDO CRON JOB ==="
echo ""

# 1. Verificar que el script existe
if [ ! -f "/root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh" ]; then
    echo "❌ El script no existe, creándolo..."
    cat > /root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh << 'SCRIPTEOF'
#!/bin/bash
cd /root/checkin24hs
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -n "$CONTAINER" ] && [ -f "deploy/dashboard.html" ]; then
    LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
    CURRENT_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null || echo "0")
    if [ "$CURRENT_SIZE" != "$LOCAL_SIZE" ]; then
        docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html" 2>/dev/null
        docker exec "$CONTAINER" pkill -f "node.*server.js" 2>/dev/null || true
    fi
fi
SCRIPTEOF
    chmod +x /root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh
    echo "✅ Script creado"
fi

echo "✅ Script verificado: /root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh"
echo ""

# 2. Verificar cron jobs actuales
echo "📅 Cron jobs actuales:"
crontab -l 2>/dev/null || echo "   (ninguno configurado)"
echo ""

# 3. Remover cualquier entrada antigua
echo "🧹 Limpiando entradas antiguas..."
TEMP_CRON=$(mktemp)
crontab -l 2>/dev/null | grep -v "APLICAR_DASHBOARD_AUTOMATICO" > "$TEMP_CRON" || true

# 4. Agregar nuevo cron job
echo "➕ Agregando nuevo cron job..."
echo "*/2 * * * * /root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh >> /root/checkin24hs/dashboard-update.log 2>&1" >> "$TEMP_CRON"

# 5. Instalar nuevo crontab
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

if [ $? -eq 0 ]; then
    echo "✅ Cron job configurado exitosamente"
else
    echo "❌ Error al configurar cron job"
    exit 1
fi

echo ""
echo "📋 Verificando configuración:"
crontab -l | grep APLICAR_DASHBOARD_AUTOMATICO
echo ""

# 6. Probar ejecución manual
echo "🧪 Probando ejecución manual..."
/root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh
echo "Código de salida: $?"

if [ $? -eq 0 ]; then
    echo "✅ Script funciona correctamente"
else
    echo "⚠️  Script tuvo algún problema"
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "📝 El cron job se ejecutará cada 2 minutos"
echo "📋 Para ver los logs: tail -f /root/checkin24hs/dashboard-update.log"
echo "📋 Para ver todos los cron jobs: crontab -l"
echo ""





