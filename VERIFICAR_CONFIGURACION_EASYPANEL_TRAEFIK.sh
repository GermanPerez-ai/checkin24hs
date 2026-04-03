#!/bin/bash
# Verificar cómo EasyPanel está configurando Traefik para el dominio

echo "=== VERIFICANDO CONFIGURACIÓN EASYPANEL/TRAEFIK ==="
echo ""

TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ Traefik no encontrado"
    exit 1
fi

echo "✅ Traefik: $TRAEFIK_CONTAINER"
echo ""

# 1. Ver archivos de configuración dinámica
echo "1️⃣ Archivos de configuración dinámica..."
echo "=========================================="
docker exec $TRAEFIK_CONTAINER find /etc/traefik -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | head -10

# 2. Buscar configuración de whatsapp
echo ""
echo "2️⃣ Buscando configuración de whatsapp..."
echo "=========================================="
docker exec $TRAEFIK_CONTAINER find /etc/traefik -type f -exec grep -l "whatsapp\|whatsapp.checkin24hs.com" {} \; 2>/dev/null || echo "   (no se encontró)"

# 3. Ver contenido de archivos de configuración dinámica
echo ""
echo "3️⃣ Contenido de archivos de configuración..."
echo "=========================================="
for file in $(docker exec $TRAEFIK_CONTAINER find /etc/traefik/dynamic -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | head -5); do
    echo "Archivo: $file"
    docker exec $TRAEFIK_CONTAINER cat "$file" 2>/dev/null | head -30
    echo ""
done

# 4. Ver variables de entorno de Traefik relacionadas con providers
echo ""
echo "4️⃣ Variables de entorno de Traefik..."
echo "=========================================="
docker inspect $TRAEFIK_CONTAINER --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -i "traefik\|docker\|file\|provider" | head -10

# 5. Ver logs recientes de Traefik
echo ""
echo "5️⃣ Logs recientes de Traefik..."
echo "=========================================="
docker logs $TRAEFIK_CONTAINER --tail 50 2>&1 | grep -i "whatsapp\|error\|404\|router" | tail -15

echo ""
echo "=========================================="
echo "📋 ANÁLISIS"
echo "=========================================="
echo ""
echo "Si no hay archivos de configuración dinámica:"
echo "   → EasyPanel puede estar usando otro método"
echo ""
echo "Si hay archivos pero no mencionan whatsapp:"
echo "   → El dominio no se está aplicando correctamente"
echo ""
