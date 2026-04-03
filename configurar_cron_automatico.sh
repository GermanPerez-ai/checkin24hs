#!/bin/bash
# Configurar cron job para actualizar dashboard automáticamente

echo "=== CONFIGURANDO CRON JOB AUTOMÁTICO ==="
echo ""

SCRIPT_PATH="/root/checkin24hs/APLICAR_DASHBOARD_AUTOMATICO.sh"

# Verificar que el script existe
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: No se encuentra $SCRIPT_PATH"
    echo "   Creando script..."
    
    cat > "$SCRIPT_PATH" << 'SCRIPTEOF'
#!/bin/bash
# Script automatizado para aplicar dashboard.html después de reinicios

cd /root/checkin24hs

if [ ! -f "deploy/dashboard.html" ]; then
    exit 1
fi

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    exit 1
fi

LOCAL_SIZE=$(stat -c%s deploy/dashboard.html 2>/dev/null || stat -f%z deploy/dashboard.html 2>/dev/null)
CURRENT_SIZE=$(docker exec "$CONTAINER" stat -c%s /app/dashboard.html 2>/dev/null || docker exec "$CONTAINER" stat -f%z /app/dashboard.html 2>/dev/null || echo "0")

if [ "$CURRENT_SIZE" != "$LOCAL_SIZE" ]; then
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html" 2>/dev/null
    docker exec "$CONTAINER" pkill -f "node.*server.js" 2>/dev/null || true
fi
SCRIPTEOF

    chmod +x "$SCRIPT_PATH"
    echo "✅ Script creado"
fi

echo "📝 Script: $SCRIPT_PATH"
echo ""

# Verificar si ya existe el cron job
CRON_EXISTS=$(crontab -l 2>/dev/null | grep -c "APLICAR_DASHBOARD_AUTOMATICO" || echo "0")

if [ "$CRON_EXISTS" -gt 0 ]; then
    echo "⚠️  Ya existe un cron job configurado:"
    crontab -l 2>/dev/null | grep "APLICAR_DASHBOARD_AUTOMATICO"
    echo ""
    echo "¿Deseas actualizarlo? (s/n)"
    read -r respuesta
    if [ "$respuesta" != "s" ] && [ "$respuesta" != "S" ]; then
        echo "Operación cancelada"
        exit 0
    fi
    # Remover el cron job existente
    crontab -l 2>/dev/null | grep -v "APLICAR_DASHBOARD_AUTOMATICO" | crontab -
fi

# Agregar nuevo cron job (cada 2 minutos)
echo "📅 Agregando cron job (se ejecutará cada 2 minutos)..."
(crontab -l 2>/dev/null; echo "*/2 * * * * $SCRIPT_PATH >> /root/checkin24hs/dashboard-update.log 2>&1") | crontab -

if [ $? -eq 0 ]; then
    echo "✅ Cron job configurado exitosamente"
    echo ""
    echo "📋 Cron job configurado:"
    crontab -l | grep "APLICAR_DASHBOARD_AUTOMATICO"
    echo ""
    echo "📝 Los logs se guardarán en: /root/checkin24hs/dashboard-update.log"
    echo ""
    echo "✅ Ahora el dashboard se actualizará automáticamente cada 2 minutos"
    echo "   Esto asegurará que los botones siempre estén presentes"
else
    echo "❌ Error al configurar cron job"
    exit 1
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "📋 Para ver los logs:"
echo "   tail -f /root/checkin24hs/dashboard-update.log"
echo ""
echo "📋 Para remover el cron job:"
echo "   crontab -l | grep -v 'APLICAR_DASHBOARD_AUTOMATICO' | crontab -"
echo ""

    chmod +x "$SCRIPT_PATH"
    echo "✅ Script creado"
fi

echo "📝 Script: $SCRIPT_PATH"
echo ""

# Verificar si ya existe el cron job
CRON_EXISTS=$(crontab -l 2>/dev/null | grep -c "APLICAR_DASHBOARD_AUTOMATICO" || echo "0")

if [ "$CRON_EXISTS" -gt 0 ]; then
    echo "⚠️  Ya existe un cron job configurado:"
    crontab -l 2>/dev/null | grep "APLICAR_DASHBOARD_AUTOMATICO"
    echo ""
    echo "¿Deseas actualizarlo? (s/n)"
    read -r respuesta
    if [ "$respuesta" != "s" ] && [ "$respuesta" != "S" ]; then
        echo "Operación cancelada"
        exit 0
    fi
    # Remover el cron job existente
    crontab -l 2>/dev/null | grep -v "APLICAR_DASHBOARD_AUTOMATICO" | crontab -
fi

# Agregar nuevo cron job (cada 2 minutos)
echo "📅 Agregando cron job (se ejecutará cada 2 minutos)..."
(crontab -l 2>/dev/null; echo "*/2 * * * * $SCRIPT_PATH >> /root/checkin24hs/dashboard-update.log 2>&1") | crontab -

if [ $? -eq 0 ]; then
    echo "✅ Cron job configurado exitosamente"
    echo ""
    echo "📋 Cron job configurado:"
    crontab -l | grep "APLICAR_DASHBOARD_AUTOMATICO"
    echo ""
    echo "📝 Los logs se guardarán en: /root/checkin24hs/dashboard-update.log"
    echo ""
    echo "✅ Ahora el dashboard se actualizará automáticamente cada 2 minutos"
    echo "   Esto asegurará que los botones siempre estén presentes"
else
    echo "❌ Error al configurar cron job"
    exit 1
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "📋 Para ver los logs:"
echo "   tail -f /root/checkin24hs/dashboard-update.log"
echo ""
echo "📋 Para remover el cron job:"
echo "   crontab -l | grep -v 'APLICAR_DASHBOARD_AUTOMATICO' | crontab -"
echo ""
# Script para configurar cron job que corrija automáticamente los contenedores

cd /root/checkin24hs

# Hacer el script ejecutable
chmod +x corregir_automatico.sh

# Crear entrada de cron si no existe
CRON_ENTRY="*/5 * * * * /root/checkin24hs/corregir_automatico.sh >> /root/checkin24hs/cron_correcciones.log 2>&1"

# Verificar si ya existe la entrada
if crontab -l 2>/dev/null | grep -q "corregir_automatico.sh"; then
    echo "✅ El cron job ya está configurado"
    echo ""
    echo "Entradas de cron actuales:"
    crontab -l | grep corregir_automatico
else
    # Agregar entrada de cron
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    echo "✅ Cron job configurado para ejecutarse cada 5 minutos"
fi

echo ""
echo "El script se ejecutará automáticamente cada 5 minutos"
echo "Los logs se guardarán en: /root/checkin24hs/cron_correcciones.log"
echo ""
echo "Para ver los logs en tiempo real:"
echo "  tail -f /root/checkin24hs/cron_correcciones.log"
echo ""
echo "Para desactivar el cron job:"
echo "  crontab -e"
echo "  (elimina la línea que contiene 'corregir_automatico.sh')"






# Script para configurar cron job que corrija automáticamente los contenedores

cd /root/checkin24hs

# Hacer el script ejecutable
chmod +x corregir_automatico.sh

# Crear entrada de cron si no existe
CRON_ENTRY="*/5 * * * * /root/checkin24hs/corregir_automatico.sh >> /root/checkin24hs/cron_correcciones.log 2>&1"

# Verificar si ya existe la entrada
if crontab -l 2>/dev/null | grep -q "corregir_automatico.sh"; then
    echo "✅ El cron job ya está configurado"
    echo ""
    echo "Entradas de cron actuales:"
    crontab -l | grep corregir_automatico
else
    # Agregar entrada de cron
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    echo "✅ Cron job configurado para ejecutarse cada 5 minutos"
fi

echo ""
echo "El script se ejecutará automáticamente cada 5 minutos"
echo "Los logs se guardarán en: /root/checkin24hs/cron_correcciones.log"
echo ""
echo "Para ver los logs en tiempo real:"
echo "  tail -f /root/checkin24hs/cron_correcciones.log"
echo ""
echo "Para desactivar el cron job:"
echo "  crontab -e"
echo "  (elimina la línea que contiene 'corregir_automatico.sh')"




