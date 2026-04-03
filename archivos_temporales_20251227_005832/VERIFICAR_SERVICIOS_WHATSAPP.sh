#!/bin/bash
# Verificar servicios de WhatsApp existentes

echo "=== Verificación de Servicios WhatsApp ==="
echo ""

echo "1️⃣ Todos los servicios Docker:"
docker service ls
echo ""

echo "2️⃣ Servicios que contienen 'whatsapp':"
docker service ls --format "{{.Name}}" | grep -i whatsapp
echo ""

echo "3️⃣ Contenedores activos en puertos 3001-3004:"
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep -E "3001|3002|3003|3004" || echo "   No hay contenedores en estos puertos"
echo ""

echo "4️⃣ Detalles de cada servicio de WhatsApp encontrado:"
for service in $(docker service ls --format "{{.Name}}" | grep -i whatsapp); do
    echo ""
    echo "📋 Servicio: $service"
    
    # Obtener puerto publicado
    PORT=$(docker service inspect $service --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{println}}{{end}}' 2>/dev/null | head -1)
    echo "   Puerto: $PORT"
    
    # Obtener estado
    STATUS=$(docker service ps $service --format "{{.CurrentState}}" | head -1)
    echo "   Estado: $STATUS"
    
    # Obtener red
    NETWORKS=$(docker service inspect $service --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
    echo "   Redes: $NETWORKS"
    
    # Obtener etiquetas Traefik
    TRAEFIK_LABELS=$(docker service inspect $service --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i traefik)
    if [ ! -z "$TRAEFIK_LABELS" ]; then
        echo "   Etiquetas Traefik:"
        echo "$TRAEFIK_LABELS" | sed 's/^/      /'
    else
        echo "   Etiquetas Traefik: ❌ No configuradas"
    fi
    
    # Obtener variables de entorno
    ENV_VARS=$(docker service inspect $service --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep -iE "INSTANCE|PORT" | head -3)
    if [ ! -z "$ENV_VARS" ]; then
        echo "   Variables relevantes:"
        echo "$ENV_VARS" | sed 's/^/      /'
    fi
done

echo ""
echo "5️⃣ Verificar puertos en uso:"
for port in 3001 3002 3003 3004; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo "   Puerto $port: ✅ En uso"
        netstat -tuln 2>/dev/null | grep ":$port " || ss -tuln 2>/dev/null | grep ":$port "
    else
        echo "   Puerto $port: ❌ No en uso"
    fi
done

echo ""
echo "=== RESUMEN ==="
echo ""
WHATSAPP_COUNT=$(docker service ls --format "{{.Name}}" | grep -i whatsapp | wc -l)
echo "Servicios de WhatsApp encontrados: $WHATSAPP_COUNT"
echo ""
echo "Configuración esperada:"
echo "  - whatsapp1 → puerto 3001"
echo "  - whatsapp2 → puerto 3002"
echo "  - whatsapp3 → puerto 3003"
echo "  - whatsapp4 → puerto 3004"
echo ""






