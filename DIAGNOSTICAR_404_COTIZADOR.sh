#!/bin/bash
# Script para diagnosticar el error 404 en cotizar.checkin24hs.com

echo "=========================================="
echo "🔍 DIAGNÓSTICO: Error 404 en Cotizador"
echo "=========================================="
echo ""

# 1. Verificar servicios de Docker relacionados con cotizador
echo "1️⃣ Verificando servicios Docker relacionados con cotizador..."
echo ""
docker service ls | grep -i cotizador || echo "   ⚠️  No se encontraron servicios con 'cotizador'"
echo ""

# 2. Verificar contenedores corriendo
echo "2️⃣ Verificando contenedores corriendo..."
echo ""
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -i cotizador || echo "   ⚠️  No se encontraron contenedores con 'cotizador'"
echo ""

# 3. Buscar servicios que puedan ser el cotizador (por puerto 80 o nombre)
echo "3️⃣ Buscando servicios en puerto 80..."
echo ""
docker service ls --format "{{.Name}}" | while read service; do
    PORT=$(docker service inspect $service --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}' 2>/dev/null)
    if [ "$PORT" = "80" ]; then
        echo "   📦 Servicio: $service (puerto $PORT)"
        docker service inspect $service --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep -E "traefik|domain|cotizar" || echo "      (sin etiquetas Traefik relacionadas)"
    fi
done
echo ""

# 4. Verificar configuración de Traefik para cotizar.checkin24hs.com
echo "4️⃣ Verificando configuración de Traefik..."
echo ""
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "   ⚠️  No se encontró contenedor de Traefik"
else
    echo "   ✅ Contenedor Traefik encontrado: $TRAEFIK_CONTAINER"
    echo ""
    echo "   Buscando configuración para 'cotizar' en logs de Traefik:"
    docker logs $TRAEFIK_CONTAINER --tail 200 2>&1 | grep -i "cotizar\|cotizador" | tail -10 || echo "      (no se encontraron referencias)"
fi
echo ""

# 5. Verificar si hay un servicio con dominio cotizar.checkin24hs.com
echo "5️⃣ Buscando servicios con dominio 'cotizar.checkin24hs.com'..."
echo ""
docker service ls --format "{{.Name}}" | while read service; do
    LABELS=$(docker service inspect $service --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null)
    if echo "$LABELS" | grep -qi "cotizar"; then
        echo "   📦 Servicio: $service"
        echo "$LABELS" | grep -i "traefik\|cotizar" | sed 's/^/      /'
    fi
done
echo ""

# 6. Verificar archivos dentro de contenedores que puedan ser el cotizador
echo "6️⃣ Verificando archivos en contenedores (buscando index.html o cotizador-cliente.html)..."
echo ""
docker ps --format "{{.Names}}" | while read container; do
    if docker exec $container ls /usr/share/nginx/html/index.html 2>/dev/null > /dev/null; then
        echo "   📦 Contenedor: $container"
        echo "      ✅ Tiene /usr/share/nginx/html/index.html"
        docker exec $container head -5 /usr/share/nginx/html/index.html 2>/dev/null | head -1 | sed 's/^/      /'
    fi
    if docker exec $container ls /usr/share/nginx/html/cotizador-cliente.html 2>/dev/null > /dev/null; then
        echo "      ✅ Tiene /usr/share/nginx/html/cotizador-cliente.html"
    fi
done
echo ""

# 7. Verificar red easypanel
echo "7️⃣ Verificando red easypanel..."
echo ""
if docker network ls | grep -q easypanel; then
    echo "   ✅ Red 'easypanel' existe"
    echo ""
    echo "   Servicios conectados a la red easypanel:"
    docker network inspect easypanel --format '{{range .Containers}}{{.Name}}{{"\n"}}{{end}}' 2>/dev/null | grep -i cotizador || echo "      (no se encontraron contenedores de cotizador)"
else
    echo "   ⚠️  Red 'easypanel' no existe"
fi
echo ""

# 8. Verificar DNS
echo "8️⃣ Verificando DNS para cotizar.checkin24hs.com..."
echo ""
RESOLVED_IP=$(nslookup cotizar.checkin24hs.com 2>/dev/null | grep -A 1 "Name:" | tail -1 | awk '{print $2}')
if [ -n "$RESOLVED_IP" ]; then
    echo "   ✅ DNS resuelve a: $RESOLVED_IP"
else
    echo "   ⚠️  No se pudo resolver DNS"
fi
echo ""

# 9. Resumen y recomendaciones
echo "=========================================="
echo "📋 RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""
echo "Si no se encontró el servicio del cotizador:"
echo "   1. Verifica en EasyPanel si el servicio existe"
echo "   2. Verifica el nombre del servicio (puede ser 'cotizador', 'checkin24hs_cotizador', etc.)"
echo ""
echo "Si el servicio existe pero no tiene configuración de Traefik:"
echo "   1. Ejecuta: ./CORREGIR_COTIZADOR_TRAEFIK.sh"
echo "   2. O configura manualmente las etiquetas Traefik en EasyPanel"
echo ""
echo "Si el servicio existe pero no tiene index.html:"
echo "   1. Verifica que el Dockerfile copie cotizador-cliente.html como index.html"
echo "   2. Verifica que los archivos estén en el servidor"
echo ""
echo "Para verificar en EasyPanel:"
echo "   1. Accede a EasyPanel"
echo "   2. Busca el servicio del cotizador"
echo "   3. Verifica la pestaña 'Dominios' - debe tener 'cotizar.checkin24hs.com'"
echo "   4. Verifica que el puerto interno sea 80"
echo ""
