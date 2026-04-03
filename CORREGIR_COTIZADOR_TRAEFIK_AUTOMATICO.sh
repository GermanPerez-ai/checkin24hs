#!/bin/bash
# Script para corregir automáticamente la configuración de Traefik para el cotizador
# Basado en el diagnóstico que muestra que el servicio existe pero no tiene etiquetas Traefik

echo "=========================================="
echo "🔧 CORREGIR CONFIGURACIÓN TRAEFIK COTIZADOR"
echo "=========================================="
echo ""

# Nombre del servicio (basado en el diagnóstico)
SERVICE_NAME="checkin24hs_cotizador"

# Verificar que el servicio existe
if ! docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo "❌ Error: Servicio '$SERVICE_NAME' no encontrado"
    echo ""
    echo "Servicios disponibles:"
    docker service ls --format "{{.Name}}" | grep -i cotizador
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# Verificar configuración actual
echo "📋 Configuración actual de Traefik:"
CURRENT_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep traefik)
if [ -z "$CURRENT_LABELS" ]; then
    echo "   ⚠️  No tiene etiquetas Traefik configuradas"
else
    echo "$CURRENT_LABELS" | sed 's/^/   /'
fi
echo ""

# Verificar que está en la red easypanel
echo "📋 Verificando red easypanel..."
NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
if echo "$NETWORKS" | grep -q "easypanel"; then
    echo "   ✅ Ya está en la red easypanel"
else
    echo "   ⚠️  No está en la red easypanel, agregando..."
    docker service update --network-add easypanel "$SERVICE_NAME"
    if [ $? -eq 0 ]; then
        echo "   ✅ Agregado a la red easypanel"
        echo "   ⏳ Esperando 10 segundos para que se aplique el cambio..."
        sleep 10
    else
        echo "   ❌ Error al agregar a la red easypanel"
        exit 1
    fi
fi
echo ""

# Configurar etiquetas Traefik
echo "🔧 Configurando etiquetas Traefik..."
echo ""

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.cotizador.service=cotizador-service" \
  --label-add "traefik.http.services.cotizador-service.loadbalancer.server.port=80" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "   ✅ Etiquetas Traefik agregadas correctamente"
else
    echo "   ❌ Error al agregar etiquetas Traefik"
    exit 1
fi
echo ""

# Verificar configuración final
echo "📋 Verificando configuración final..."
echo ""
FINAL_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep traefik)
echo "Etiquetas Traefik configuradas:"
echo "$FINAL_LABELS" | sed 's/^/   /'
echo ""

# Esperar a que Traefik detecte los cambios
echo "⏳ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30
echo ""

# Verificar logs de Traefik
echo "📋 Verificando logs de Traefik..."
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "   Buscando referencias a 'cotizar' en logs recientes:"
    docker logs "$TRAEFIK_CONTAINER" --tail 50 2>&1 | grep -i "cotizar\|cotizador" | tail -5 || echo "      (no se encontraron referencias aún, puede tardar un poco más)"
fi
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
