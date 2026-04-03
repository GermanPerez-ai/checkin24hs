#!/bin/bash
# Diagnóstico 404 en whatsapp.checkin24hs.com/api/send
# Ejecutar en el SERVIDOR (donde corre Docker/EasyPanel).

set -e
echo "=== Diagnóstico 404 WhatsApp ==="
echo ""

echo "--- 1. Servicios con 'whatsapp' en el nombre ---"
docker service ls 2>/dev/null | grep -i whatsapp || echo "(no se encontraron servicios o no estás en Swarm)"
echo ""

echo "--- 2. Labels Traefik del servicio WhatsApp ---"
SVC=""
for name in checkin24hs_whatsapp whatsapp; do
  if docker service inspect "$name" --format '{{.Spec.Name}}' 2>/dev/null | grep -q .; then
    SVC="$name"
    break
  fi
done
if [ -z "$SVC" ]; then
  echo "No se encontró servicio 'checkin24hs_whatsapp' ni 'whatsapp'. Listando todos:"
  docker service ls 2>/dev/null || true
else
  echo "Servicio: $SVC"
  docker service inspect "$SVC" --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}
{{end}}' 2>/dev/null | grep -E "traefik\.http\.(routers|middlewares|services)" || echo "(sin labels Traefik)"
fi
echo ""

echo "--- 3. Prueba directa al backend (contenedor en puerto 3001) ---"
echo "Si el servicio está en este host, probar:"
echo "  curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3001/api/send"
echo "  curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3001/api/health"
echo "(Necesitás el puerto publicado o ejecutar curl desde dentro de la red del stack.)"
echo ""

echo "--- 4. Resumen ---"
echo "Si los labels de Traefik NO aparecen en el servicio, el redeploy desde EasyPanel"
echo "puede no estar usando este docker-compose o el dominio whatsapp.checkin24hs.com"
echo "puede estar asignado en EasyPanel a otra app/proxy."
echo ""
echo "Comprobá en EasyPanel:"
echo "  - Que la app que tiene el servicio WhatsApp use 'Deploy from Compose' con el"
echo "    docker-compose.easypanel.yml de este repo (con PathPrefix y routers)."
echo "  - Que el dominio whatsapp.checkin24hs.com esté vinculado a ESA app y no"
echo "    a un proxy genérico que devuelve 404."
echo "=== Fin ==="
