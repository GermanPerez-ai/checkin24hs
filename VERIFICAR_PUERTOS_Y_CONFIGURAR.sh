#!/bin/bash
# Verificar puertos y configurar SSL correctamente

echo "=== VERIFICANDO PUERTOS DE SERVICIOS WHATSAPP ==="
echo ""

for service in checkin24hs_whatsapp checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "=== $service ==="
    echo "Puertos configurados:"
    docker service inspect $service --format '{{range .Endpoint.Ports}}{{.PublishedPort}} -> {{.TargetPort}} ({{.Protocol}}){{"\n"}}{{end}}' 2>/dev/null || echo "  Sin puertos publicados"
    
    echo "Labels actuales:"
    docker service inspect $service --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep -E "traefik|port" || echo "  (sin labels relevantes)"
    echo ""
done

echo "=== CONFIGURACIÓN CORRECTA ==="
echo ""
echo "Los servicios no necesitan puertos publicados si usan Traefik"
echo "Traefik se conectará internamente a través de la red Docker"
echo ""






