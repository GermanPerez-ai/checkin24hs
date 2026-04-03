#!/bin/bash

# Script para verificar y corregir configuración de Traefik para rutas /qr

echo "=========================================="
echo "🔍 VERIFICANDO CONFIGURACIÓN DE TRAEFIK"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Verificar etiquetas actuales
echo "1️⃣ Etiquetas Traefik actuales:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik" | sort
echo ""

# 2. Verificar que el servicio esté en la red easypanel
echo "2️⃣ Verificando red easypanel:"
NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if echo "$NETWORKS" | grep -q "easypanel"; then
    echo "✅ Servicio está en la red easypanel"
else
    echo "⚠️  Servicio NO está en la red easypanel"
    echo "   Agregando a la red..."
    docker service update --network-add easypanel "$SERVICE_NAME"
    sleep 3
fi
echo ""

# 3. Verificar logs de Traefik (si es posible)
echo "3️⃣ Verificando si Traefik está corriendo:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "✅ Traefik encontrado: $TRAEFIK_CONTAINER"
    echo ""
    echo "   Para ver logs de Traefik:"
    echo "   docker logs $TRAEFIK_CONTAINER --tail 50 | grep whatsapp"
else
    echo "⚠️  Contenedor Traefik no encontrado (puede estar como servicio Docker Swarm)"
    echo "   Buscando servicio Traefik..."
    docker service ls | grep -i traefik || echo "   No se encontró servicio Traefik"
fi
echo ""

# 4. Probar acceso directo al puerto (bypass Traefik)
echo "4️⃣ Probando acceso directo al servicio (bypass Traefik):"
CONTAINER_IP=$(docker service ps "$SERVICE_NAME" --no-trunc --format "{{.Node}}" | head -1)
if [ -n "$CONTAINER_IP" ]; then
    echo "   Probando: curl -I http://localhost:3001/api/qr"
    curl -I http://localhost:3001/api/qr 2>&1 | head -3
    echo ""
    echo "   Probando: curl -I http://localhost:3001/qr"
    curl -I http://localhost:3001/qr 2>&1 | head -3
else
    echo "   No se pudo obtener IP del contenedor"
fi
echo ""

echo "=========================================="
echo "💡 RECOMENDACIÓN"
echo "=========================================="
echo ""
echo "Si /api/qr funciona pero /qr no, usa siempre /api/qr"
echo "O verifica en EasyPanel → Dominios si hay alguna configuración"
echo "que esté limitando las rutas."
echo ""
