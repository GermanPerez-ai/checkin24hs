#!/bin/bash

echo "=== Configurar Traefik para CRM (versión final) ==="

# 1. Verificar etiquetas actuales
echo ""
echo "1. Etiquetas Traefik actuales:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "No hay etiquetas Traefik"

# 2. Eliminar etiquetas antiguas si existen (para empezar limpio)
echo ""
echo "2. Eliminando etiquetas Traefik antiguas (si existen)..."
docker service update \
  --label-rm "traefik.enable" \
  --label-rm "traefik.http.routers.crm.rule" \
  --label-rm "traefik.http.routers.crm.entrypoints" \
  --label-rm "traefik.http.services.crm.loadbalancer.server.port" \
  checkin24hs_crm 2>/dev/null || echo "No había etiquetas antiguas"

# 3. Esperar un momento
sleep 5

# 4. Agregar etiquetas Traefik correctas
echo ""
echo "3. Agregando etiquetas Traefik correctas..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.crm.entrypoints=web" \
  --label-add "traefik.http.routers.crm.entrypoints=websecure" \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  checkin24hs_crm

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas Traefik agregadas"
else
    echo "❌ Error al agregar etiquetas Traefik"
    exit 1
fi

# 5. Verificar que se agregaron
echo ""
echo "4. Verificando etiquetas después de agregar:"
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 6. Esperar a que Traefik detecte los cambios
echo ""
echo "5. Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

# 7. Verificar logs de Traefik
echo ""
echo "6. Logs de Traefik relacionados con CRM:"
docker service logs traefik --tail 100 | grep -iE "crm|checkin24hs_crm" | tail -20

# 8. Verificar contenedor del CRM
echo ""
echo "7. Verificando contenedor del CRM:"
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    
    # Obtener IP del contenedor en la red easypanel
    CRM_IP=$(docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{range $value}}{{.IPAddress}}{{end}}{{println}}{{end}}' | grep easypanel | awk -F': ' '{print $2}')
    
    if [ ! -z "$CRM_IP" ]; then
        echo "IP del CRM en easypanel: $CRM_IP"
        echo ""
        echo "8. Probando conexión desde el servidor:"
        timeout 3 bash -c "echo > /dev/tcp/$CRM_IP/3005" 2>/dev/null && echo "✅ Puerto 3005 accesible desde el servidor" || echo "⚠️  Puerto 3005 no accesible desde el servidor"
    fi
fi

# 9. Probar acceso HTTP desde el servidor
echo ""
echo "9. Probando acceso HTTP desde el servidor:"
curl -I http://localhost:3005 2>&1 | head -5 || echo "No se puede acceder desde localhost (normal si solo escucha en 0.0.0.0 dentro del contenedor)"

# 10. Verificar configuración de Traefik
echo ""
echo "10. Verificando configuración de Traefik:"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo ""
    echo "11. Redes del contenedor Traefik:"
    docker inspect $TRAEFIK_CONTAINER --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{println}}{{end}}' | grep easypanel && echo "✅ Traefik está en la red easypanel"
fi

echo ""
echo "=== Configuración completada ==="
echo ""
echo "Ahora prueba acceder a: http://crm.checkin24hs.com"
echo "Espera 1-2 minutos para que Traefik propague completamente los cambios"
echo ""
echo "Si aún no funciona, verifica:"
echo "1. Que el DNS de crm.checkin24hs.com resuelva correctamente: nslookup crm.checkin24hs.com"
echo "2. Que Traefik esté detectando el servicio: docker service logs traefik --tail 50 | grep crm"


















