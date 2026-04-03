#!/bin/bash
# Diagnosticar error 502 en servicios de WhatsApp

echo "=== DIAGNÓSTICO DE ERROR 502 ==="
echo ""

# Verificar servicios de WhatsApp
echo "📋 Servicios de WhatsApp:"
docker service ls | grep whatsapp
echo ""

# Verificar labels de Traefik
echo "=== CONFIGURACIÓN DE TRAEFIK ==="
for service in checkin24hs_whatsapp checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "=== $service ==="
    echo "Labels Traefik:"
    docker service inspect $service --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
    echo ""
done

# Verificar redes
echo "=== REDES DE LOS SERVICIOS ==="
for service in checkin24hs_whatsapp checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "=== $service ==="
    echo "Redes:"
    docker service inspect $service --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{"\n"}}{{end}}'
    echo ""
done

# Verificar si Traefik puede alcanzar los servicios
echo "=== VERIFICANDO CONECTIVIDAD ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo "Redes de Traefik:"
    docker inspect $TRAEFIK_CONTAINER --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}'
    echo ""
fi

# Verificar puertos internos de los servicios
echo "=== PUERTOS INTERNOS DE LOS SERVICIOS ==="
for service in checkin24hs_whatsapp checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "=== $service ==="
    echo "Puertos:"
    docker service inspect $service --format '{{range .Endpoint.Ports}}{{.TargetPort}} ({{.Protocol}}){{"\n"}}{{end}}'
    echo ""
done

# Verificar logs de Traefik para errores 502
echo "=== LOGS DE TRAEFIK (errores 502) ==="
if [ -n "$TRAEFIK_CONTAINER" ]; then
    docker logs $TRAEFIK_CONTAINER --tail 100 2>&1 | grep -iE "502|bad gateway|api[1-4]" | tail -20 || echo "   (sin errores 502 recientes)"
fi

echo ""
echo "=== SOLUCIÓN SUGERIDA ==="
echo ""
echo "El error 502 indica que Traefik no puede conectarse al servicio backend."
echo "Posibles causas:"
echo "1. El servicio no está en la misma red que Traefik"
echo "2. El puerto configurado en Traefik no coincide con el puerto del servicio"
echo "3. El servicio no está respondiendo"
echo ""
echo "Verifica que:"
echo "- Los servicios estén en la red 'easypanel' (o la red que usa Traefik)"
echo "- El puerto en los labels de Traefik coincida con el puerto interno del servicio"
echo ""






