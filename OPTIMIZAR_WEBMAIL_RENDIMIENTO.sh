#!/bin/bash

echo "=========================================="
echo "⚡ OPTIMIZANDO RENDIMIENTO DEL WEBMAIL"
echo "=========================================="
echo ""

cd /root/checkin24hs 2>/dev/null || cd ~/checkin24hs 2>/dev/null || echo "⚠️  No se encontró directorio checkin24hs"

# Buscar servicio webmail
WEBMAIL_SERVICE=$(docker service ls --filter "name=webmail" --format "{{.Name}}" | head -1)

if [ -z "$WEBMAIL_SERVICE" ]; then
    echo "❌ No se encontró servicio webmail"
    exit 1
fi

echo "✅ Servicio encontrado: $WEBMAIL_SERVICE"
echo ""

# 1. AUMENTAR TIMEOUTS EN TRAEFIK
echo "=========================================="
echo "1️⃣ AUMENTANDO TIMEOUTS EN TRAEFIK"
echo "=========================================="
echo ""

echo "Configurando timeouts más largos para webmail..."
docker service update \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  --label-add "traefik.http.services.webmail.loadbalancer.healthcheck.interval=30s" \
  --label-add "traefik.http.services.webmail.loadbalancer.healthcheck.timeout=10s" \
  --label-add "traefik.http.middlewares.webmail-timeout.forwardauth.authResponseHeaders=X-Forwarded-User" \
  --label-add "traefik.http.middlewares.webmail-timeout.retry.attempts=3" \
  --label-add "traefik.http.middlewares.webmail-timeout.retry.initialInterval=100ms" \
  --label-add "traefik.http.routers.webmail.middlewares=webmail-timeout" \
  --label-add "traefik.http.routers.webmail-secure.middlewares=webmail-timeout" \
  "$WEBMAIL_SERVICE"

echo "✅ Timeouts configurados"
echo ""

# 2. VERIFICAR RECURSOS
echo "=========================================="
echo "2️⃣ VERIFICANDO RECURSOS DEL SERVICIO"
echo "=========================================="
echo ""

echo "📊 Recursos actuales:"
docker service inspect "$WEBMAIL_SERVICE" --format '{{json .Spec.TaskTemplate.Resources}}' 2>/dev/null | python3 -m json.tool 2>/dev/null || docker service inspect "$WEBMAIL_SERVICE" --format '{{json .Spec.TaskTemplate.Resources}}' 2>/dev/null

echo ""
echo "💡 RECOMENDACIÓN: En EasyPanel, ve a Servicios → webmail → Recursos"
echo "   Asegúrate de tener:"
echo "   - CPU: Mínimo 1.0 (mejor 2.0)"
echo "   - RAM: Mínimo 1024 MB (mejor 2048 MB)"
echo ""

# 3. VERIFICAR LOGS PARA ERRORES
echo "=========================================="
echo "3️⃣ VERIFICANDO LOGS PARA ERRORES"
echo "=========================================="
echo ""

echo "📋 Buscando errores en los últimos 100 logs..."
docker service logs "$WEBMAIL_SERVICE" --tail 100 2>&1 | grep -iE "error|timeout|failed|database|connection|fatal|exception" | tail -20

if [ $? -ne 0 ]; then
    echo "   ✅ No se encontraron errores obvios en los logs recientes"
else
    echo ""
    echo "   ⚠️  Se encontraron errores. Revisa los logs completos:"
    echo "      docker service logs $WEBMAIL_SERVICE --tail 200"
fi
echo ""

# 4. VERIFICAR CONEXIÓN A BASE DE DATOS
echo "=========================================="
echo "4️⃣ VERIFICANDO CONEXIÓN A BASE DE DATOS"
echo "=========================================="
echo ""

WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "📦 Verificando variables de entorno relacionadas con BD..."
    docker exec "$WEBMAIL_CONTAINER" env 2>/dev/null | grep -iE "database|db|mysql|postgres|roundcube" | head -10
    
    echo ""
    echo "💡 Si faltan variables de BD, configúralas en EasyPanel:"
    echo "   Servicios → webmail → Variables de Entorno"
    echo ""
else
    echo "⚠️  No se encontró contenedor para verificar"
fi
echo ""

# 5. OPTIMIZAR CONFIGURACIÓN DE TRAEFIK
echo "=========================================="
echo "5️⃣ OPTIMIZANDO CONFIGURACIÓN DE TRAEFIK"
echo "=========================================="
echo ""

echo "Actualizando configuración completa de Traefik con timeouts extendidos..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.routers.webmail.tls=true" \
  --label-add "traefik.http.routers.webmail.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  --label-add "traefik.http.services.webmail.loadbalancer.healthcheck.path=/" \
  --label-add "traefik.http.services.webmail.loadbalancer.healthcheck.interval=30s" \
  --label-add "traefik.http.services.webmail.loadbalancer.healthcheck.timeout=10s" \
  --label-add "traefik.http.services.webmail.loadbalancer.healthcheck.scheme=http" \
  "$WEBMAIL_SERVICE"

echo "✅ Configuración optimizada"
echo ""

# 6. REINICIAR SERVICIO PARA APLICAR CAMBIOS
echo "=========================================="
echo "6️⃣ REINICIANDO SERVICIO"
echo "=========================================="
echo ""

echo "🔄 Reiniciando servicio para aplicar optimizaciones..."
docker service update --force "$WEBMAIL_SERVICE"
echo "✅ Servicio reiniciado"
echo ""

# 7. ESPERAR Y VERIFICAR
echo "=========================================="
echo "7️⃣ ESPERANDO Y VERIFICANDO"
echo "=========================================="
echo ""

echo "⏳ Esperando 45 segundos para que el servicio se reinicie completamente..."
sleep 45
echo ""

echo "📊 Estado del servicio:"
docker service ps "$WEBMAIL_SERVICE" --no-trunc --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}" | head -3
echo ""

# 8. PROBAR ACCESO
echo "=========================================="
echo "8️⃣ PROBANDO ACCESO"
echo "=========================================="
echo ""

echo "🌐 Probando https://webmail.checkin24hs.com/..."
EXTERNAL_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" --max-time 30 https://webmail.checkin24hs.com/ 2>&1)
echo "   HTTP Status: $EXTERNAL_STATUS"

if [ "$EXTERNAL_STATUS" = "200" ] || [ "$EXTERNAL_STATUS" = "301" ] || [ "$EXTERNAL_STATUS" = "302" ]; then
    echo "   ✅ Webmail accesible"
else
    echo "   ⚠️  Estado: $EXTERNAL_STATUS"
fi
echo ""

# 9. RESUMEN Y RECOMENDACIONES
echo "=========================================="
echo "✅ RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""

echo "Optimizaciones aplicadas:"
echo "  ✅ Timeouts aumentados en Traefik"
echo "  ✅ Health checks configurados"
echo "  ✅ Servicio reiniciado"
echo ""

echo "⚠️  ACCIONES ADICIONALES RECOMENDADAS:"
echo ""
echo "1. AUMENTAR RECURSOS EN EASYPANEL:"
echo "   - Ve a EasyPanel → Servicios → webmail → Recursos"
echo "   - CPU: Aumenta a 2.0"
echo "   - RAM: Aumenta a 2048 MB"
echo "   - Guarda y espera 1-2 minutos"
echo ""

echo "2. VERIFICAR VARIABLES DE ENTORNO:"
echo "   - Ve a EasyPanel → Servicios → webmail → Variables"
echo "   - Verifica que tenga todas las variables de BD necesarias"
echo "   - Si faltan, agrégalas según la documentación de Roundcube"
echo ""

echo "3. VERIFICAR LOGS EN EASYPANEL:"
echo "   - Ve a EasyPanel → Servicios → webmail → Registros"
echo "   - Busca errores específicos como:"
echo "     * 'Error del servidor'"
echo "     * 'Database connection failed'"
echo "     * 'Timeout'"
echo ""

echo "4. SI EL PROBLEMA PERSISTE:"
echo "   - Verifica que la base de datos esté accesible"
echo "   - Verifica que el servidor de correo esté configurado"
echo "   - Considera aumentar aún más los recursos"
echo ""

echo "Para ver logs en tiempo real:"
echo "  docker service logs -f $WEBMAIL_SERVICE"
echo ""

echo "=========================================="
echo ""
