#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICACIÓN COMPLETA DE WEBMAIL"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

# 1. Verificar que el servicio está corriendo
echo "1️⃣ Estado del servicio:"
echo "----------------------------------------"
docker service ps "$SERVICE_NAME" --no-trunc --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}" | head -5
echo ""

# 2. Verificar contenedor
echo "2️⃣ Contenedor activo:"
echo "----------------------------------------"
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}\t{{.Names}}\t{{.Status}}" | head -1)
if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "✅ $WEBMAIL_CONTAINER"
    CONTAINER_ID=$(echo "$WEBMAIL_CONTAINER" | awk '{print $1}')
    
    # Probar acceso interno
    echo ""
    echo "   Probando acceso interno al contenedor:"
    INTERNAL_HTTP=$(docker exec "$CONTAINER_ID" curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null || echo "000")
    if [ "$INTERNAL_HTTP" = "200" ]; then
        echo "   ✅ HTTP interno: $INTERNAL_HTTP"
    else
        echo "   ❌ HTTP interno: $INTERNAL_HTTP"
    fi
else
    echo "❌ No se encontró contenedor activo"
fi
echo ""

# 3. Verificar labels de Traefik
echo "3️⃣ Labels de Traefik:"
echo "----------------------------------------"
TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>/dev/null | grep -i traefik)

if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ No se encontraron labels de Traefik"
    echo "   Ejecuta: ./SOLUCIONAR_WEBMAIL_504_COMPLETO.sh"
else
    echo "$TRAEFIK_LABELS"
    echo ""
    echo "✅ Labels configuradas"
fi
echo ""

# 4. Verificar red de Traefik
echo "4️⃣ Red de Traefik:"
echo "----------------------------------------"
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -n "$EASYPANEL_NET" ]; then
    echo "✅ Red de EasyPanel: $EASYPANEL_NET"
    
    # Verificar si el servicio está en la red
    SERVICE_NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range $net := .Spec.TaskTemplate.Networks}}{{printf "%s\n" $net.Target}}{{end}}' 2>/dev/null)
    if echo "$SERVICE_NETWORKS" | grep -q "$EASYPANEL_NET"; then
        echo "✅ Servicio está en la red de Traefik"
    else
        echo "❌ Servicio NO está en la red de Traefik"
        echo "   Ejecuta: docker service update --network-add $EASYPANEL_NET $SERVICE_NAME"
    fi
else
    echo "❌ No se encontró la red de EasyPanel"
fi
echo ""

# 5. Verificar IP del servicio
echo "5️⃣ IP del servicio:"
echo "----------------------------------------"
SERVICE_IP=$(docker service inspect "$SERVICE_NAME" --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server"}}{{$v}}{{end}}{{end}}' 2>/dev/null | cut -d: -f1)

if [ -n "$SERVICE_IP" ]; then
    echo "✅ IP configurada en Traefik: $SERVICE_IP"
    
    # Verificar que el contenedor tenga esa IP
    if [ -n "$CONTAINER_ID" ]; then
        CONTAINER_IP=$(docker inspect "$CONTAINER_ID" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
        echo "   IP del contenedor: $CONTAINER_IP"
        
        if [ "$SERVICE_IP" = "$CONTAINER_IP" ]; then
            echo "   ✅ IPs coinciden"
        else
            echo "   ⚠️  IPs no coinciden - esto puede causar problemas"
        fi
    fi
else
    echo "⚠️  No se encontró IP configurada en Traefik"
fi
echo ""

# 6. Verificar logs de Traefik
echo "6️⃣ Logs de Traefik (últimas 30 líneas relacionadas con webmail):"
echo "----------------------------------------"
docker service logs traefik --tail 500 2>&1 | grep -iE "webmail|$DOMAIN" | tail -30 || echo "   No se encontraron logs recientes"
echo ""

# 7. Verificar errores en logs del servicio
echo "7️⃣ Logs del servicio webmail (últimas 20 líneas):"
echo "----------------------------------------"
docker service logs "$SERVICE_NAME" --tail 50 2>&1 | tail -20
echo ""

# 8. Verificar acceso desde el servidor (puede fallar si no hay acceso externo)
echo "8️⃣ Probando acceso desde el servidor:"
echo "----------------------------------------"
echo "   Nota: Esto puede fallar si el servidor no tiene acceso externo"
echo ""
echo "🌐 HTTP: http://$DOMAIN/"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$DOMAIN/" 2>&1 || echo "000")
echo "   HTTP Status: $HTTP_STATUS"

echo "🌐 HTTPS: https://$DOMAIN/"
HTTPS_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" --max-time 5 "https://$DOMAIN/" 2>&1 || echo "000")
echo "   HTTPS Status: $HTTPS_STATUS"
echo ""

# 9. Verificar DNS
echo "9️⃣ Verificación DNS:"
echo "----------------------------------------"
DOMAIN_IP=$(dig +short "$DOMAIN" 2>/dev/null | head -1)
if [ -n "$DOMAIN_IP" ]; then
    echo "✅ DNS resuelve: $DOMAIN -> $DOMAIN_IP"
else
    echo "❌ No se pudo resolver DNS para $DOMAIN"
fi
echo ""

# 10. Verificar configuración de Traefik (routers y services)
echo "🔟 Verificando configuración de Traefik:"
echo "----------------------------------------"
if [ -n "$TRAEFIK_LABELS" ]; then
    echo "   Routers configurados:"
    echo "$TRAEFIK_LABELS" | grep "routers" | sed 's/^/   /'
    echo ""
    echo "   Services configurados:"
    echo "$TRAEFIK_LABELS" | grep "services" | sed 's/^/   /'
else
    echo "   ⚠️  No se pudieron obtener las labels"
fi
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""

if [ "$INTERNAL_HTTP" = "200" ]; then
    echo "✅ El contenedor responde correctamente internamente"
else
    echo "❌ El contenedor NO responde internamente"
    echo "   Revisa los logs del servicio"
fi

if [ -n "$TRAEFIK_LABELS" ]; then
    echo "✅ Labels de Traefik configuradas"
else
    echo "❌ Faltan labels de Traefik"
    echo "   Ejecuta: ./SOLUCIONAR_WEBMAIL_504_COMPLETO.sh"
fi

if [ "$HTTP_STATUS" = "000" ] && [ "$HTTPS_STATUS" = "000" ]; then
    echo ""
    echo "⚠️  No se pudo conectar desde el servidor"
    echo "   Esto puede ser normal si el servidor no tiene acceso externo"
    echo "   Prueba acceder desde tu navegador: https://$DOMAIN/"
    echo ""
    echo "   Si desde el navegador también falla, verifica:"
    echo "   1. Que Traefik esté corriendo: docker service ps traefik"
    echo "   2. Los logs de Traefik para errores"
    echo "   3. Que el DNS esté apuntando correctamente"
fi

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTPS_STATUS" = "200" ]; then
    echo ""
    echo "✅ El servicio está accesible externamente"
fi

echo ""
