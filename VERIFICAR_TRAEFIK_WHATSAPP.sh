#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO CONFIGURACIÓN DE TRAEFIK PARA WHATSAPP"
echo "=========================================="
echo ""

# 1. Ver contenedor de Traefik
echo "1️⃣ Contenedor Traefik:"
echo "=========================================="
docker ps --filter "name=traefik" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 2. Ver configuración del contenedor de WhatsApp
echo "2️⃣ Contenedor WhatsApp y sus etiquetas:"
echo "=========================================="
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)
if [ ! -z "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    echo ""
    echo "Etiquetas (labels) del contenedor:"
    docker inspect "$CONTAINER" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep -E "traefik|easy" || echo "No se encontraron etiquetas de Traefik"
    echo ""
    echo "Puertos expuestos:"
    docker port "$CONTAINER"
else
    echo "❌ No se encontró contenedor de WhatsApp 1"
fi
echo ""

# 3. Ver logs de Traefik buscando errores o configuraciones
echo "3️⃣ Últimos logs de Traefik:"
echo "=========================================="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    docker logs "$TRAEFIK_CONTAINER" --tail 30 2>&1 | grep -i "error\|api1\|whatsapp\|route" | tail -15 || echo "No se encontraron logs relevantes"
else
    echo "❌ No se encontró contenedor de Traefik"
fi
echo ""

# 4. Verificar si Traefik puede alcanzar el contenedor de WhatsApp
echo "4️⃣ Verificando conectividad desde Traefik:"
echo "=========================================="
if [ ! -z "$TRAEFIK_CONTAINER" ] && [ ! -z "$CONTAINER" ]; then
    echo "Probando conexión desde Traefik al contenedor WhatsApp..."
    docker exec "$TRAEFIK_CONTAINER" wget -q -O- --timeout=3 http://${CONTAINER}:3001/api/status?card=1 2>&1 | head -5 || \
    docker exec "$TRAEFIK_CONTAINER" curl -s --max-time 3 http://${CONTAINER}:3001/api/status?card=1 2>&1 | head -5 || \
    echo "No se pudo conectar (puede ser normal si no tienen wget/curl en Traefik)"
else
    echo "No se pueden verificar los contenedores"
fi
echo ""

# 5. Ver configuración completa del contenedor WhatsApp
echo "5️⃣ Configuración completa del contenedor WhatsApp:"
echo "=========================================="
if [ ! -z "$CONTAINER" ]; then
    docker inspect "$CONTAINER" --format '{{json .Config.Labels}}' | python3 -m json.tool 2>/dev/null || \
    docker inspect "$CONTAINER" --format '{{json .Config.Labels}}' | jq '.' 2>/dev/null || \
    docker inspect "$CONTAINER" --format '{{json .Config.Labels}}'
fi
echo ""

echo "=========================================="
echo "📋 DIAGNÓSTICO:"
echo "=========================================="
echo ""
echo "Si NO hay etiquetas de Traefik en el contenedor WhatsApp:"
echo "  - El contenedor no está configurado para ser enrutado por Traefik"
echo "  - Necesitas agregar etiquetas Traefik al contenedor"
echo ""
echo "Etiquetas necesarias para api1.checkin24hs.com:"
echo "  - traefik.enable=true"
echo "  - traefik.http.routers.whatsapp.rule=Host(\"api1.checkin24hs.com\")"
echo "  - traefik.http.routers.whatsapp.entrypoints=websecure"
echo "  - traefik.http.routers.whatsapp.tls.certresolver=letsencrypt"
echo "  - traefik.http.services.whatsapp.loadbalancer.server.port=3001"
echo ""



