#!/bin/bash
# 🔍 Verificar labels de Traefik en el servicio

echo "=============================================================="
echo "🔍 VERIFICANDO LABELS DE TRAEFIK"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Ver TODOS los labels del servicio
echo "1️⃣  Todos los labels del servicio:"
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.Labels}}' | python3 -m json.tool
echo ""

# 2. Buscar labels específicos de Traefik
echo "2️⃣  Labels relacionados con Traefik:"
docker service inspect checkin24hs_whatsapp --format '{{range $key, $value := .Spec.Labels}}{{if or (contains $key "traefik") (contains $key "router") (contains $key "rule")}}{{$key}}={{$value}}{{println}}{{end}}{{end}}' 2>/dev/null || \
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.Labels}}' | python3 -m json.tool | grep -iE "traefik|router|rule|enable|http|service"
echo ""

# 3. Verificar si el servicio está en la misma red que Traefik
echo "3️⃣  Redes del servicio:"
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.TaskTemplate.Networks}}' | python3 -m json.tool 2>/dev/null || \
docker service inspect checkin24hs_whatsapp | grep -A 10 "Networks"
echo ""

# 4. Verificar red de Traefik
echo "4️⃣  Redes de Traefik:"
docker service inspect traefik --format '{{json .Spec.TaskTemplate.Networks}}' | python3 -m json.tool 2>/dev/null || \
docker service inspect traefik | grep -A 10 "Networks"
echo ""

# 5. Verificar contenedor y sus labels
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "5️⃣  Labels del contenedor:"
docker inspect $CONTAINER_ID --format '{{json .Config.Labels}}' | python3 -m json.tool | grep -iE "traefik|router|rule" || echo "   ⚠️  No se encontraron labels de Traefik en el contenedor"
echo ""

# 6. Verificar si hay un dominio configurado para este servicio
echo "6️⃣  Buscando configuración de dominio:"
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.Labels}}' | python3 -m json.tool | grep -iE "host|domain|rule" || echo "   ⚠️  No se encontró configuración de dominio"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
echo "📋 Nota: Si no hay labels de Traefik configurados, el servicio"
echo "   solo será accesible directamente por el puerto 3001."
echo "   Para acceder a través de Traefik, necesitarías configurar"
echo "   labels como:"
echo "   - traefik.enable=true"
echo "   - traefik.http.routers.whatsapp.rule=Host(\"tu-dominio.com\")"
echo "   - traefik.http.services.whatsapp.loadbalancer.server.port=3001"
echo ""
