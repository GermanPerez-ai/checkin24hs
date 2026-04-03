#!/bin/bash

echo "=========================================="
echo "🔧 SOLUCIÓN COMPLETA ERROR 504 WEBMAIL"
echo "=========================================="
echo ""

cd /root/checkin24hs 2>/dev/null || cd ~/checkin24hs 2>/dev/null || echo "⚠️  No se encontró directorio checkin24hs"

# 1. DIAGNÓSTICO INICIAL
echo "=========================================="
echo "1️⃣ DIAGNÓSTICO INICIAL"
echo "=========================================="
echo ""

# Buscar servicio webmail
WEBMAIL_SERVICE=$(docker service ls --filter "name=webmail" --format "{{.Name}}" | head -1)

if [ -z "$WEBMAIL_SERVICE" ]; then
    echo "⚠️  No se encontró servicio con nombre 'webmail'"
    echo "   Buscando servicios relacionados..."
    docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}" | grep -iE "mail|roundcube|sogo|rainloop"
    echo ""
    echo "❌ Por favor, identifica el nombre correcto del servicio y ejecuta:"
    echo "   docker service update --force [NOMBRE_DEL_SERVICIO]"
    exit 1
fi

echo "✅ Servicio encontrado: $WEBMAIL_SERVICE"
echo ""

# Verificar estado del servicio
echo "📊 Estado del servicio:"
docker service ps "$WEBMAIL_SERVICE" --no-trunc --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}" | head -5
echo ""

# Verificar contenedores
echo "📦 Contenedores de webmail:"
docker ps --filter "name=webmail" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
echo ""

# 2. VERIFICAR RED DE TRAEFIK
echo "=========================================="
echo "2️⃣ VERIFICANDO RED DE TRAEFIK"
echo "=========================================="
echo ""

EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -z "$EASYPANEL_NET" ]; then
    echo "❌ ERROR: No se encontró la red easypanel"
    echo "   Buscando redes disponibles..."
    docker network ls | grep -E "traefik|easypanel|web"
    exit 1
fi

echo "✅ Red EasyPanel encontrada: $EASYPANEL_NET"
echo ""

# Verificar si webmail está en la red
IS_IN_NETWORK=$(docker network inspect $EASYPANEL_NET --format='{{range .Containers}}{{.Name}} {{end}}' 2>&1 | grep -o webmail | head -1)

if [ -z "$IS_IN_NETWORK" ]; then
    echo "⚠️  Webmail NO está en la red de Traefik"
    echo "   Agregando webmail a la red EasyPanel..."
    docker service update --network-add $EASYPANEL_NET "$WEBMAIL_SERVICE"
    echo "✅ Webmail agregado a la red"
    sleep 15
else
    echo "✅ Webmail ya está en la red EasyPanel"
fi
echo ""

# 3. VERIFICAR Y CORREGIR PUERTO
echo "=========================================="
echo "3️⃣ VERIFICANDO PUERTO INTERNO"
echo "=========================================="
echo ""

CURRENT_PORT=$(docker service inspect "$WEBMAIL_SERVICE" --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep "loadbalancer.server.port" | cut -d'=' -f2 | head -1)

echo "Puerto actual configurado: ${CURRENT_PORT:-no configurado}"

if [ "$CURRENT_PORT" != "80" ]; then
    echo "⚠️  Puerto incorrecto. Corrigiendo a 80..."
    docker service update \
      --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
      "$WEBMAIL_SERVICE"
    echo "✅ Puerto configurado a 80"
    sleep 10
else
    echo "✅ Puerto ya está configurado correctamente (80)"
fi
echo ""

# 4. VERIFICAR Y ACTUALIZAR ETIQUETAS DE TRAEFIK
echo "=========================================="
echo "4️⃣ CONFIGURANDO ETIQUETAS DE TRAEFIK"
echo "=========================================="
echo ""

echo "Actualizando etiquetas de Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.routers.webmail.service=webmail" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  --label-add "traefik.http.routers.webmail-secure.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail-secure.entrypoints=websecure" \
  --label-add "traefik.http.routers.webmail-secure.service=webmail" \
  --label-add "traefik.http.routers.webmail-secure.tls=true" \
  --label-add "traefik.http.routers.webmail-secure.tls.certresolver=letsencrypt" \
  "$WEBMAIL_SERVICE"

echo "✅ Etiquetas actualizadas"
echo ""

# 5. VERIFICAR LOGS
echo "=========================================="
echo "5️⃣ VERIFICANDO LOGS DEL SERVICIO"
echo "=========================================="
echo ""

echo "📋 Últimas 20 líneas de logs:"
docker service logs "$WEBMAIL_SERVICE" --tail 20 2>&1 | tail -20
echo ""

# 6. PROBAR ACCESO INTERNO
echo "=========================================="
echo "6️⃣ PROBANDO ACCESO INTERNO"
echo "=========================================="
echo ""

WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "📦 Contenedor: $WEBMAIL_CONTAINER"
    echo ""
    echo "🔍 Probando acceso en puerto 80..."
    
    # Probar con curl si está disponible
    if docker exec "$WEBMAIL_CONTAINER" which curl >/dev/null 2>&1; then
        HTTP_CODE=$(docker exec "$WEBMAIL_CONTAINER" curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:80 2>&1)
        echo "   HTTP Status Code: $HTTP_CODE"
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
            echo "   ✅ Webmail responde correctamente internamente"
        else
            echo "   ⚠️  Webmail responde con código: $HTTP_CODE"
        fi
    else
        # Probar con wget si curl no está disponible
        if docker exec "$WEBMAIL_CONTAINER" which wget >/dev/null 2>&1; then
            RESPONSE=$(docker exec "$WEBMAIL_CONTAINER" wget -q -O- --timeout=5 http://localhost:80 2>&1 | head -1)
            if [ -n "$RESPONSE" ]; then
                echo "   ✅ Webmail responde correctamente internamente"
            else
                echo "   ⚠️  Webmail no responde o está iniciando..."
            fi
        else
            echo "   ⚠️  No se pudo probar (curl/wget no disponibles)"
        fi
    fi
else
    echo "⚠️  No se encontró contenedor para probar"
fi
echo ""

# 7. ESPERAR Y VERIFICAR ESTADO FINAL
echo "=========================================="
echo "7️⃣ ESPERANDO APLICACIÓN DE CAMBIOS"
echo "=========================================="
echo ""

echo "⏳ Esperando 30 segundos para que se apliquen los cambios..."
sleep 30
echo ""

# 8. VERIFICAR CONFIGURACIÓN FINAL
echo "=========================================="
echo "8️⃣ CONFIGURACIÓN FINAL"
echo "=========================================="
echo ""

echo "📋 Etiquetas de Traefik configuradas:"
docker service inspect "$WEBMAIL_SERVICE" --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik | sort
echo ""

echo "🌐 Redes del servicio:"
docker service inspect "$WEBMAIL_SERVICE" --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>&1
echo ""

# 9. PROBAR ACCESO EXTERNO
echo "=========================================="
echo "9️⃣ PROBANDO ACCESO EXTERNO"
echo "=========================================="
echo ""

echo "🌐 Probando https://webmail.checkin24hs.com/..."
EXTERNAL_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" --max-time 10 https://webmail.checkin24hs.com/ 2>&1)
echo "   HTTP Status: $EXTERNAL_STATUS"

if [ "$EXTERNAL_STATUS" = "504" ]; then
    echo "   ❌ Gateway Timeout - El servicio aún no responde"
    echo "   💡 Espera 1-2 minutos más y prueba nuevamente"
elif [ "$EXTERNAL_STATUS" = "502" ]; then
    echo "   ❌ Bad Gateway - Traefik no puede conectarse al servicio"
    echo "   💡 Verifica que el servicio esté corriendo"
elif [ "$EXTERNAL_STATUS" = "503" ]; then
    echo "   ⚠️  Service Unavailable - El servicio puede estar reiniciando"
    echo "   💡 Espera 30 segundos más"
elif [ "$EXTERNAL_STATUS" = "200" ] || [ "$EXTERNAL_STATUS" = "301" ] || [ "$EXTERNAL_STATUS" = "302" ]; then
    echo "   ✅ ¡Webmail funcionando correctamente!"
else
    echo "   ⚠️  Estado: $EXTERNAL_STATUS"
fi
echo ""

# 10. RESUMEN Y RECOMENDACIONES
echo "=========================================="
echo "✅ RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""

echo "Cambios realizados:"
echo "  ✅ Webmail agregado/verificado en la red de Traefik"
echo "  ✅ Puerto configurado a 80"
echo "  ✅ Etiquetas de Traefik actualizadas"
echo ""

if [ "$EXTERNAL_STATUS" != "200" ] && [ "$EXTERNAL_STATUS" != "301" ] && [ "$EXTERNAL_STATUS" != "302" ]; then
    echo "⚠️  El webmail aún no responde correctamente"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Espera 1-2 minutos para que los cambios se apliquen completamente"
    echo "  2. Verifica en EasyPanel que el servicio esté 🟢 Verde (corriendo)"
    echo "  3. Revisa los logs del servicio en EasyPanel"
    echo "  4. Si el problema persiste, ejecuta:"
    echo "     docker service update --force $WEBMAIL_SERVICE"
    echo ""
    echo "Para ver logs en tiempo real:"
    echo "  docker service logs -f $WEBMAIL_SERVICE"
else
    echo "✅ ¡Problema resuelto! El webmail debería estar funcionando."
fi

echo ""
echo "=========================================="
echo ""
