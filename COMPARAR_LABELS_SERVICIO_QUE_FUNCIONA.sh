#!/bin/bash
# Ver labels de un servicio que SÍ funciona (dashboard o cotizador) para replicar el patrón en webmail

echo "=== Labels del servicio dashboard (si existe y tiene traefik) ==="
docker service inspect checkin24hs_dashboard --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep -i traefik | sort || echo "(servicio no existe o sin labels traefik)"

echo ""
echo "=== Labels del servicio cotizador (si existe y tiene traefik) ==="
docker service inspect checkin24hs_cotizador --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep -i traefik | sort || echo "(servicio no existe o sin labels traefik)"

echo ""
echo "=== Todos los servicios con labels traefik.http.routers ==="
for s in $(docker service ls --format '{{.Name}}'); do
  R=$(docker service inspect $s --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}} {{end}}' 2>/dev/null | tr ' ' '\n' | grep "traefik.http.routers")
  if [ -n "$R" ]; then
    echo "--- $s ---"
    echo "$R"
    echo ""
  fi
done
