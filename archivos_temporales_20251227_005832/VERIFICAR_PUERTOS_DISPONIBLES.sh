#!/bin/bash
# Script para verificar puertos ocupados y encontrar uno disponible para el CRM

echo "=========================================="
echo "Verificando puertos ocupados"
echo "=========================================="
echo ""

echo "1. Puertos ocupados por servicios Docker:"
echo "-------------------------------------------"
docker service ls --format "table {{.Name}}\t{{.Ports}}" | grep -E "300[0-9]|:300[0-9]"

echo ""
echo "2. Puertos ocupados por contenedores:"
echo "-------------------------------------------"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "300[0-9]|:300[0-9]"

echo ""
echo "3. Verificando puertos específicos (3000-3010):"
echo "-------------------------------------------"
for port in {3000..3010}; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo "Puerto $port: OCUPADO"
    else
        echo "Puerto $port: DISPONIBLE"
    fi
done

echo ""
echo "4. Verificando puertos en Docker Swarm:"
echo "-------------------------------------------"
docker service ls | while read line; do
    service_name=$(echo $line | awk '{print $2}')
    if [ "$service_name" != "NAME" ]; then
        ports=$(docker service inspect $service_name --format '{{range .Endpoint.Ports}}{{.PublishedPort}} {{end}}' 2>/dev/null)
        if [ ! -z "$ports" ]; then
            echo "Servicio: $service_name"
            echo "  Puertos publicados: $ports"
        fi
    fi
done

echo ""
echo "5. Buscando puerto disponible (3005-3015):"
echo "-------------------------------------------"
for port in {3005..3015}; do
    if ! netstat -tuln 2>/dev/null | grep -q ":$port " && ! ss -tuln 2>/dev/null | grep -q ":$port "; then
        # Verificar también en Docker
        docker_using=$(docker ps --format "{{.Ports}}" | grep -o ":$port->" || echo "")
        if [ -z "$docker_using" ]; then
            echo "✅ Puerto $port parece estar DISPONIBLE"
        fi
    fi
done

echo ""
echo "=========================================="
echo "Recomendación: Usar puerto 3005 o superior"
echo "=========================================="


