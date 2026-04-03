#!/bin/bash
# Verificar y configurar SSL para WhatsApp

echo "=== VERIFICANDO SERVICIO WHATSAPP ==="
echo ""

# Buscar servicios de WhatsApp
echo "🔍 Buscando servicios de WhatsApp..."
docker service ls --format "{{.Name}}" | grep -i whatsapp

echo ""
echo "=== CONFIGURANDO SSL ==="
echo ""

# Intentar con el nombre más probable
SERVICE_NAME="checkin24hs_whatsapp"
DOMAIN="whatsapp.checkin24hs.com"
PORT="3001"

# Verificar si existe
if docker service ls --format "{{.Name}}" | grep -q "^${SERVICE_NAME}$"; then
    echo "✅ Servicio encontrado: $SERVICE_NAME"
    echo ""
    
    # Verificar red
    NETWORKS=$(docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if ! echo "$NETWORKS" | grep -q "easypanel"; then
        echo "➕ Agregando a red easypanel..."
        docker service update --network-add easypanel $SERVICE_NAME
        sleep 3
    fi
    
    # Aplicar labels
    echo "🔧 Aplicando labels SSL..."
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.whatsapp.rule=Host(\`${DOMAIN}\`)" \
      --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
      --label-add "traefik.http.routers.whatsapp.tls=true" \
      --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=${PORT}" \
      $SERVICE_NAME 2>&1 | grep -v "since no changes were detected" || true
    
    echo ""
    echo "✅ Configuración aplicada"
    echo ""
    echo "⏳ Espera 2-5 minutos para que Let's Encrypt genere el certificado"
    echo "🌐 Luego accede a: https://${DOMAIN}/api/qr"
else
    echo "❌ Servicio $SERVICE_NAME no encontrado"
    echo ""
    echo "Por favor, ejecuta este comando para ver todos los servicios:"
    echo "   docker service ls"
    echo ""
    echo "Y luego actualiza el script con el nombre correcto del servicio"
fi
