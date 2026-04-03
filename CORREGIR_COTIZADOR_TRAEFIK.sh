#!/bin/bash
# Corregir configuración de Traefik para el servicio cotizador

echo "=== Corrigiendo configuración de Traefik para cotizador ==="

# 1. Verificar etiquetas actuales
echo ""
echo "1. Etiquetas actuales:"
docker service inspect cotizador --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik

# 2. Actualizar servicio con nombre de servicio explícito
echo ""
echo "2. Actualizando servicio con configuración correcta..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.cotizador.entrypoints=web" \
  --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.cotizador.service=cotizador-service" \
  --label-add "traefik.http.services.cotizador-service.loadbalancer.server.port=80" \
  cotizador

if [ $? -eq 0 ]; then
    echo "✅ Configuración actualizada"
else
    echo "❌ Error al actualizar"
    exit 1
fi

# 3. Esperar a que Traefik detecte los cambios
echo ""
echo "3. Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

# 4. Verificar logs de Traefik
echo ""
echo "4. Verificando logs de Traefik:"
docker service logs traefik --tail 50 | grep -i "cotizar\|cotizador" || echo "No se encontraron referencias a cotizador en los logs"

# 5. Verificar que el servicio está corriendo
echo ""
echo "5. Estado del servicio:"
docker service ls | grep cotizador

echo ""
echo "✅ Configuración completada"
echo "🌐 Prueba acceder a: https://cotizar.checkin24hs.com"
