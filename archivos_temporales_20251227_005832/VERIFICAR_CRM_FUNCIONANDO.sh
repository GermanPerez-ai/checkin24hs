#!/bin/bash

echo "=== Verificar que el CRM está funcionando correctamente ==="

# 1. Verificar etiquetas Traefik
echo ""
echo "1. Etiquetas Traefik del CRM:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 2. Verificar estado del servicio
echo ""
echo "2. Estado del servicio CRM:"
docker service ps checkin24hs_crm --no-trunc | head -3

# 3. Verificar logs del servicio
echo ""
echo "3. Logs del servicio CRM (últimas 10 líneas):"
docker service logs checkin24hs_crm --tail 10

# 4. Probar acceso HTTPS
echo ""
echo "4. Probando acceso HTTPS:"
curl -I https://crm.checkin24hs.com 2>&1 | head -10

# 5. Probar acceso HTTP (debería redirigir)
echo ""
echo "5. Probando acceso HTTP (debería redirigir a HTTPS):"
curl -I http://crm.checkin24hs.com 2>&1 | head -10

# 6. Verificar que el servicio está escuchando en el puerto correcto
echo ""
echo "6. Verificando que el servicio está escuchando en el puerto 3005:"
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    docker exec $CONTAINER_ID netstat -tuln 2>/dev/null | grep 3005 || docker exec $CONTAINER_ID ss -tuln 2>/dev/null | grep 3005
fi

echo ""
echo "=== Verificación completada ==="
echo ""
echo "El CRM debería estar accesible en: https://crm.checkin24hs.com"
echo "El acceso HTTP debería redirigir automáticamente a HTTPS"
