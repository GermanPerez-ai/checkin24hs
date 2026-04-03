#!/bin/bash
# Ver cómo está configurado Traefik y por qué ignora las labels del webmail

echo "=== 1. Traefik: comando y variables de entorno ==="
TRAEFIK_ID=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
docker inspect $TRAEFIK_ID --format '{{.Config.Cmd}}'
docker inspect $TRAEFIK_ID --format '{{range .Config.Env}}{{.}}{{"\n"}}{{end}}' | grep -iE "traefik|provider|docker"
echo ""

echo "=== 2. Traefik: volúmenes y archivos de config montados ==="
docker inspect $TRAEFIK_ID --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
echo ""

echo "=== 3. Servicios con labels que contienen 'traefik' o 'webmail' ==="
for s in $(docker service ls --format '{{.Name}}'); do
  L=$(docker service inspect $s --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}} {{end}}' 2>/dev/null)
  if echo "$L" | grep -qi traefik; then
    echo "--- $s ---"
    echo "$L" | tr ' ' '\n' | grep -i traefik
    echo ""
  fi
done
echo ""

echo "=== 4. Petición a localhost:80 con Host webmail (sin DNS) ==="
curl -sI -H "Host: webmail.checkin24hs.com" "http://127.0.0.1/" | head -5
echo ""

echo "=== 5. Logs de Traefik (últimas 20 líneas) ==="
docker service logs $(docker service ls -q --filter name=traefik) --tail 20 2>&1
