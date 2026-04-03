#!/bin/bash
# Script completo para verificar y crear configuración de los 4 servicios de WhatsApp

echo "=== Verificación Completa de Servicios WhatsApp ==="
echo ""

# Configuración esperada
declare -A WHATSAPP_CONFIG=(
    ["whatsapp1"]="3001"
    ["whatsapp2"]="3002"
    ["whatsapp3"]="3003"
    ["whatsapp4"]="3004"
)

# 1. Ver todos los servicios
echo "1️⃣ Todos los servicios Docker:"
docker service ls
echo ""

# 2. Ver todos los contenedores
echo "2️⃣ Todos los contenedores activos:"
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
echo ""

# 3. Verificar cada servicio de WhatsApp
echo "3️⃣ Verificando servicios de WhatsApp..."
for service_name in "${!WHATSAPP_CONFIG[@]}"; do
    PORT=${WHATSAPP_CONFIG[$service_name]}
    echo ""
    echo "📱 $service_name (puerto $PORT):"
    
    # Buscar servicio por nombre
    SERVICE=$(docker service ls --format "{{.Name}}" | grep -iE "^${service_name}$|whatsapp.*${service_name}|${service_name}.*whatsapp" | head -1)
    
    # Buscar por puerto
    if [ -z "$SERVICE" ]; then
        CONTAINER=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep "$PORT" | awk '{print $1}' | head -1)
        if [ ! -z "$CONTAINER" ]; then
            SERVICE=$(docker inspect $CONTAINER --format '{{index .Config.Labels "com.docker.swarm.service.name"}}' 2>/dev/null)
        fi
    fi
    
    if [ ! -z "$SERVICE" ]; then
        echo "   ✅ Servicio encontrado: $SERVICE"
        
        # Ver estado
        STATUS=$(docker service ps $SERVICE --format "{{.CurrentState}}" | head -1)
        echo "   📊 Estado: $STATUS"
        
        # Ver puerto
        SERVICE_PORT=$(docker service inspect $SERVICE --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{println}}{{end}}' | grep "$PORT" | head -1)
        if [ ! -z "$SERVICE_PORT" ]; then
            echo "   🔌 Puerto: $SERVICE_PORT"
        fi
        
        # Ver red
        NETWORKS=$(docker service inspect $SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
        if echo "$NETWORKS" | grep -q "easypanel"; then
            echo "   🌐 Red: ✅ En easypanel"
        else
            echo "   🌐 Red: ⚠️  NO en easypanel"
        fi
        
        # Ver etiquetas Traefik
        TRAEFIK_LABELS=$(docker service inspect $SERVICE --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik | wc -l)
        if [ "$TRAEFIK_LABELS" -gt 0 ]; then
            echo "   🏷️  Traefik: ✅ Configurado ($TRAEFIK_LABELS etiquetas)"
        else
            echo "   🏷️  Traefik: ❌ NO configurado"
        fi
    else
        echo "   ❌ Servicio NO encontrado"
        echo "   💡 Necesitas crear el servicio en EasyPanel"
    fi
done

echo ""

# 4. Verificar puertos
echo "4️⃣ Verificando puertos 3001-3004..."
for port in 3001 3002 3003 3004; do
    CONTAINER=$(docker ps --format "{{.Names}}\t{{.Ports}}" | grep "$port")
    if [ ! -z "$CONTAINER" ]; then
        echo "   Puerto $port: ✅ $CONTAINER"
    else
        echo "   Puerto $port: ❌ No hay contenedor"
    fi
done
echo ""

# 5. Verificar archivos
echo "5️⃣ Verificando archivos de WhatsApp..."
if [ -d "/root/checkin24hs/whatsapp-server" ]; then
    echo "   ✅ Directorio whatsapp-server existe"
    if [ -f "/root/checkin24hs/whatsapp-server/whatsapp-server.js" ]; then
        echo "   ✅ Archivo whatsapp-server.js existe"
        SIZE=$(ls -lh /root/checkin24hs/whatsapp-server/whatsapp-server.js 2>/dev/null | awk '{print $5}')
        echo "   📊 Tamaño: $SIZE"
    else
        echo "   ❌ Archivo whatsapp-server.js NO existe"
    fi
else
    echo "   ❌ Directorio whatsapp-server NO existe"
fi
echo ""

# 6. Verificar DNS
echo "6️⃣ Verificando DNS..."
for i in 1 2 3 4; do
    DOMAIN="whatsapp${i}.checkin24hs.com"
    DNS_RESULT=$(nslookup $DOMAIN 2>&1 | grep -A 2 "Name:" | tail -1)
    if echo "$DNS_RESULT" | grep -q "72.61.58.240"; then
        echo "   ✅ $DOMAIN → 72.61.58.240"
    else
        echo "   ❌ $DOMAIN → NO configurado"
    fi
done
echo ""

# 7. Resumen y recomendaciones
echo "=== RESUMEN ==="
echo ""
echo "Para crear los servicios en EasyPanel:"
echo ""
for service_name in "${!WHATSAPP_CONFIG[@]}"; do
    PORT=${WHATSAPP_CONFIG[$service_name]}
    INSTANCE_NUM=$(echo $service_name | sed 's/whatsapp//')
    echo "📱 $service_name (puerto $PORT):"
    echo "   - Nombre: $service_name"
    echo "   - Source: GitHub → checkin24hs → /whatsapp-server"
    echo "   - Variables:"
    echo "     INSTANCE_NUMBER=$INSTANCE_NUM"
    echo "     PORT=$PORT"
    echo "     SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co"
    echo "     SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    echo "   - Puerto: $PORT"
    echo "   - Comando: node whatsapp-server.js"
    echo ""
done

echo "Después de crear los servicios, ejecuta:"
echo "  bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh"
echo ""

