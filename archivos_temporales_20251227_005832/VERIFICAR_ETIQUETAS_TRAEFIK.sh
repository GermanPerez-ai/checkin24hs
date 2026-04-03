#!/bin/bash
# Verificar etiquetas Traefik de los servicios de WhatsApp

echo "=== Verificación de Etiquetas Traefik ==="
echo ""

for service in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $service:"
    
    # Ver todas las etiquetas
    ALL_LABELS=$(docker service inspect $service --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null)
    
    # Filtrar solo Traefik
    TRAEFIK_LABELS=$(echo "$ALL_LABELS" | grep -i traefik)
    
    if [ ! -z "$TRAEFIK_LABELS" ]; then
        echo "   ✅ Etiquetas Traefik encontradas:"
        echo "$TRAEFIK_LABELS" | sed 's/^/      /'
    else
        echo "   ❌ No se encontraron etiquetas Traefik"
        echo "   Todas las etiquetas del servicio:"
        echo "$ALL_LABELS" | head -10 | sed 's/^/      /'
    fi
    
    echo ""
done

echo "=== Verificar desde Docker Service Inspect ==="
echo ""

for service in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $service:"
    docker service inspect $service --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik || echo "   No hay etiquetas Traefik"
    echo ""
done






