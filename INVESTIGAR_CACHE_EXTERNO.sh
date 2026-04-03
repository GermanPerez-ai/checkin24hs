#!/bin/bash

echo "=========================================="
echo "🔍 INVESTIGACIÓN: CACHE EXTERNO"
echo "=========================================="
echo ""

# 1. Verificar headers HTTP que envía el servidor
echo "=== 1. HEADERS HTTP DEL SERVIDOR ==="
echo "Verificando headers de respuesta de dashboard.checkin24hs.com..."
echo ""
curl -I https://dashboard.checkin24hs.com 2>&1 | head -20
echo ""

# 2. Verificar si hay Cloudflare u otro CDN
echo "=== 2. VERIFICAR CDN/PROXY EXTERNO ==="
CF_HEADERS=$(curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cf-|cloudflare|cdn-|x-forwarded")
if [ -n "$CF_HEADERS" ]; then
    echo "⚠️  Se encontraron headers de CDN/Proxy:"
    echo "$CF_HEADERS"
else
    echo "✅ No se encontraron headers de CDN externo"
fi
echo ""

# 3. Verificar headers de caché específicamente
echo "=== 3. HEADERS DE CACHÉ ==="
CACHE_HEADERS=$(curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cache-control|pragma|expires|etag|last-modified|age|via")
if [ -n "$CACHE_HEADERS" ]; then
    echo "Headers de caché encontrados:"
    echo "$CACHE_HEADERS"
else
    echo "⚠️  No se encontraron headers de caché explícitos"
fi
echo ""

# 4. Verificar desde el contenedor directamente (sin Traefik)
echo "=== 4. VERIFICAR CONTENEDOR DIRECTAMENTE (sin Traefik) ==="
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
CONTAINER_IP=$(docker inspect "$CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
echo "Contenedor: $CONTAINER"
echo "IP del contenedor: $CONTAINER_IP"
echo ""
echo "Probando conexión directa al contenedor (puerto 3000):"
curl -I http://localhost:3000 2>&1 | head -15
echo ""

# 5. Verificar servicios de caché conocidos
echo "=== 5. VERIFICAR SERVICIOS DE CACHÉ ==="
echo "Buscando contenedores relacionados con caché..."
docker ps --format "{{.Names}}" | grep -iE "cache|redis|varnish|nginx|cloudflare"
if [ $? -eq 0 ]; then
    echo "⚠️  Se encontraron servicios que podrían estar cacheando:"
    docker ps --format "table {{.Names}}\t{{.Image}}" | grep -iE "cache|redis|varnish|nginx"
else
    echo "✅ No se encontraron servicios de caché explícitos"
fi
echo ""

# 6. Verificar DNS y resolución
echo "=== 6. VERIFICAR DNS ==="
echo "Resolución DNS de dashboard.checkin24hs.com:"
nslookup dashboard.checkin24hs.com 2>&1 | grep -A 5 "Name:"
echo ""
echo "IP del servidor:"
hostname -I | awk '{print $1}'
echo ""

# 7. Verificar headers X-Forwarded (para ver si hay proxies)
echo "=== 7. HEADERS X-FORWARDED (proxies) ==="
FORWARDED_HEADERS=$(curl -I https://dashboard.checkin24hs.com 2>&1 | grep -i "x-forwarded")
if [ -n "$FORWARDED_HEADERS" ]; then
    echo "⚠️  Headers X-Forwarded encontrados (hay proxies):"
    echo "$FORWARDED_HEADERS"
else
    echo "✅ No se encontraron headers X-Forwarded"
fi
echo ""

# 8. Verificar respuesta completa con curl -v
echo "=== 8. RESPUESTA COMPLETA (verbose) ==="
echo "Obteniendo respuesta completa (primeras 40 líneas)..."
curl -v https://dashboard.checkin24hs.com 2>&1 | head -40
echo ""

echo "=========================================="
echo "✅ Investigación completada"
echo "=========================================="
echo ""
echo "💡 RESUMEN:"
echo "- Si ves 'cf-' o 'cloudflare' en headers → Hay Cloudflare cacheando"
echo "- Si ves 'Cache-Control' con valores largos → Hay caché activo"
echo "- Si ves 'X-Forwarded' → Hay proxies intermediarios"
echo "- Si ves 'Age' header → Hay caché intermediario"
echo ""
