#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNOSTICANDO ERROR 504 EN WEBMAIL"
echo "=========================================="
echo ""

# 1. Verificar servicio de webmail
echo "1️⃣ Servicios relacionados con webmail:"
echo "----------------------------------------"
docker service ls --filter "name=webmail" --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"
echo ""

# 2. Verificar contenedores de webmail
echo "2️⃣ Contenedores de webmail:"
echo "----------------------------------------"
docker ps --filter "name=webmail" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
echo ""

# 3. Verificar configuración de Traefik para webmail
echo "3️⃣ Configuración de Traefik para webmail:"
echo "----------------------------------------"
WEBMAIL_SERVICE=$(docker service ls --filter "name=webmail" --format "{{.Name}}" | head -1)

if [ -z "$WEBMAIL_SERVICE" ]; then
    echo "⚠️  No se encontró servicio con nombre 'webmail'"
    echo "   Buscando servicios que puedan ser webmail..."
    docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}" | grep -iE "mail|roundcube|sogo|rainloop"
else
    echo "✅ Servicio encontrado: $WEBMAIL_SERVICE"
    echo ""
    TRAEFIK_LABELS=$(docker service inspect "$WEBMAIL_SERVICE" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep -E "traefik")
    
    if [ -z "$TRAEFIK_LABELS" ]; then
        echo "❌ No se encontraron labels de Traefik"
    else
        echo "✅ Labels de Traefik encontradas:"
        echo "$TRAEFIK_LABELS" | head -10
    fi
fi
echo ""

# 4. Verificar logs del servicio
echo "4️⃣ Logs recientes del servicio webmail:"
echo "----------------------------------------"
if [ -n "$WEBMAIL_SERVICE" ]; then
    docker service logs "$WEBMAIL_SERVICE" --tail 30 2>&1 | tail -30
else
    WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
    if [ -n "$WEBMAIL_CONTAINER" ]; then
        echo "✅ Contenedor encontrado: $WEBMAIL_CONTAINER"
        docker logs "$WEBMAIL_CONTAINER" --tail 30 2>&1 | tail -30
    else
        echo "⚠️  No se encontró contenedor de webmail"
    fi
fi
echo ""

# 5. Verificar estado del servicio
echo "5️⃣ Estado del servicio:"
echo "----------------------------------------"
if [ -n "$WEBMAIL_SERVICE" ]; then
    docker service ps "$WEBMAIL_SERVICE" --no-trunc --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}" | head -5
else
    echo "⚠️  No se puede verificar estado sin servicio"
fi
echo ""

# 6. Verificar puerto interno
echo "6️⃣ Verificando puerto interno del servicio:"
echo "----------------------------------------"
if [ -n "$WEBMAIL_SERVICE" ]; then
    SERVICE_PORTS=$(docker service inspect "$WEBMAIL_SERVICE" --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{"\n"}}{{end}}' 2>/dev/null)
    if [ -n "$SERVICE_PORTS" ]; then
        echo "✅ Puertos configurados:"
        echo "$SERVICE_PORTS"
    else
        echo "⚠️  No se encontraron puertos configurados"
    fi
else
    WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
    if [ -n "$WEBMAIL_CONTAINER" ]; then
        echo "📊 Puertos del contenedor:"
        docker port "$WEBMAIL_CONTAINER" 2>/dev/null || echo "   ⚠️  No se pudieron obtener puertos"
    fi
fi
echo ""

# 7. Probar acceso interno
echo "7️⃣ Probando acceso interno al servicio:"
echo "----------------------------------------"
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "📦 Contenedor: $WEBMAIL_CONTAINER"
    echo ""
    echo "🔍 Buscando puerto del servicio web..."
    # Intentar puertos comunes de webmail
    for PORT in 80 8080 443 8443 9000; do
        echo -n "   Probando puerto $PORT: "
        docker exec "$WEBMAIL_CONTAINER" sh -c "curl -s -o /dev/null -w '%{http_code}' http://localhost:$PORT 2>&1" 2>/dev/null | head -1
    done
else
    echo "⚠️  No se encontró contenedor para probar acceso interno"
fi
echo ""

# 8. Verificar acceso externo
echo "8️⃣ Verificando acceso externo:"
echo "----------------------------------------"
echo "🌐 https://webmail.checkin24hs.com/:"
EXTERNAL_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" https://webmail.checkin24hs.com/ 2>&1)
echo "   HTTP Status: $EXTERNAL_STATUS"

if [ "$EXTERNAL_STATUS" = "504" ]; then
    echo "   ❌ Gateway Timeout - El servicio backend no está respondiendo"
elif [ "$EXTERNAL_STATUS" = "502" ]; then
    echo "   ❌ Bad Gateway - Traefik no puede conectarse al servicio"
elif [ "$EXTERNAL_STATUS" = "503" ]; then
    echo "   ❌ Service Unavailable - El servicio puede estar reiniciando"
elif [ "$EXTERNAL_STATUS" = "200" ]; then
    echo "   ✅ Servicio funcionando correctamente"
else
    echo "   ⚠️  Estado inesperado: $EXTERNAL_STATUS"
fi
echo ""

# 9. Verificar configuración de Traefik
echo "9️⃣ Verificando configuración de Traefik para webmail:"
echo "----------------------------------------"
if [ -n "$WEBMAIL_SERVICE" ]; then
    TRAEFIK_RULE=$(docker service inspect "$WEBMAIL_SERVICE" --format '{{range $key, $value := .Spec.Labels}}{{if eq $key "traefik.http.routers.webmail.rule"}}{{$value}}{{end}}{{end}}' 2>/dev/null)
    TRAEFIK_PORT=$(docker service inspect "$WEBMAIL_SERVICE" --format '{{range $key, $value := .Spec.Labels}}{{if eq $key "traefik.http.services.webmail.loadbalancer.server.port"}}{{$value}}{{end}}{{end}}' 2>/dev/null)
    
    if [ -n "$TRAEFIK_RULE" ]; then
        echo "✅ Regla de Traefik: $TRAEFIK_RULE"
    else
        echo "❌ No se encontró regla de Traefik"
    fi
    
    if [ -n "$TRAEFIK_PORT" ]; then
        echo "✅ Puerto de Traefik: $TRAEFIK_PORT"
    else
        echo "❌ No se encontró puerto de Traefik"
    fi
else
    echo "⚠️  No se puede verificar sin servicio"
fi
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""
if [ "$EXTERNAL_STATUS" = "504" ]; then
    echo "❌ Error 504 Gateway Timeout detectado"
    echo ""
    echo "Posibles causas:"
    echo "  1. El servicio webmail no está corriendo"
    echo "  2. El servicio está reiniciando"
    echo "  3. El puerto configurado en Traefik no coincide con el del servicio"
    echo "  4. El servicio está respondiendo muy lento (timeout)"
    echo ""
    echo "Soluciones:"
    echo "  1. Verificar que el servicio esté corriendo en EasyPanel"
    echo "  2. Verificar los logs del servicio para ver errores"
    echo "  3. Verificar que el puerto en Traefik sea correcto"
    echo "  4. Reiniciar el servicio si es necesario"
fi
echo ""
