#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔍 DIAGNÓSTICO DE WEBMAIL"
echo "=========================================="
echo ""

# 1. Verificar servicios relacionados con webmail
echo "=== 1. Servicios relacionados con webmail ==="
docker service ls | grep -i "webmail\|mail" || echo "No se encontraron servicios de webmail"
echo ""

# 2. Verificar contenedores de webmail
echo "=== 2. Contenedores de webmail ==="
docker ps --filter "name=webmail" --format "{{.Names}} - {{.Status}}" || echo "No se encontraron contenedores de webmail"
echo ""

# 3. Verificar configuración de Traefik para webmail
echo "=== 3. Configuración de Traefik para webmail ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo ""
    echo "Buscando configuración para webmail.checkin24hs.com:"
    docker logs "$TRAEFIK_CONTAINER" --tail 200 2>&1 | grep -i "webmail" | tail -10 || echo "  No se encontraron referencias a webmail"
else
    echo "❌ No se encontró contenedor de Traefik"
fi
echo ""

# 4. Verificar servicios de Docker Swarm
echo "=== 4. Servicios de Docker Swarm ==="
docker service ls
echo ""

# 5. Verificar certificados SSL en Traefik
echo "=== 5. Verificando certificados SSL ==="
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Buscando errores de certificado en logs de Traefik:"
    docker logs "$TRAEFIK_CONTAINER" --tail 100 2>&1 | grep -i "certificate\|ssl\|tls\|webmail" | tail -10 || echo "  No se encontraron errores de certificado"
fi
echo ""

# 6. Verificar si el servicio responde en HTTP (sin SSL)
echo "=== 6. Probando conexión HTTP ==="
WEBMAIL_SERVICE=$(docker service ls | grep -i "webmail\|mail" | awk '{print $2}' | head -1)
if [ ! -z "$WEBMAIL_SERVICE" ]; then
    echo "Servicio encontrado: $WEBMAIL_SERVICE"
    WEBMAIL_CONTAINER=$(docker ps --filter "name=$WEBMAIL_SERVICE" --format "{{.Names}}" | head -1)
    if [ ! -z "$WEBMAIL_CONTAINER" ]; then
        echo "Contenedor: $WEBMAIL_CONTAINER"
        echo "Probando respuesta local:"
        docker exec "$WEBMAIL_CONTAINER" wget -q -O- http://localhost:80 2>&1 | head -5 || echo "  No responde en puerto 80"
        docker exec "$WEBMAIL_CONTAINER" wget -q -O- http://localhost:8080 2>&1 | head -5 || echo "  No responde en puerto 8080"
    fi
else
    echo "⚠️ No se encontró servicio de webmail"
fi
echo ""

# 7. Verificar configuración de red
echo "=== 7. Verificando red Docker ==="
docker network ls | grep -i "traefik\|webmail\|mail"
echo ""

# 8. Verificar etiquetas de Traefik en servicios
echo "=== 8. Etiquetas de Traefik en servicios ==="
for service in $(docker service ls --format "{{.Name}}" | grep -i "webmail\|mail"); do
    echo "Servicio: $service"
    docker service inspect "$service" --format='{{range $k, $v := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -10
    echo ""
done

echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "Si el webmail no tiene certificado SSL válido:"
echo "  1. Verifica que Traefik tenga configurado Let's Encrypt"
echo "  2. Verifica que el dominio webmail.checkin24hs.com apunte al servidor"
echo "  3. Verifica las etiquetas de Traefik en el servicio de webmail"
echo ""
echo "Si necesitas acceder temporalmente sin SSL:"
echo "  - Usa http://webmail.checkin24hs.com (si está configurado)"
echo "  - O accede directamente por IP y puerto"
echo ""


