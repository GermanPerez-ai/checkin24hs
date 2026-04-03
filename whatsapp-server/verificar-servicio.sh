#!/bin/bash
# 🔍 Script para Verificar y Diagnosticar Servicios WhatsApp

echo "=============================================================="
echo "🔍 VERIFICACIÓN DE SERVICIOS WHATSAPP"
echo "=============================================================="
echo ""

# 1. Verificar servicios Docker Swarm
echo "1️⃣  Servicios Docker Swarm:"
echo "--------------------------------------------------------------"
docker service ls | grep whatsapp
echo ""

# 2. Verificar contenedores
echo "2️⃣  Contenedores corriendo:"
echo "--------------------------------------------------------------"
docker ps | grep whatsapp
echo ""

# 3. Verificar mapeo de puertos
echo "3️⃣  Mapeo de puertos:"
echo "--------------------------------------------------------------"
echo "WhatsApp 1:"
docker service inspect checkin24hs_whatsapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{end}}' 2>/dev/null || echo "   No se pudo obtener información"
echo ""

echo "WhatsApp 2:"
docker service inspect checkin24hs_whatsapp2 --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{end}}' 2>/dev/null || echo "   No se pudo obtener información"
echo ""

echo "WhatsApp 3:"
docker service inspect checkin24hs_whatsapp3 --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{end}}' 2>/dev/null || echo "   No se pudo obtener información"
echo ""

echo "WhatsApp 4:"
docker service inspect checkin24hs_whatsapp4 --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{end}}' 2>/dev/null || echo "   No se pudo obtener información"
echo ""

# 4. Verificar puertos escuchando
echo "4️⃣  Puertos escuchando en el sistema:"
echo "--------------------------------------------------------------"
netstat -tulpn | grep -E ":(3001|3002|3003|3004)" || ss -tulpn | grep -E ":(3001|3002|3003|3004)"
echo ""

# 5. Ver logs del servicio whatsapp1
echo "5️⃣  Últimos 30 logs de WhatsApp 1:"
echo "--------------------------------------------------------------"
docker service logs checkin24hs_whatsapp --tail 30 2>&1 | tail -30
echo ""

# 6. Verificar variables de entorno del servicio
echo "6️⃣  Variables de entorno del servicio WhatsApp 1:"
echo "--------------------------------------------------------------"
docker service inspect checkin24hs_whatsapp --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep -E "(PORT|INSTANCE)" || echo "   No se encontraron variables PORT o INSTANCE"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
echo "💡 Si el puerto 3001 no está mapeado, necesitas:"
echo "   1. Ir a EasyPanel"
echo "   2. Editar el servicio 'checkin24hs_whatsapp'"
echo "   3. En 'Resources' o 'Recursos', agregar mapeo de puerto:"
echo "      - Puerto externo: 3001"
echo "      - Puerto interno: 3001"
echo "   4. Guardar y reiniciar el servicio"
echo ""
