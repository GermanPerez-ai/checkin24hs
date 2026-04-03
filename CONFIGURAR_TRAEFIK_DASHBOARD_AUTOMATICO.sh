#!/bin/bash
# Script para configurar Traefik para el dashboard automáticamente
# Detecta el nombre del servicio y agrega las etiquetas necesarias

echo "=========================================="
echo "🔧 Configurando Traefik para Dashboard"
echo "=========================================="
echo ""

# 1. Detectar el nombre del servicio del dashboard (buscar específicamente dashboard, NO CRM)
echo "1️⃣ Detectando servicio del dashboard..."
# Buscar primero servicios que contengan "dashboard" pero NO "crm"
SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "dashboard" | grep -viE "crm" | head -1)

# Si no encuentra, buscar checkin24hs_dashboard específicamente
if [ -z "$SERVICE_NAME" ]; then
    SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "^checkin24hs_dashboard$|^checkin24hs-dashboard$" | head -1)
fi

# Si aún no encuentra, mostrar todos los servicios y pedir confirmación
if [ -z "$SERVICE_NAME" ]; then
    echo "⚠️  No se encontró servicio del dashboard automáticamente"
    echo ""
    echo "Servicios disponibles:"
    docker service ls
    echo ""
    echo "Por favor, especifica el nombre del servicio del dashboard:"
    read -p "Nombre del servicio: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        echo "❌ No se especificó un servicio"
        exit 1
    fi
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# 2. Verificar que el servicio existe
if ! docker service inspect "$SERVICE_NAME" > /dev/null 2>&1; then
    echo "❌ Error: El servicio $SERVICE_NAME no existe"
    exit 1
fi

# 3. Verificar etiquetas actuales
echo "2️⃣ Verificando etiquetas Traefik actuales..."
CURRENT_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik)

if [ ! -z "$CURRENT_LABELS" ]; then
    echo "⚠️  El servicio ya tiene etiquetas Traefik:"
    echo "$CURRENT_LABELS"
    echo ""
    read -p "¿Deseas reemplazarlas? (s/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
        echo "❌ Operación cancelada"
        exit 0
    fi
    
    # Eliminar etiquetas antiguas
    echo "🗑️  Eliminando etiquetas antiguas..."
    docker service update \
      --label-rm "traefik.enable" \
      --label-rm "traefik.http.routers.dashboard.rule" \
      --label-rm "traefik.http.routers.dashboard.entrypoints" \
      --label-rm "traefik.http.routers.dashboard.tls" \
      --label-rm "traefik.http.routers.dashboard.tls.certresolver" \
      --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
      "$SERVICE_NAME" 2>/dev/null || echo "No había etiquetas antiguas"
    
    sleep 5
fi

# 4. Verificar en qué red está el servicio
echo ""
echo "3️⃣ Verificando red del servicio..."
SERVICE_NETWORKS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}')
EASYPANEL_NET=$(docker network ls | grep easypanel | awk '{print $1}' | head -1)

if [ ! -z "$EASYPANEL_NET" ]; then
    EASYPANEL_NAME=$(docker network ls | grep easypanel | awk '{print $2}' | head -1)
    echo "✅ Red easypanel encontrada: $EASYPANEL_NAME ($EASYPANEL_NET)"
    
    # Verificar si el servicio está en la red easypanel
    if echo "$SERVICE_NETWORKS" | grep -q "$EASYPANEL_NET"; then
        echo "✅ El servicio está en la red easypanel"
    else
        echo "⚠️  El servicio NO está en la red easypanel"
        echo "🔧 Agregando a la red easypanel..."
        docker service update --network-add "$EASYPANEL_NAME" "$SERVICE_NAME"
        sleep 5
    fi
else
    echo "⚠️  No se encontró red easypanel"
    echo "   El servicio puede no ser detectado por Traefik"
fi

# 5. Agregar etiquetas de Traefik
echo ""
echo "4️⃣ Agregando etiquetas de Traefik..."
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=web" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  "$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Etiquetas Traefik agregadas correctamente"
else
    echo "❌ Error al agregar etiquetas Traefik"
    exit 1
fi

# 6. Verificar que se agregaron
echo ""
echo "5️⃣ Verificando etiquetas después de agregar..."
sleep 5
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

# 7. Esperar a que Traefik detecte los cambios
echo ""
echo "6️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

# 8. Verificar logs de Traefik
echo ""
echo "7️⃣ Verificando logs de Traefik..."
docker service logs traefik --tail 50 | grep -iE "dashboard|$SERVICE_NAME" | tail -10 || echo "No se encontraron logs relacionados"

# 9. Resumen
echo ""
echo "=========================================="
echo "✅ Configuración completada"
echo "=========================================="
echo ""
echo "Servicio: $SERVICE_NAME"
echo "Dominio: dashboard.checkin24hs.com"
echo "Puerto: 3000"
echo ""
echo "Espera 1-2 minutos y luego prueba acceder a:"
echo "  https://dashboard.checkin24hs.com"
echo ""
echo "Si aún no funciona, verifica:"
echo "  1. Que Traefik esté corriendo: docker service ls | grep traefik"
echo "  2. Que el servicio esté en la red easypanel"
echo "  3. Los logs de Traefik: docker service logs traefik --tail 100"
echo ""
