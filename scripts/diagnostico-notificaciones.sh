#!/bin/bash
# Script de diagnóstico para sistemas de notificaciones
# Uso: bash scripts/diagnostico-notificaciones.sh

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 DIAGNÓSTICO: SISTEMAS DE NOTIFICACIONES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ===== 1. SERVICIO ANA =====
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "┃ 1. SERVICIO ANA (ana.checkin24hs.com)"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar contenedor
if docker ps | grep -q "ana"; then
    echo "✅ Contenedor Ana está corriendo"
    CONTAINER=$(docker ps | grep ana | awk '{print $NF}')
    echo "   Container: $CONTAINER"
else
    echo "❌ Contenedor Ana NO está corriendo"
    echo "   → docker ps | grep ana (sin resultados)"
fi
echo ""

# Verificar servicio (si es Docker Swarm)
if docker service ls 2>/dev/null | grep -q "ana"; then
    SERVICE=$(docker service ls | grep ana | awk '{print $2}')
    REPLICAS=$(docker service ls | grep ana | awk '{print $4}')
    echo "✅ Servicio Swarm: $SERVICE"
    echo "   Réplicas: $REPLICAS"
    
    if [[ "$REPLICAS" == "0/"* ]]; then
        echo "   ⚠️  No hay réplicas corriendo!"
    fi
else
    echo "ℹ️  No es servicio Swarm (posiblemente docker-compose)"
fi
echo ""

# Verificar health endpoint
echo "Verificando health endpoint..."
HEALTH_RESPONSE=$(curl -sf -m 5 https://ana.checkin24hs.com/health 2>&1)
HEALTH_CODE=$?

if [ $HEALTH_CODE -eq 0 ]; then
    echo "✅ Ana responde en /health"
    echo "$HEALTH_RESPONSE" | head -3
else
    echo "❌ Ana NO responde en /health"
    echo "   Error: $HEALTH_RESPONSE"
fi
echo ""

# Verificar cron jobs
echo "Verificando cron jobs de Ana..."
ANA_CRON_COUNT=$(crontab -l 2>/dev/null | grep -c "ana.checkin24hs.com" || echo "0")

if [ "$ANA_CRON_COUNT" -gt 0 ]; then
    echo "✅ Cron jobs configurados ($ANA_CRON_COUNT jobs)"
    echo ""
    echo "Jobs encontrados:"
    crontab -l 2>/dev/null | grep "ana.checkin24hs.com" | while read line; do
        echo "   • $line"
    done
else
    echo "❌ NO hay cron jobs configurados"
    echo "   → Ver: ana/crontab.example"
fi
echo ""

# Verificar logs de Ana
if [ -f /var/log/ana-jobs.log ]; then
    echo "📋 Últimas líneas de /var/log/ana-jobs.log:"
    tail -5 /var/log/ana-jobs.log | sed 's/^/   /'
else
    echo "⚠️  Log /var/log/ana-jobs.log no existe"
fi
echo ""

# ===== 2. EMAIL MONITOR =====
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "┃ 2. EMAIL MONITOR (email-monitor/monitor.js)"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar cron
EMAIL_CRON_COUNT=$(crontab -l 2>/dev/null | grep -c "email-monitor" || echo "0")

if [ "$EMAIL_CRON_COUNT" -gt 0 ]; then
    echo "✅ Cron configurado ($EMAIL_CRON_COUNT entrada(s))"
    echo ""
    echo "Jobs encontrados:"
    crontab -l 2>/dev/null | grep "email-monitor" | while read line; do
        echo "   • $line"
    done
else
    echo "❌ NO hay cron job configurado"
    echo "   → Agregar: */10 * * * * cd /root/checkin24hs/email-monitor && node monitor.js >> /var/log/email-monitor.log 2>&1"
fi
echo ""

# Verificar directorio y archivos
if [ -d /root/checkin24hs/email-monitor ]; then
    echo "✅ Directorio email-monitor existe"
    
    if [ -f /root/checkin24hs/email-monitor/.env ]; then
        echo "✅ Archivo .env existe"
        
        # Verificar variables críticas (sin mostrar valores)
        echo ""
        echo "Variables de entorno:"
        for VAR in IMAP_USER IMAP_PASS WHATSAPP_API_URL WHATSAPP_API_KEY WHATSAPP_GROUP_ID SUPABASE_URL; do
            if grep -q "^${VAR}=" /root/checkin24hs/email-monitor/.env 2>/dev/null; then
                echo "   ✅ $VAR configurado"
            else
                echo "   ❌ $VAR NO configurado"
            fi
        done
    else
        echo "❌ Archivo .env NO existe"
        echo "   → Crear desde .env.example"
    fi
    
    if [ -f /root/checkin24hs/email-monitor/monitor.js ]; then
        echo "✅ Script monitor.js existe"
    else
        echo "❌ Script monitor.js NO existe"
    fi
else
    echo "❌ Directorio email-monitor NO existe"
fi
echo ""

# Verificar logs
if [ -f /var/log/email-monitor.log ]; then
    LOG_SIZE=$(ls -lh /var/log/email-monitor.log | awk '{print $5}')
    LOG_DATE=$(ls -l /var/log/email-monitor.log | awk '{print $6, $7, $8}')
    echo "📋 Log existe: $LOG_SIZE (última modificación: $LOG_DATE)"
    echo ""
    echo "Últimas 5 líneas:"
    tail -5 /var/log/email-monitor.log | sed 's/^/   /'
else
    echo "⚠️  Log /var/log/email-monitor.log no existe"
    echo "   → El cron job no se ha ejecutado o guarda logs en otro lugar"
fi
echo ""

# Test rápido (solo si node está disponible y el directorio existe)
if [ -d /root/checkin24hs/email-monitor ] && command -v node >/dev/null 2>&1; then
    echo "🧪 Test rápido (--dry-run)..."
    cd /root/checkin24hs/email-monitor
    timeout 10 node monitor.js --dry-run 2>&1 | head -10 | sed 's/^/   /'
    TEST_EXIT=$?
    
    if [ $TEST_EXIT -eq 0 ]; then
        echo "   ✅ Test exitoso"
    elif [ $TEST_EXIT -eq 124 ]; then
        echo "   ⏱️  Test timeout (normal si hay muchos emails)"
    else
        echo "   ❌ Test falló (exit code: $TEST_EXIT)"
    fi
else
    echo "ℹ️  Test rápido omitido (node o directorio no disponible)"
fi
echo ""

# ===== 3. NO STOP =====
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "┃ 3. NO STOP (sistema no identificado)"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "❓ Sistema 'No Stop' no encontrado en el código"
echo ""
echo "Posibles interpretaciones:"
echo "   1. Nombre informal para notificaciones continuas"
echo "   2. Servicio externo de monitoreo (UptimeRobot, etc.)"
echo "   3. Sistema no documentado"
echo ""
echo "📝 Acción requerida: Aclarar con usuario qué es 'No Stop'"
echo ""

# Buscar servicios relacionados
echo "Buscando servicios que puedan ser 'No Stop'..."
echo ""

# Verificar servicios Docker
echo "Servicios Docker activos:"
if command -v docker >/dev/null 2>&1; then
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep -v NAMES | while read line; do
        echo "   • $line"
    done
else
    echo "   ℹ️  Docker no disponible"
fi
echo ""

# Verificar cron jobs que corren frecuentemente (posibles "no stop")
echo "Cron jobs que corren cada <30 min (posibles 'no stop'):"
crontab -l 2>/dev/null | grep -E "^\*|^[0-9]" | grep -v "^#" | while read line; do
    # Extraer frecuencia
    FREQ=$(echo "$line" | awk '{print $1, $2}')
    if echo "$FREQ" | grep -qE "^\*/[1-9]|^\*/[12][0-9]"; then
        echo "   • $line"
    fi
done || echo "   (ninguno encontrado)"
echo ""

# ===== RESUMEN =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 RESUMEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Contador de problemas
ISSUES=0

# Ana
if ! docker ps | grep -q "ana" && ! docker service ls 2>/dev/null | grep -q "ana"; then
    echo "❌ Ana: Servicio NO corriendo"
    ((ISSUES++))
elif ! curl -sf -m 5 https://ana.checkin24hs.com/health >/dev/null 2>&1; then
    echo "⚠️  Ana: Servicio corriendo pero NO responde"
    ((ISSUES++))
elif [ "$ANA_CRON_COUNT" -eq 0 ]; then
    echo "⚠️  Ana: Cron jobs NO configurados"
    ((ISSUES++))
else
    echo "✅ Ana: OK"
fi

# Email Monitor
if [ "$EMAIL_CRON_COUNT" -eq 0 ]; then
    echo "❌ Email Monitor: Cron job NO configurado"
    ((ISSUES++))
elif [ ! -f /root/checkin24hs/email-monitor/.env ]; then
    echo "❌ Email Monitor: .env NO existe"
    ((ISSUES++))
elif [ ! -f /var/log/email-monitor.log ]; then
    echo "⚠️  Email Monitor: No hay logs (¿nunca se ejecutó?)"
    ((ISSUES++))
else
    echo "✅ Email Monitor: OK"
fi

# No Stop
echo "❓ No Stop: Sistema no identificado"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ISSUES -eq 0 ]; then
    echo "✅ No se encontraron problemas críticos"
else
    echo "⚠️  Se encontraron $ISSUES problema(s)"
    echo ""
    echo "📋 Próximos pasos:"
    echo "   1. Revisar detalles arriba"
    echo "   2. Ver DIAGNOSTICO_NOTIFICACIONES.md para soluciones"
    echo "   3. Ejecutar fixes específicos según el problema"
fi

echo ""
echo "📝 Para más información:"
echo "   cat /root/checkin24hs/DIAGNOSTICO_NOTIFICACIONES.md"
echo ""
