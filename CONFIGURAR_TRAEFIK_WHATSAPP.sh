#!/bin/bash

echo "=========================================="
echo "🔧 CONFIGURANDO TRAEFIK PARA WHATSAPP"
echo "=========================================="
echo ""

# Verificar si estamos usando Docker Swarm
echo "1️⃣ Verificando servicios de Docker Swarm:"
echo "=========================================="
docker service ls | grep whatsapp
echo ""

# Obtener el nombre del servicio
SERVICE_NAME=$(docker service ls | grep whatsapp | grep "\.1" | awk '{print $2}' | head -1)

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró servicio de WhatsApp en Docker Swarm"
    echo ""
    echo "Intentando con nombre completo..."
    SERVICE_NAME="checkin24hs_whatsapp"
fi

echo "Servicio encontrado: $SERVICE_NAME"
echo ""

# Ver configuración actual del servicio
echo "2️⃣ Configuración actual del servicio:"
echo "=========================================="
docker service inspect "$SERVICE_NAME" --format '{{json .Spec.Labels}}' | python3 -m json.tool 2>/dev/null || \
docker service inspect "$SERVICE_NAME" --format '{{json .Spec.Labels}}'
echo ""

echo "=========================================="
echo "📋 OPCIONES PARA CONFIGURAR:"
echo "=========================================="
echo ""
echo "OPCIÓN 1: Configurar desde EasyPanel (RECOMENDADO)"
echo "  1. Ve a EasyPanel → Apps → WhatsApp"
echo "  2. Ve a la pestaña 'Domains' o 'Settings'"
echo "  3. Agrega el dominio: api1.checkin24hs.com"
echo "  4. Configura el puerto: 3001"
echo "  5. Guarda y espera a que se actualice"
echo ""
echo "OPCIÓN 2: Agregar etiquetas manualmente (AVANZADO)"
echo "  Ejecuta este comando para actualizar el servicio:"
echo ""
echo "  docker service update \\"
echo "    --label-add 'traefik.enable=true' \\"
echo "    --label-add 'traefik.http.routers.whatsapp.rule=Host(\"api1.checkin24hs.com\")' \\"
echo "    --label-add 'traefik.http.routers.whatsapp.entrypoints=websecure' \\"
echo "    --label-add 'traefik.http.routers.whatsapp.tls.certresolver=letsencrypt' \\"
echo "    --label-add 'traefik.http.routers.whatsapp.tls=true' \\"
echo "    --label-add 'traefik.http.services.whatsapp.loadbalancer.server.port=3001' \\"
echo "    $SERVICE_NAME"
echo ""
echo "=========================================="
echo "⚠️  ADVERTENCIA:"
echo "=========================================="
echo "Si actualizas el servicio manualmente, EasyPanel puede"
echo "sobrescribir los cambios. Es mejor configurarlo desde"
echo "el panel de EasyPanel."
echo ""



