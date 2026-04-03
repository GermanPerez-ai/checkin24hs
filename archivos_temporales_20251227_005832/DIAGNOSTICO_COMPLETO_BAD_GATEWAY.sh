#!/bin/bash
# Diagnóstico completo del error Bad Gateway

echo "=== DIAGNÓSTICO COMPLETO BAD GATEWAY ==="
echo ""

# 1. Verificar servicios
echo "1️⃣ Estado de los servicios:"
docker service ls | grep whatsapp
echo ""

# 2. Verificar puertos internos
echo "2️⃣ Puertos internos de cada servicio:"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    docker service inspect $s --format 'Puerto publicado: {{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null
    docker service inspect $s --format 'Puerto objetivo: {{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null
    echo ""
done

# 3. Verificar red easypanel
echo "3️⃣ Red easypanel:"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    NET=$(docker service inspect $s --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    if echo "$NET" | grep -q easypanel; then
        echo "✅ $s está en easypanel"
    else
        echo "❌ $s NO está en easypanel"
    fi
done
echo ""

# 4. Verificar etiquetas Traefik
echo "4️⃣ Etiquetas Traefik:"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    echo "📋 $s:"
    docker service inspect $s --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | head -6
    echo ""
done

# 5. Verificar contenedores activos
echo "5️⃣ Contenedores activos:"
docker ps | grep whatsapp
echo ""

# 6. Probar conectividad interna
echo "6️⃣ Probando conectividad interna desde red easypanel:"
for s in checkin24hs_whatsapp1 checkin24hs_whatsapp2 checkin24hs_whatsapp3 checkin24hs_whatsapp4; do
    PORT=$(echo $s | sed 's/checkin24hs_whatsapp//')
    PORT=$((PORT + 3000))
    echo "   Probando $s en puerto $PORT..."
    docker run --rm --network easypanel alpine/curl:latest curl -I --max-time 5 http://tasks.$s:$PORT 2>&1 | head -3 || echo "   ❌ No se pudo conectar"
    echo ""
done

# 7. Verificar logs de Traefik
echo "7️⃣ Últimos errores de Traefik:"
docker service logs traefik --tail 100 2>&1 | grep -iE "whatsapp|502|bad|gateway|error" | tail -20 || echo "   No se encontraron errores específicos"
echo ""

# 8. Verificar configuración de Traefik para whatsapp4
echo "8️⃣ Verificando configuración específica de whatsapp4:"
docker service inspect checkin24hs_whatsapp4 --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik
echo ""

# 9. Verificar si Traefik puede ver los servicios
echo "9️⃣ Verificando si Traefik detecta los servicios:"
docker exec $(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1) wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i whatsapp || echo "   No se encontraron routers de WhatsApp en Traefik"
echo ""

echo "=== FIN DEL DIAGNÓSTICO ==="






