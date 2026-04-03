#!/bin/bash

# Script para verificar DNS y configuración de Traefik para CRM

SERVICE_NAME="checkin24hs_crm"

echo "=== Verificando DNS y Traefik para CRM ==="

# 1. Verificar IP del servidor
echo ""
echo "1. IP pública del servidor:"
curl -s ifconfig.me || echo "No se pudo obtener IP pública"
echo ""

# 2. Verificar configuración de Traefik en el servicio
echo "2. Configuración de Traefik en el servicio CRM:"
docker service inspect $SERVICE_NAME --format '{{json .Spec.Labels}}' | grep -i traefik || echo "No se encontraron etiquetas de Traefik"

# 3. Verificar si el dominio resuelve
echo ""
echo "3. Verificando resolución DNS:"
nslookup crm.checkin24hs.com 2>&1 | head -10 || echo "El dominio no resuelve (esto es normal si no está configurado)"

# 4. Ver logs de Traefik relacionados con CRM
echo ""
echo "4. Logs de Traefik (últimas 30 líneas):"
docker service logs traefik --tail 30 2>&1 | grep -i crm || echo "No se encontraron referencias a CRM en los logs de Traefik"

# 5. Ver configuración de red del servicio
echo ""
echo "5. Redes del servicio CRM:"
docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

# 6. Ver puertos expuestos
echo ""
echo "6. Puertos del servicio:"
docker service inspect $SERVICE_NAME --format '{{json .Endpoint.Ports}}' | jq '.' 2>/dev/null || docker service inspect $SERVICE_NAME --format '{{json .Endpoint.Ports}}'

echo ""
echo "=== Verificación completada ==="
echo ""
echo "Si el DNS no está configurado, necesitas:"
echo "  1. Agregar registro A o CNAME en tu proveedor de DNS"
echo "  2. Apuntar crm.checkin24hs.com a la IP del servidor"
echo "  3. Esperar 5-15 minutos para propagación DNS"






