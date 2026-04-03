#!/bin/bash

echo "=== Corregir etiquetas Traefik del CRM ==="

# 1. Ver etiquetas actuales
echo ""
echo "1. Etiquetas actuales del CRM:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 2. Eliminar etiquetas actuales
echo ""
echo "2. Eliminando etiquetas actuales..."
docker service update \
  --label-rm "traefik.enable" \
  --label-rm "traefik.http.routers.crm.rule" \
  --label-rm "traefik.http.routers.crm.entrypoints" \
  --label-rm "traefik.http.services.crm.loadbalancer.server.port" \
  checkin24hs_crm 2>/dev/null

sleep 5

# 3. Agregar etiquetas correctas (igual que el Dashboard)
echo ""
echo "3. Agregando etiquetas correctas (igual que el Dashboard)..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.crm.entrypoints=websecure" \
  --label-add "traefik.http.routers.crm.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  checkin24hs_crm

# 4. Verificar que se agregaron
echo ""
echo "4. Esperando 10 segundos..."
sleep 10

echo ""
echo "5. Verificando etiquetas después de agregar:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 5. Reiniciar Traefik para que detecte los cambios
echo ""
echo "6. Reiniciando Traefik..."
docker service update --force traefik

# 6. Esperar y verificar
echo ""
echo "7. Esperando 30 segundos para que Traefik se reinicie y detecte los cambios..."
sleep 30

# 7. Probar acceso HTTPS (websecure)
echo ""
echo "8. Probando acceso HTTPS:"
curl -I https://crm.checkin24hs.com 2>&1 | head -10

# 8. Probar acceso HTTP (debería redirigir a HTTPS)
echo ""
echo "9. Probando acceso HTTP (debería redirigir):"
curl -I http://crm.checkin24hs.com 2>&1 | head -10

# 9. Ver logs de Traefik
echo ""
echo "10. Logs de Traefik (últimas 20 líneas):"
docker service logs traefik --tail 20

echo ""
echo "=== Proceso completado ==="
echo ""
echo "Ahora prueba acceder a: https://crm.checkin24hs.com"
echo "El acceso HTTP debería redirigir automáticamente a HTTPS"






