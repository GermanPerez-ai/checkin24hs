#!/bin/bash
# Script para diagnosticar y corregir el problema del cotizador que muestra archivo obsoleto

echo "🔍 Diagnóstico del Cotizador - Archivo Obsoleto"
echo "================================================"
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar servicios del cotizador
echo "1️⃣ Buscando servicios del cotizador..."
COTIZADOR_SERVICE=$(docker service ls --format "{{.Name}}" | grep -i cotizador | head -1)

if [ -z "$COTIZADOR_SERVICE" ]; then
    echo -e "${RED}❌ No se encontró servicio del cotizador${NC}"
    echo "   Buscando contenedores..."
    COTIZADOR_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i cotizador | head -1)
    if [ -z "$COTIZADOR_CONTAINER" ]; then
        echo -e "${RED}❌ No se encontró contenedor del cotizador${NC}"
        exit 1
    else
        echo -e "${YELLOW}⚠️  Se encontró contenedor: $COTIZADOR_CONTAINER${NC}"
        USE_CONTAINER=true
    fi
else
    echo -e "${GREEN}✅ Servicio encontrado: $COTIZADOR_SERVICE${NC}"
    USE_CONTAINER=false
fi

echo ""

# 2. Verificar qué archivo está sirviendo
echo "2️⃣ Verificando archivo que se está sirviendo..."

if [ "$USE_CONTAINER" = true ]; then
    CONTAINER_ID=$COTIZADOR_CONTAINER
else
    # Obtener ID del contenedor del servicio
    CONTAINER_ID=$(docker service ps $COTIZADOR_SERVICE --no-trunc --format "{{.Name}}" | head -1)
    if [ -z "$CONTAINER_ID" ]; then
        CONTAINER_ID=$(docker ps --format "{{.ID}}" --filter "name=$COTIZADOR_SERVICE" | head -1)
    fi
fi

if [ -z "$CONTAINER_ID" ]; then
    echo -e "${RED}❌ No se pudo obtener ID del contenedor${NC}"
    exit 1
fi

echo "   Contenedor: $CONTAINER_ID"
echo ""

# Verificar contenido del index.html en el contenedor
echo "3️⃣ Verificando contenido de index.html en el contenedor..."
INDEX_CONTENT=$(docker exec $CONTAINER_ID cat /usr/share/nginx/html/index.html 2>/dev/null | head -30)

if echo "$INDEX_CONTENT" | grep -q "TUS RESERVAS TIENEN BENEFICIOS"; then
    echo -e "${RED}❌ PROBLEMA ENCONTRADO: El contenedor está sirviendo index.html obsoleto${NC}"
    echo "   El archivo contiene 'TUS RESERVAS TIENEN BENEFICIOS' (página obsoleta)"
    PROBLEMA_ENCONTRADO=true
elif echo "$INDEX_CONTENT" | grep -q "Solicitar Cotización"; then
    echo -e "${GREEN}✅ El contenedor tiene el archivo correcto (cotizador-cliente.html)${NC}"
    PROBLEMA_ENCONTRADO=false
else
    echo -e "${YELLOW}⚠️  No se pudo determinar el contenido del archivo${NC}"
    echo "   Primeras líneas del archivo:"
    echo "$INDEX_CONTENT" | head -10
    PROBLEMA_ENCONTRADO=unknown
fi

echo ""

# 4. Verificar si existe cotizador-cliente.html en el contenedor
echo "4️⃣ Verificando si cotizador-cliente.html existe en el contenedor..."
if docker exec $CONTAINER_ID test -f /usr/share/nginx/html/cotizador-cliente.html 2>/dev/null; then
    echo -e "${GREEN}✅ cotizador-cliente.html existe en el contenedor${NC}"
else
    echo -e "${YELLOW}⚠️  cotizador-cliente.html NO existe en el contenedor${NC}"
    echo "   Esto es normal si se copió como index.html"
fi

echo ""

# 5. Verificar configuración de nginx
echo "5️⃣ Verificando configuración de nginx..."
NGINX_CONFIG=$(docker exec $CONTAINER_ID cat /etc/nginx/conf.d/default.conf 2>/dev/null)
if echo "$NGINX_CONFIG" | grep -q "index index.html"; then
    echo -e "${GREEN}✅ Nginx está configurado para servir index.html${NC}"
else
    echo -e "${YELLOW}⚠️  Configuración de nginx no encontrada o diferente${NC}"
fi

echo ""

# 6. Verificar bind mounts (si los hay)
echo "6️⃣ Verificando bind mounts..."
if [ "$USE_CONTAINER" = false ]; then
    MOUNTS=$(docker service inspect $COTIZADOR_SERVICE --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}}:{{.Target}} {{end}}' 2>/dev/null)
    if [ -n "$MOUNTS" ] && [ "$MOUNTS" != " " ]; then
        echo -e "${YELLOW}⚠️  Bind mounts encontrados:${NC}"
        echo "   $MOUNTS"
        echo "   Verifica que no apunten a un directorio con index.html obsoleto"
    else
        echo -e "${GREEN}✅ No hay bind mounts configurados${NC}"
    fi
else
    MOUNTS=$(docker inspect $CONTAINER_ID --format '{{range .Mounts}}{{.Source}}:{{.Target}} {{end}}' 2>/dev/null)
    if [ -n "$MOUNTS" ] && [ "$MOUNTS" != " " ]; then
        echo -e "${YELLOW}⚠️  Bind mounts encontrados:${NC}"
        echo "   $MOUNTS"
    else
        echo -e "${GREEN}✅ No hay bind mounts configurados${NC}"
    fi
fi

echo ""

# 7. Resumen y recomendaciones
echo "================================================"
echo "📋 RESUMEN Y RECOMENDACIONES"
echo "================================================"
echo ""

if [ "$PROBLEMA_ENCONTRADO" = true ]; then
    echo -e "${RED}❌ PROBLEMA CONFIRMADO:${NC}"
    echo "   El contenedor está sirviendo index.html obsoleto"
    echo ""
    echo -e "${YELLOW}🔧 SOLUCIÓN:${NC}"
    echo "   1. Ve a EasyPanel → Servicio '$COTIZADOR_SERVICE'"
    echo "   2. Ve a la pestaña 'Fuente' o 'Source'"
    echo "   3. Verifica que esté usando 'Dockerfile.cotizador'"
    echo "   4. Haz clic en 'Reconstruir' o 'Rebuild'"
    echo "   5. Espera 2-5 minutos a que termine la compilación"
    echo ""
    echo "   O desde SSH, ejecuta:"
    echo "   docker service update --force $COTIZADOR_SERVICE"
    echo ""
elif [ "$PROBLEMA_ENCONTRADO" = false ]; then
    echo -e "${GREEN}✅ El contenedor tiene el archivo correcto${NC}"
    echo ""
    echo "   Si aún ves la página obsoleta en el navegador:"
    echo "   1. Limpia la caché del navegador (Ctrl+Shift+Delete)"
    echo "   2. O abre en modo incógnito"
    echo "   3. O fuerza recarga (Ctrl+Shift+R)"
    echo ""
else
    echo -e "${YELLOW}⚠️  No se pudo determinar el problema${NC}"
    echo "   Revisa manualmente el contenido del contenedor"
    echo ""
fi

echo "================================================"
echo ""
