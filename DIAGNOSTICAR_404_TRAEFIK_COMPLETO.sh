#!/bin/bash
# Diagnóstico completo 404 webmail + Traefik

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

echo "=============================================="
echo "DIAGNOSTICO 404 TRAEFIK WEBMAIL"
echo "=============================================="
echo ""

echo "1. TODAS las labels del servicio webmail:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | sort
echo ""

echo "2. Redes del servicio webmail:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>/dev/null
echo ""

echo "3. IP actual del contenedor webmail:"
echo "----------------------------------------"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker inspect "$CONTAINER_ID" --format '{{range $k, $v := .NetworkSettings.Networks}}Red: {{$k}} -> IP: {{$v.IPAddress}}{{"\n"}}{{end}}' 2>/dev/null
echo ""

echo "4. Servicio Traefik (nombre y red):"
echo "----------------------------------------"
docker service ls | grep -i traefik
TRAEFIK_SERVICE=$(docker service ls --format '{{.Name}}' | grep -i traefik | head -1)
if [ -n "$TRAEFIK_SERVICE" ]; then
  echo "   Redes de Traefik:"
  docker service inspect "$TRAEFIK_SERVICE" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>/dev/null
  echo ""
  echo "   Labels de Traefik (solo traefik.):"
  docker service inspect "$TRAEFIK_SERVICE" --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep -i traefik | head -20
fi
echo ""

echo "5. API Traefik - Routers (puerto 8080):"
echo "----------------------------------------"
# Traefik suele exponer API en 8080
TRAEFIK_TASK=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ -n "$TRAEFIK_TASK" ]; then
  docker exec "$TRAEFIK_TASK" wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | head -100 || echo "   (API no disponible o puerto distinto)"
else
  curl -s http://localhost:8080/api/http/routers 2>/dev/null | head -50 || echo "   (No se pudo conectar a API Traefik :8080)"
fi
echo ""

echo "6. API Traefik - Entrypoints:"
echo "----------------------------------------"
if [ -n "$TRAEFIK_TASK" ]; then
  docker exec "$TRAEFIK_TASK" wget -qO- http://localhost:8080/api/entrypoints 2>/dev/null || true
else
  curl -s http://localhost:8080/api/entrypoints 2>/dev/null || true
fi
echo ""

echo "7. Otros servicios con label Host (posible conflicto):"
echo "----------------------------------------"
for s in $(docker service ls --format '{{.Name}}'); do
  RULE=$(docker service inspect "$s" --format '{{range $k,$v := .Spec.Labels}}{{if eq $k "traefik.http.routers.webmail.rule"}}{{$v}}{{end}}{{end}}' 2>/dev/null)
  RULE2=$(docker service inspect "$s" --format '{{range $k,$v := .Spec.Labels}}{{if eq $k "traefik.http.routers.webmail-websecure.rule"}}{{$v}}{{end}}{{end}}' 2>/dev/null)
  if [ -n "$RULE" ] || [ -n "$RULE2" ]; then
    echo "   $s: webmail rule = $RULE $RULE2"
  fi
done
docker service ls --format '{{.Name}}' | while read s; do
  docker service inspect "$s" --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>/dev/null | grep -q "webmail.checkin24hs.com" && echo "   Dominio en servicio: $s"
done
echo ""

echo "8. Probar HTTP (puerto 80) ademas de HTTPS:"
echo "----------------------------------------"
curl -s -o /dev/null -w "   https://$DOMAIN/ -> %{http_code}\n" -k "https://$DOMAIN/"
curl -s -o /dev/null -w "   http://$DOMAIN/  -> %{http_code}\n" "http://$DOMAIN/" 2>/dev/null || echo "   http no probado (timeout o redirect)"
echo ""

echo "=============================================="
echo "POSIBLES SOLUCIONES"
echo "=============================================="
echo ""
echo "A) Si no hay traefik.http.routers.* para webmail:"
echo "   En EasyPanel -> webmail -> Dominios: agrega exactamente: $DOMAIN"
echo "   Luego Implementar. O anade labels manualmente (ver abajo)."
echo ""
echo "B) Si el entrypoint no es websecure, prueba:"
echo "   docker service update --label-add 'traefik.http.routers.webmail.entrypoints=web' $SERVICE_NAME"
echo "   (para HTTP) y prueba http://$DOMAIN/"
echo ""
echo "C) Algunos paneles usan nombre de router con sufijo, ej:"
echo "   traefik.http.routers.webmail-websecure.rule=Host(\`$DOMAIN\`)"
echo "   traefik.http.routers.webmail-websecure.service=webmail"
echo "   traefik.http.routers.webmail-websecure.entrypoints=websecure"
echo ""
echo "D) Reiniciar Traefik para que recargue labels:"
echo "   docker service update --force $TRAEFIK_SERVICE"
echo ""
