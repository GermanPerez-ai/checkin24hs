#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNÓSTICO PROFUNDO DEL ERROR 404"
echo "=========================================="
echo ""

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

# 1. Verificar que el servicio responde directamente
echo "=== 1. PRUEBA DE ACCESO DIRECTO ==="
CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
echo "IP del contenedor: $CONTAINER_IP"
echo ""

echo "Probando conexión directa:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$CONTAINER_IP:3000" 2>/dev/null)
echo "HTTP Status Code: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ El servicio responde correctamente"
else
    echo "❌ El servicio NO responde (HTTP $HTTP_CODE)"
    echo "   Esto indica que el problema está en el servicio, no en Traefik"
fi
echo ""

# 2. Verificar labels de Traefik en el servicio
echo "=== 2. LABELS DE TRAEFIK EN EL SERVICIO ==="
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep -i "traefik" | head -20
echo ""

# 3. Verificar red del contenedor
echo "=== 3. RED DEL CONTENEDOR ==="
docker inspect "$CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{"\n"}}{{end}}' 2>/dev/null
echo ""

# 4. Verificar red de Traefik
echo "=== 4. RED DE TRAEFIK ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    docker inspect "$TRAEFIK_CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{"\n"}}{{end}}' 2>/dev/null
else
    echo "No se encontró contenedor de Traefik"
fi
echo ""

# 5. Verificar si están en la misma red
echo "=== 5. VERIFICAR REDES COMPARTIDAS ==="
CONTAINER_NETWORKS=$(docker inspect "$CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}' 2>/dev/null)
TRAEFIK_NETWORKS=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}' 2>/dev/null 2>/dev/null)

echo "Redes del dashboard: $CONTAINER_NETWORKS"
echo "Redes de Traefik: $TRAEFIK_NETWORKS"
echo ""

# 6. Verificar logs de Traefik para errores
echo "=== 6. LOGS DE TRAEFIK (buscando errores) ==="
docker logs "$TRAEFIK_CONTAINER" --tail 50 2>&1 | grep -iE "error|404|dashboard|checkin24hs" | tail -10
echo ""

# 7. Verificar configuración del dominio directamente
echo "=== 7. PROBAR DOMINIO DIRECTAMENTE ==="
echo "Probando https://dashboard.checkin24hs.com desde el servidor:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "https://dashboard.checkin24hs.com" 2>&1 | head -1
echo ""

echo "=========================================="
echo "✅ Diagnóstico completado"
echo "=========================================="
