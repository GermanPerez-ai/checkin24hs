#!/bin/bash
# Script para verificar el estado actual de los servicios de WhatsApp

echo "=== Estado de Servicios WhatsApp ==="
echo ""

# 1. Ver servicios Docker
echo "1️⃣ Servicios Docker:"
docker service ls | grep -i whatsapp || echo "   ❌ No hay servicios de WhatsApp"
echo ""

# 2. Ver contenedores
echo "2️⃣ Contenedores activos:"
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep -i whatsapp || echo "   ❌ No hay contenedores de WhatsApp"
echo ""

# 3. Verificar puertos
echo "3️⃣ Puertos 3001-3004:"
for port in 3001 3002 3003 3004; do
    CONTAINER=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep "$port")
    if [ ! -z "$CONTAINER" ]; then
        echo "   ✅ Puerto $port: $CONTAINER"
    else
        echo "   ❌ Puerto $port: No hay contenedor"
    fi
done
echo ""

# 4. Verificar logs (si hay servicios)
echo "4️⃣ Últimos logs de servicios:"
for i in 1 2 3 4; do
    SERVICE_NAME=$(docker service ls --format "{{.Name}}" | grep -iE "^whatsapp${i}$|whatsapp.*${i}" | head -1)
    if [ ! -z "$SERVICE_NAME" ]; then
        echo "   📱 $SERVICE_NAME:"
        docker service logs $SERVICE_NAME --tail 3 2>&1 | tail -3 | sed 's/^/      /'
    fi
done
echo ""

# 5. Verificar Traefik
echo "5️⃣ Configuración Traefik:"
docker service ls --format "{{.Name}}" | grep -i whatsapp | while read service; do
    TRAEFIK_LABELS=$(docker service inspect $service --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | wc -l)
    if [ "$TRAEFIK_LABELS" -gt 0 ]; then
        echo "   ✅ $service: Traefik configurado ($TRAEFIK_LABELS etiquetas)"
    else
        echo "   ❌ $service: Traefik NO configurado"
    fi
done
echo ""

# 6. Verificar DNS
echo "6️⃣ DNS:"
for i in 1 2 3 4; do
    DOMAIN="whatsapp${i}.checkin24hs.com"
    DNS_RESULT=$(nslookup $DOMAIN 2>&1 | grep -A 2 "Name:" | tail -1)
    if echo "$DNS_RESULT" | grep -q "72.61.58.240"; then
        echo "   ✅ $DOMAIN → 72.61.58.240"
    else
        echo "   ❌ $DOMAIN → NO configurado"
    fi
done
echo ""

# 7. Resumen
echo "=== RESUMEN ==="
echo ""
WHATSAPP_COUNT=$(docker service ls --format "{{.Name}}" | grep -i whatsapp | wc -l)
if [ "$WHATSAPP_COUNT" -eq 0 ]; then
    echo "❌ No hay servicios de WhatsApp creados"
    echo ""
    echo "📋 Próximo paso: Crear los 4 servicios en EasyPanel"
    echo "   Ver: PASO_A_PASO_WHATSAPP.md"
elif [ "$WHATSAPP_COUNT" -lt 4 ]; then
    echo "⚠️  Solo $WHATSAPP_COUNT de 4 servicios creados"
    echo ""
    echo "📋 Próximo paso: Crear los servicios faltantes en EasyPanel"
else
    echo "✅ $WHATSAPP_COUNT servicios creados"
    echo ""
    echo "📋 Próximos pasos:"
    echo "   1. Verificar que todos estén corriendo (verde en EasyPanel)"
    echo "   2. Ejecutar: bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh"
    echo "   3. Configurar DNS"
fi
echo ""


