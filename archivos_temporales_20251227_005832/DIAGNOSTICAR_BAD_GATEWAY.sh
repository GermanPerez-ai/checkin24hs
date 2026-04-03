#!/bin/bash
# Diagnosticar error Bad Gateway en servicios de WhatsApp

echo "=== Diagnóstico de Bad Gateway ==="
echo ""

# Verificar servicios
echo "1️⃣ Estado de los servicios:"
docker service ls | grep -i whatsapp
echo ""

# Verificar contenedores activos
echo "2️⃣ Contenedores activos:"
docker ps | grep -i whatsapp
echo ""

# Verificar puertos internos
echo "3️⃣ Puertos configurados en cada servicio:"
for service in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $service:"
    PORT=$(docker service inspect $service --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{println}}{{end}}' 2>/dev/null)
    echo "   Puerto: $PORT"
    
    # Verificar si el contenedor está escuchando
    CONTAINER_ID=$(docker ps --filter "name=$service" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER_ID" ]; then
        echo "   Contenedor ID: $CONTAINER_ID"
        # Verificar puertos en el contenedor
        CONTAINER_PORTS=$(docker port $CONTAINER_ID 2>/dev/null)
        if [ ! -z "$CONTAINER_PORTS" ]; then
            echo "   Puertos del contenedor: $CONTAINER_PORTS"
        fi
    fi
    echo ""
done

# Verificar red easypanel
echo "4️⃣ Red easypanel:"
for service in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    NETWORKS=$(docker service inspect $service --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if echo "$NETWORKS" | grep -q "easypanel"; then
        echo "   ✅ $service está en easypanel"
    else
        echo "   ❌ $service NO está en easypanel"
    fi
done
echo ""

# Verificar etiquetas Traefik
echo "5️⃣ Etiquetas Traefik:"
for service in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $service:"
    TRAEFIK_LABELS=$(docker service inspect $service --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik)
    if [ ! -z "$TRAEFIK_LABELS" ]; then
        echo "$TRAEFIK_LABELS" | sed 's/^/   /'
    else
        echo "   ⚠️  No hay etiquetas Traefik"
    fi
    echo ""
done

# Verificar logs de Traefik
echo "6️⃣ Últimos logs de Traefik (errores relacionados con WhatsApp):"
docker service logs traefik --tail 50 2>&1 | grep -iE "whatsapp|bad|gateway|error|502" | tail -20 || echo "   No se encontraron errores recientes"
echo ""

# Verificar logs de los servicios
echo "7️⃣ Logs de whatsapp2 (últimas 20 líneas):"
docker service logs checkin24hs_whatsapp2 --tail 20 2>&1 | tail -20
echo ""

# Verificar conectividad interna
echo "8️⃣ Probar conectividad interna:"
CONTAINER_ID=$(docker ps --filter "name=checkin24hs_whatsapp2" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "   Probando conexión al contenedor desde la red easypanel..."
    docker run --rm --network easypanel alpine/curl:latest curl -I --max-time 5 http://tasks.checkin24hs_whatsapp2:3002 2>&1 | head -5 || echo "   ❌ No se pudo conectar"
else
    echo "   ❌ No se encontró contenedor de whatsapp2"
fi
echo ""

echo "=== RESUMEN ==="
echo ""
echo "Si ves 'Bad Gateway', verifica:"
echo "   1. ✅ El servicio está corriendo (docker service ls)"
echo "   2. ✅ El servicio está en la red easypanel"
echo "   3. ✅ Las etiquetas Traefik están configuradas"
echo "   4. ✅ El puerto interno coincide (3001, 3002, 3003, 3004)"
echo "   5. ✅ El servicio está escuchando en el puerto correcto"
echo ""






