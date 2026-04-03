#!/bin/bash
# Script para crear el servicio cotizador directamente en el servidor

echo "=== PASO 1: Verificar archivos ==="
cd /root/checkin24hs
ls -la cotizador-cliente.html supabase-config.js supabase-client.js Dockerfile.cotizador

echo ""
echo "=== PASO 2: Construir imagen Docker ==="
docker build -f Dockerfile.cotizador -t cotizador:latest .

if [ $? -ne 0 ]; then
    echo "❌ Error al construir la imagen"
    exit 1
fi

echo ""
echo "✅ Imagen construida correctamente"
docker images | grep cotizador

echo ""
echo "=== PASO 3: Verificar que estamos en modo Swarm ==="
docker info | grep Swarm

echo ""
echo "=== PASO 4: Crear servicio Docker Swarm ==="
docker service create \
  --name cotizador \
  --network easypanel \
  --replicas 1 \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label "traefik.http.routers.cotizador.entrypoints=web" \
  --label "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label "traefik.http.services.cotizador.loadbalancer.server.port=80" \
  cotizador:latest

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Servicio creado correctamente"
    echo ""
    echo "=== PASO 5: Verificar servicio ==="
    docker service ls | grep cotizador
    echo ""
    echo "=== Logs del servicio ==="
    docker service logs cotizador --tail 20
    echo ""
    echo "✅ Servicio cotizador creado y corriendo"
    echo "🌐 Accede a: https://cotizar.checkin24hs.com (espera 2-3 minutos para que Traefik configure SSL)"
else
    echo "❌ Error al crear el servicio"
    exit 1
fi
