#!/bin/bash
# Verificar servicios activos y crear configuración para WhatsApp1

echo "=== Verificando Servicios Activos ==="
echo ""

# 1. Ver todos los servicios
echo "📋 Todos los servicios Docker:"
docker service ls
echo ""

# 2. Ver todos los contenedores
echo "📋 Todos los contenedores activos:"
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
echo ""

# 3. Buscar cualquier cosa relacionada con WhatsApp
echo "🔍 Buscando referencias a WhatsApp..."
docker service ls --format "{{.Name}}" | grep -i whatsapp || echo "   No hay servicios con 'whatsapp'"
docker ps --format "{{.Names}}" | grep -i whatsapp || echo "   No hay contenedores con 'whatsapp'"
echo ""

# 4. Verificar puertos 3001-3004
echo "🔍 Verificando puertos 3001-3004..."
for port in 3001 3002 3003 3004; do
    CONTAINER=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep $port)
    if [ ! -z "$CONTAINER" ]; then
        echo "   Puerto $port: $CONTAINER"
    else
        echo "   Puerto $port: ❌ No hay contenedor"
    fi
done
echo ""

# 5. Verificar si existe el directorio whatsapp-server
echo "📁 Verificando archivos de WhatsApp..."
if [ -d "/root/checkin24hs/whatsapp-server" ]; then
    echo "   ✅ Directorio whatsapp-server existe"
    if [ -f "/root/checkin24hs/whatsapp-server/whatsapp-server.js" ]; then
        echo "   ✅ Archivo whatsapp-server.js existe"
        echo "   📊 Tamaño: $(ls -lh /root/checkin24hs/whatsapp-server/whatsapp-server.js | awk '{print $5}')"
    else
        echo "   ❌ Archivo whatsapp-server.js NO existe"
    fi
else
    echo "   ❌ Directorio whatsapp-server NO existe"
fi
echo ""

# 6. Verificar red easypanel
echo "🌐 Verificando red easypanel..."
docker network inspect easypanel --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | head -20
echo ""

# 7. Resumen y recomendaciones
echo "=== RESUMEN ==="
echo ""
echo "Para crear el servicio WhatsApp1:"
echo ""
echo "1. Ve a EasyPanel → New Service"
echo "2. Nombre: whatsapp1"
echo "3. Source: GitHub → checkin24hs → /whatsapp-server"
echo "4. Variables:"
echo "   INSTANCE_NUMBER=1"
echo "   PORT=3001"
echo "   SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co"
echo "   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
echo "5. Puerto: 3001"
echo "6. Comando: node whatsapp-server.js"
echo ""
echo "Después de crear el servicio, ejecuta:"
echo "  bash CONFIGURAR_TRAEFIK_WHATSAPP1.sh"
echo ""






