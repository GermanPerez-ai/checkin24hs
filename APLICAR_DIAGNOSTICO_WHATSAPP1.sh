#!/bin/bash
# Script completo para diagnosticar y solucionar whatsapp1.checkin24hs.com

echo "=== Diagnóstico Completo de whatsapp1.checkin24hs.com ==="
echo ""

# 1. Verificar DNS
echo "1️⃣ Verificando DNS..."
DNS_RESULT=$(nslookup whatsapp1.checkin24hs.com 2>&1 | grep -A 2 "Name:" | tail -1)
if echo "$DNS_RESULT" | grep -q "72.61.58.240"; then
    echo "✅ DNS configurado correctamente: $DNS_RESULT"
else
    echo "❌ DNS NO configurado o apunta a otra IP"
    echo "   Resultado: $DNS_RESULT"
    echo "   ⚠️  Necesitas agregar registro A: whatsapp1.checkin24hs.com → 72.61.58.240"
fi
echo ""

# 2. Buscar servicios de WhatsApp
echo "2️⃣ Buscando servicios de WhatsApp..."
WHATSAPP_SERVICES=$(docker service ls --format "{{.Name}}" | grep -i whatsapp)
if [ -z "$WHATSAPP_SERVICES" ]; then
    echo "⚠️  No se encontraron servicios de WhatsApp"
    echo "   Buscando contenedores..."
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -i whatsapp || echo "   No hay contenedores de WhatsApp"
else
    echo "✅ Servicios encontrados:"
    echo "$WHATSAPP_SERVICES"
fi
echo ""

# 3. Verificar puerto 3001
echo "3️⃣ Verificando puerto 3001..."
PORT_3001=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep 3001)
if [ -z "$PORT_3001" ]; then
    echo "⚠️  No hay contenedores en puerto 3001"
else
    echo "✅ Contenedor en puerto 3001:"
    echo "$PORT_3001"
fi
echo ""

# 4. Probar conexión directa
echo "4️⃣ Probando conexión directa..."
if curl -s --max-time 5 http://localhost:3001 > /dev/null 2>&1; then
    echo "✅ Puerto 3001 responde localmente"
    curl -I http://localhost:3001 2>&1 | head -3
else
    echo "❌ Puerto 3001 NO responde"
fi
echo ""

# 5. Verificar configuración de Traefik
echo "5️⃣ Verificando configuración de Traefik..."
echo "Buscando servicios con etiquetas Traefik para whatsapp1..."
docker service ls --format "{{.Name}}" | while read service; do
    TRAEFIK_LABELS=$(docker service inspect $service --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "whatsapp1\|3001")
    if [ ! -z "$TRAEFIK_LABELS" ]; then
        echo "✅ Servicio: $service"
        echo "$TRAEFIK_LABELS" | head -5
    fi
done
echo ""

# 6. Verificar logs de Traefik
echo "6️⃣ Verificando logs de Traefik (últimas 30 líneas relacionadas)..."
docker service logs traefik --tail 100 2>&1 | grep -iE "whatsapp1|3001|error" | tail -10 || echo "No se encontraron referencias en los logs"
echo ""

# 7. Resumen y recomendaciones
echo "=== RESUMEN Y RECOMENDACIONES ==="
echo ""

# Determinar qué hacer
if [ -z "$WHATSAPP_SERVICES" ] && [ -z "$PORT_3001" ]; then
    echo "❌ PROBLEMA: No hay servicio de WhatsApp corriendo"
    echo ""
    echo "📋 SOLUCIÓN:"
    echo "   1. Crear servicio de WhatsApp en EasyPanel"
    echo "   2. Configurar puerto interno: 3001"
    echo "   3. Agregar etiquetas Traefik (ver SOLUCIONAR_WHATSAPP1.md)"
elif [ ! -z "$PORT_3001" ] && [ -z "$(docker service ls --format '{{.Name}}' | xargs -I {} docker service inspect {} --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i 'whatsapp1.checkin24hs.com')" ]; then
    echo "⚠️  PROBLEMA: Servicio existe pero Traefik no está configurado"
    echo ""
    echo "📋 SOLUCIÓN:"
    SERVICE_NAME=$(docker ps --filter "publish=3001" --format "{{.Label \"com.docker.swarm.service.name\"}}" | head -1)
    if [ ! -z "$SERVICE_NAME" ]; then
        echo "   Servicio encontrado: $SERVICE_NAME"
        echo ""
        echo "   Ejecuta estos comandos:"
        echo "   docker service update \\"
        echo "     --label-add 'traefik.enable=true' \\"
        echo "     --label-add 'traefik.http.routers.whatsapp1.rule=Host(\`whatsapp1.checkin24hs.com\`)' \\"
        echo "     --label-add 'traefik.http.routers.whatsapp1.entrypoints=websecure' \\"
        echo "     --label-add 'traefik.http.routers.whatsapp1.tls.certresolver=letsencrypt' \\"
        echo "     --label-add 'traefik.http.services.whatsapp1.loadbalancer.server.port=3001' \\"
        echo "     $SERVICE_NAME"
    else
        echo "   ⚠️  No se pudo identificar el servicio automáticamente"
        echo "   Busca el servicio manualmente con: docker service ls"
    fi
else
    echo "✅ Todo parece estar configurado correctamente"
    echo "   Si aún no funciona, verifica:"
    echo "   - DNS propagado (puede tardar hasta 24 horas)"
    echo "   - Certificado SSL generado (puede tardar unos minutos)"
    echo "   - Logs de Traefik para errores"
fi
echo ""

