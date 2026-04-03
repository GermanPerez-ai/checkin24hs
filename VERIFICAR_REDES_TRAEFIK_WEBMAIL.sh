#!/bin/bash
# Traefik solo descubre servicios en sus mismas redes. Comprobar si webmail y Traefik comparten red.

echo "=== Redes del servicio Traefik ==="
docker service inspect $(docker service ls -q --filter name=traefik) --format '{{range .Spec.TaskTemplate.Networks}}  {{.Target}}{{end}}' 2>/dev/null
TRAEFIK_NETS=$(docker service inspect $(docker service ls -q --filter name=traefik) --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>/dev/null)

echo ""
echo "=== Redes del servicio webmail ==="
docker service inspect checkin24hs_webmail --format '{{range .Spec.TaskTemplate.Networks}}  {{.Target}}{{end}}' 2>/dev/null
WEBMAIL_NETS=$(docker service inspect checkin24hs_webmail --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>/dev/null)

echo ""
echo "=== Nombre de las redes (Traefik) ==="
for id in $TRAEFIK_NETS; do docker network inspect $id --format '  {{.Name}}: {{.Id}}' 2>/dev/null; done

echo ""
echo "=== Nombre de las redes (webmail) ==="
for id in $WEBMAIL_NETS; do docker network inspect $id --format '  {{.Name}}: {{.Id}}' 2>/dev/null; done

echo ""
echo "=== Servicios que SÍ tienen labels traefik (para comparar) ==="
for s in $(docker service ls --format '{{.Name}}'); do
  L=$(docker service inspect $s --format '{{range $k,$v := .Spec.Labels}}{{$k}} {{end}}' 2>/dev/null)
  if echo "$L" | grep -q "traefik.http.routers"; then
    NETS=$(docker service inspect $s --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>/dev/null)
    echo "  $s -> redes: $NETS"
  fi
done
echo ""
echo "Si webmail no comparte ninguna red con Traefik, anade webmail a la red de Traefik:"
echo "  RED=\$(docker network ls --filter name=easypanel -q | head -1)"
echo "  docker service update --network-add \$RED checkin24hs_webmail"
