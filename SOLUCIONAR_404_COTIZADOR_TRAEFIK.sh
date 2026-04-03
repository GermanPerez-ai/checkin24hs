#!/bin/bash
# Script para solucionar el error 404 del cotizador configurando Traefik

echo "=========================================="
echo "🔧 SOLUCIONAR 404 COTIZADOR - TRAEFIK"
echo "=========================================="
echo ""

# Nombre del servicio
SERVICE_NAME="checkin24hs_cotizador"

# Verificar que el servicio existe
echo "1️⃣ Verificando que el servicio existe..."
if ! docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo "❌ Error: Servicio '$SERVICE_NAME' no encontrado"
    echo ""
    echo "Servicios disponibles con 'cotizador':"
    docker service ls --format "{{.Name}}" | grep -i cotizador || echo "   (ninguno encontrado)"
    echo ""
    echo "Todos los servicios:"
    docker service ls --format "{{.Name}}" | head -10
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# Verificar que está en la red easypanel
echo "2️⃣ Verificando red easypanel..."
NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if echo "$NETWORKS" | grep -q "easypanel"; then
    echo "   ✅ Ya está en la red easypanel"
else
    echo "   ⚠️  No está en la red easypanel, agregando..."
    OUT=$(docker service update --network-add easypanel "$SERVICE_NAME" 2>&1)
    RET=$?
    if [ $RET -eq 0 ]; then
        echo "   ✅ Agregado a la red easypanel"
        echo "   ⏳ Esperando 10 segundos..."
        sleep 10
    elif echo "$OUT" | grep -q "already attached"; then
        echo "   ✅ Ya estaba en la red easypanel (Docker lo confirmó)"
    else
        echo "   ❌ Error al agregar a la red easypanel: $OUT"
        exit 1
    fi
fi
echo ""

# Verificar etiquetas actuales
echo "3️⃣ Etiquetas Traefik actuales:"
CURRENT_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep traefik)
if [ -z "$CURRENT_LABELS" ]; then
    echo "   ⚠️  No tiene etiquetas Traefik configuradas"
else
    echo "$CURRENT_LABELS" | sed 's/^/   /'
fi
echo ""

# Configurar etiquetas Traefik
echo "4️⃣ Configurando etiquetas Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.cotizador.tls=true" \
  --label-add "traefik.http.routers.cotizador.service=cotizador-service" \
  --label-add "traefik.http.services.cotizador-service.loadbalancer.server.port=80" \
  --label-add "traefik.docker.network=easypanel" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "   ✅ Etiquetas Traefik agregadas correctamente"
else
    echo "   ❌ Error al agregar etiquetas Traefik"
    exit 1
fi
echo ""

# Verificar configuración final
echo "5️⃣ Verificando configuración final..."
FINAL_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep traefik)
echo "Etiquetas Traefik configuradas:"
echo "$FINAL_LABELS" | sed 's/^/   /'
echo ""

# Esperar a que Traefik detecte los cambios
echo "6️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30
echo ""

# Verificar estado del servicio
echo "7️⃣ Estado del servicio:"
docker service ps "$SERVICE_NAME" --no-trunc | head -3
echo ""

echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🌐 Próximos pasos:"
echo "   1. Espera 1-2 minutos adicionales para que Traefik genere el certificado SSL"
echo "   2. Prueba acceder a: https://cotizar.checkin24hs.com/"
echo "   3. Si aún no funciona, verifica en EasyPanel:"
echo "      - Ve al servicio 'cotizador'"
echo "      - Pestaña 'Dominios'"
echo "      - Debe tener 'cotizar.checkin24hs.com' configurado"
echo ""
echo "📋 Para verificar manualmente:"
echo "   docker service inspect $SERVICE_NAME --format '{{range \$key, \$value := .Spec.Labels}}{{\$key}}={{\$value}}{{\"\\n\"}}{{end}}' | grep traefik"
echo ""
