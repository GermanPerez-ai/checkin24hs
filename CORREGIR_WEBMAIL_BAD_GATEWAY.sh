#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 CORRIGIENDO BAD GATEWAY EN WEBMAIL"
echo "=========================================="
echo ""

# 1. Buscar servicios de webmail
echo "=== 1. Buscando servicios de webmail ==="
WEBMAIL_SERVICES=$(docker service ls --format "{{.Name}}" | grep -i "webmail\|mail")
if [ -z "$WEBMAIL_SERVICES" ]; then
    echo "⚠️ No se encontraron servicios de webmail en Docker Swarm"
    echo "Buscando contenedores de webmail..."
    docker ps -a | grep -i "webmail\|mail" || echo "No se encontraron contenedores de webmail"
else
    echo "Servicios encontrados:"
    echo "$WEBMAIL_SERVICES"
fi
echo ""

# 2. Verificar contenedores de webmail
echo "=== 2. Contenedores de webmail ==="
WEBMAIL_CONTAINERS=$(docker ps --filter "name=webmail" --format "{{.Names}}")
if [ -z "$WEBMAIL_CONTAINERS" ]; then
    echo "⚠️ No se encontraron contenedores de webmail corriendo"
    echo "Buscando todos los contenedores relacionados con mail..."
    docker ps -a | grep -i "mail" || echo "No se encontraron contenedores relacionados"
else
    echo "Contenedores encontrados:"
    for container in $WEBMAIL_CONTAINERS; do
        echo "  - $container"
        echo "    Estado: $(docker ps --filter "name=$container" --format '{{.Status}}')"
        echo "    Puertos: $(docker port $container 2>/dev/null || echo 'No expuestos')"
    done
fi
echo ""

# 3. Verificar configuración de Traefik para webmail
echo "=== 3. Configuración de Traefik para webmail ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
    echo ""
    echo "Buscando errores relacionados con webmail:"
    docker logs "$TRAEFIK_CONTAINER" --tail 100 2>&1 | grep -i "webmail\|bad.*gateway\|502" | tail -10 || echo "  No se encontraron errores específicos"
    echo ""
    echo "Buscando configuración de routing para webmail:"
    docker logs "$TRAEFIK_CONTAINER" --tail 200 2>&1 | grep -i "webmail.checkin24hs.com" | tail -5 || echo "  No se encontró configuración para webmail.checkin24hs.com"
else
    echo "❌ No se encontró contenedor de Traefik"
fi
echo ""

# 4. Verificar etiquetas de Traefik en servicios
echo "=== 4. Etiquetas de Traefik en servicios ==="
for service in $(docker service ls --format "{{.Name}}"); do
    LABELS=$(docker service inspect "$service" --format='{{range $k, $v := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep -i "webmail\|traefik" | head -5)
    if [ ! -z "$LABELS" ]; then
        echo "Servicio: $service"
        echo "$LABELS"
        echo ""
    fi
done

# 5. Verificar si hay servicios que deberían ser webmail
echo "=== 5. Todos los servicios disponibles ==="
docker service ls
echo ""

# 6. Verificar red Docker
echo "=== 6. Verificando red Docker ==="
echo "Redes disponibles:"
docker network ls | grep -E "traefik|webmail|mail|ingress"
echo ""

# 7. Probar conectividad desde Traefik
if [ ! -z "$TRAEFIK_CONTAINER" ] && [ ! -z "$WEBMAIL_CONTAINERS" ]; then
    echo "=== 7. Probando conectividad desde Traefik ==="
    FIRST_WEBMAIL=$(echo "$WEBMAIL_CONTAINERS" | head -1)
    echo "Probando conexión desde Traefik a $FIRST_WEBMAIL..."
    
    # Obtener IP del contenedor de webmail
    WEBMAIL_IP=$(docker inspect "$FIRST_WEBMAIL" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
    if [ ! -z "$WEBMAIL_IP" ]; then
        echo "IP del webmail: $WEBMAIL_IP"
        echo "Probando conexión HTTP desde Traefik..."
        docker exec "$TRAEFIK_CONTAINER" wget -q -O- --timeout=5 "http://$WEBMAIL_IP:80" 2>&1 | head -3 || echo "  No se pudo conectar"
    else
        echo "⚠️ No se pudo obtener la IP del contenedor de webmail"
    fi
fi
echo ""

# 8. Verificar puertos expuestos
echo "=== 8. Puertos expuestos en contenedores de webmail ==="
for container in $WEBMAIL_CONTAINERS; do
    echo "Contenedor: $container"
    docker port "$container" 2>/dev/null || echo "  No tiene puertos expuestos"
    echo ""
done

echo "=========================================="
echo "📋 DIAGNÓSTICO COMPLETADO"
echo "=========================================="
echo ""
echo "Posibles soluciones:"
echo ""
echo "1. Si no hay servicio de webmail:"
echo "   - Verifica si el webmail está configurado en Docker Swarm"
echo "   - O si está corriendo como contenedor independiente"
echo ""
echo "2. Si el servicio existe pero Traefik no puede conectarse:"
echo "   - Verifica que el servicio esté en la misma red que Traefik"
echo "   - Verifica las etiquetas de Traefik en el servicio"
echo "   - Verifica que el puerto configurado en Traefik sea correcto"
echo ""
echo "3. Si necesitas crear/actualizar el servicio:"
echo "   - Necesitarás las etiquetas de Traefik correctas"
echo "   - Ejemplo: traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)"
echo ""


