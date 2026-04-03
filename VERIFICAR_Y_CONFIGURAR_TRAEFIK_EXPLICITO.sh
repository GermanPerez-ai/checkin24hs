#!/bin/bash
# Verificar y configurar Traefik para que solo use servicios con etiquetas explícitas

echo "=========================================="
echo "🔍 Verificando configuración de Traefik"
echo "=========================================="
echo ""

# 1. Verificar contenedor de Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ No se encontró contenedor de Traefik"
    exit 1
fi

echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
echo ""

# 2. Ver configuración actual de Traefik
echo "1️⃣ Verificando configuración de Traefik..."
echo ""

# Ver si hay archivo de configuración
echo "Archivos de configuración en Traefik:"
docker exec "$TRAEFIK_CONTAINER" ls -la /etc/traefik/ 2>/dev/null || echo "No se puede acceder a /etc/traefik/"

echo ""
echo "Configuración de Traefik (si existe):"
docker exec "$TRAEFIK_CONTAINER" cat /etc/traefik/traefik.yml 2>/dev/null || echo "No hay archivo traefik.yml"

echo ""
echo "Variables de entorno de Traefik:"
docker inspect "$TRAEFIK_CONTAINER" --format '{{range $key, $value := .Config.Env}}{{println $value}}{{end}}' | grep -iE "traefik|docker|exposed" || echo "No hay variables relevantes"

echo ""
echo "2️⃣ El problema es que Traefik está creando routers automáticamente"
echo "   basándose en los nombres de los servicios Docker."
echo ""
echo "   Solución: Necesitamos deshabilitar la detección automática"
echo "   o configurar Traefik para que solo use servicios con traefik.enable=true"
echo ""

# 3. Verificar qué servicios están siendo detectados
echo "3️⃣ Verificando qué servicios Traefik está detectando..."
echo ""
echo "Servicios en la red easypanel:"
EASYPANEL_NET=$(docker network ls | grep easypanel | awk '{print $1}' | head -1)
if [ ! -z "$EASYPANEL_NET" ]; then
    docker network inspect "$EASYPANEL_NET" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | tr ' ' '\n' | grep -v "^$"
fi

echo ""
echo "4️⃣ Verificando etiquetas actuales del dashboard..."
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "5️⃣ El problema puede ser que Traefik está usando el provider Docker"
echo "   con detección automática habilitada."
echo ""
echo "   Necesitamos verificar si podemos acceder a la API de Traefik"
echo "   para ver qué routers tiene configurados:"
echo ""

# Intentar acceder a la API de Traefik (si está habilitada)
TRAEFIK_API=$(docker exec "$TRAEFIK_CONTAINER" wget -qO- http://localhost:8080/api/http/routers 2>/dev/null)

if [ ! -z "$TRAEFIK_API" ]; then
    echo "✅ API de Traefik accesible"
    echo "Routers configurados:"
    echo "$TRAEFIK_API" | head -50
else
    echo "⚠️  No se puede acceder a la API de Traefik (puede no estar habilitada)"
fi

echo ""
echo "=========================================="
echo "📋 Resumen y Recomendación"
echo "=========================================="
echo ""
echo "El problema es que Traefik está detectando automáticamente servicios"
echo "y creando routers basados en sus nombres."
echo ""
echo "Opciones para solucionarlo:"
echo ""
echo "1. Configurar Traefik para que solo detecte servicios con traefik.enable=true"
echo "   (Esto requiere modificar la configuración de Traefik)"
echo ""
echo "2. Usar nombres de servicios que no causen conflictos"
echo "   (Cambiar checkin24hs_dashboard a otro nombre)"
echo ""
echo "3. Verificar si EasyPanel está configurando Traefik automáticamente"
echo "   y deshabilitar esa configuración"
echo ""
echo "4. Acceder directamente al dashboard por IP:puerto en lugar de usar Traefik"
echo ""
echo "¿Quieres que verifiquemos la configuración de EasyPanel?"
echo ""
