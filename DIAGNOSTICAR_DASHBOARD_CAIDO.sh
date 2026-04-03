#!/bin/bash
# Diagnóstico completo para identificar por qué el dashboard no está accesible

echo "=== DIAGNÓSTICO: DASHBOARD NO ACCESIBLE ==="
echo ""

DASHBOARD_DOMAIN="dashboard.checkin24hs.com"

echo "1. Verificando servicios de dashboard..."
DASHBOARD_SERVICES=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | wc -l)
if [ "$DASHBOARD_SERVICES" -gt 0 ]; then
    echo "✅ $DASHBOARD_SERVICES contenedor(es) de dashboard corriendo:"
    docker ps --filter "name=checkin24hs_dashboard" --format "  - {{.Names}} ({{.Status}})"
else
    echo "❌ NO hay contenedores de dashboard corriendo"
    echo "   Ejecuta: docker ps -a | grep dashboard"
fi

echo ""
echo "2. Verificando Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Traefik corriendo: $TRAEFIK_CONTAINER"
    echo "   Estado:"
    docker ps --filter "name=traefik" --format "  {{.Status}}"
else
    echo "❌ Traefik NO está corriendo"
    echo "   Buscando servicios de Traefik..."
    docker ps -a | grep -i traefik
fi

echo ""
echo "3. Verificando labels de Traefik en servicios de dashboard..."
if docker service inspect checkin24hs_dashboard &>/dev/null; then
    echo "✅ Servicio checkin24hs_dashboard existe"
    echo "   Labels de Traefik:"
    docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -10
else
    echo "⚠️ Servicio checkin24hs_dashboard no encontrado (puede ser un contenedor normal)"
fi

echo ""
echo "4. Verificando DNS..."
RESOLVED_IP=$(dig +short $DASHBOARD_DOMAIN 2>/dev/null | head -n 1)
HOST_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -z "$HOST_IP" ]; then
    HOST_IP=$(hostname -I | awk '{print $1}')
fi

if [ -n "$RESOLVED_IP" ]; then
    echo "✅ DNS resuelve $DASHBOARD_DOMAIN -> $RESOLVED_IP"
    if [ "$RESOLVED_IP" = "$HOST_IP" ]; then
        echo "✅ DNS apunta correctamente al servidor ($HOST_IP)"
    else
        echo "⚠️ DNS apunta a $RESOLVED_IP pero el servidor es $HOST_IP"
        echo "   Necesitas actualizar el DNS para que apunte a $HOST_IP"
    fi
else
    echo "❌ DNS NO resuelve $DASHBOARD_DOMAIN"
    echo "   Necesitas configurar el DNS para que apunte a $HOST_IP"
fi

echo ""
echo "5. Verificando puertos abiertos..."
if command -v netstat >/dev/null 2>&1; then
    echo "Puertos 80 y 443 en escucha:"
    netstat -tuln | grep -E ":80 |:443 " || echo "  No se encontraron puertos 80/443 abiertos"
elif command -v ss >/dev/null 2>&1; then
    echo "Puertos 80 y 443 en escucha:"
    ss -tuln | grep -E ":80 |:443 " || echo "  No se encontraron puertos 80/443 abiertos"
else
    echo "⚠️ No se puede verificar puertos (netstat/ss no disponibles)"
fi

echo ""
echo "6. Verificando acceso local al dashboard..."
LOCAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost/dashboard.html 2>/dev/null)
if [ "$LOCAL_TEST" = "200" ]; then
    echo "✅ Dashboard responde localmente (HTTP 200)"
elif [ "$LOCAL_TEST" = "000" ]; then
    echo "⚠️ Dashboard NO responde localmente"
    echo "   Verificando contenedores..."
    docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -n 1 | xargs -I {} docker exec {} curl -s -o /dev/null -w "%{http_code}" http://localhost/dashboard.html 2>/dev/null || echo "  No se pudo verificar"
else
    echo "⚠️ Dashboard responde con HTTP $LOCAL_TEST localmente"
fi

echo ""
echo "7. Verificando acceso HTTPS desde el servidor..."
HTTPS_TEST=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -k https://$DASHBOARD_DOMAIN 2>/dev/null)
if [ "$HTTPS_TEST" = "200" ]; then
    echo "✅ HTTPS funciona desde el servidor (HTTP 200)"
elif [ "$HTTPS_TEST" = "000" ]; then
    echo "❌ HTTPS NO funciona desde el servidor"
    echo "   Posibles causas:"
    echo "   - Traefik no está configurado para dashboard.checkin24hs.com"
    echo "   - Certificado SSL no está configurado"
    echo "   - Firewall bloqueando puerto 443"
else
    echo "⚠️ HTTPS responde con HTTP $HTTPS_TEST desde el servidor"
fi

echo ""
echo "8. Verificando logs de Traefik (últimas 20 líneas)..."
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Logs de Traefik:"
    docker logs $TRAEFIK_CONTAINER --tail 20 2>&1 | grep -iE "dashboard|error|404|502|503" || echo "  No se encontraron errores relacionados con dashboard"
else
    echo "⚠️ No se puede verificar logs (Traefik no encontrado)"
fi

echo ""
echo "=== RESUMEN Y SOLUCIONES ==="
echo ""
echo "Si el dashboard NO está accesible, verifica:"
echo ""
echo "1. DNS:"
echo "   - El dominio dashboard.checkin24hs.com debe apuntar a: $HOST_IP"
echo "   - Verifica en tu proveedor de DNS (Cloudflare, Namecheap, etc.)"
echo ""
echo "2. Traefik:"
echo "   - Debe estar corriendo: docker ps | grep traefik"
echo "   - Debe tener labels configurados para dashboard.checkin24hs.com"
echo ""
echo "3. Servicio de Dashboard:"
echo "   - Debe estar corriendo: docker ps | grep dashboard"
echo "   - Debe estar en la misma red que Traefik"
echo ""
echo "4. Certificado SSL:"
echo "   - Debe estar configurado Let's Encrypt en Traefik"
echo "   - Verifica con: docker logs traefik | grep -i acme"
echo ""
echo "5. Firewall:"
echo "   - Puertos 80 y 443 deben estar abiertos"
echo "   - Verifica con: ufw status o iptables -L"
echo ""






