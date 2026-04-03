#!/bin/bash
# Script completo para buscar EasyPanel

echo "=========================================="
echo "BUSCAR EASYPANEL COMPLETO"
echo "=========================================="
echo ""

# 1. Verificar procesos relacionados con EasyPanel
echo "1. Procesos relacionados con EasyPanel:"
ps aux | grep -i easypanel | grep -v grep || echo "No se encontraron procesos"
echo ""

# 2. Verificar todos los puertos en uso
echo "2. Puertos en uso (80-9000):"
netstat -tuln | grep -E ":(80|443|3000|3006|8080|8090|8091|8092|8093|8094|8095)" | sort
echo ""

# 3. Verificar contenedores Docker con todos los detalles
echo "3. Todos los contenedores Docker con detalles:"
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}"
echo ""

# 4. Verificar servicios Docker Swarm completos
echo "4. Todos los servicios Docker Swarm:"
docker service ls
echo ""

# 5. Verificar si hay un proceso node en puertos comunes de EasyPanel
echo "5. Procesos Node.js y sus puertos:"
for port in 8080 8090 8091 8092 8093 8094 8095; do
    result=$(sudo lsof -i :$port 2>/dev/null || netstat -tulpn | grep :$port)
    if [ ! -z "$result" ]; then
        echo "Puerto $port:"
        echo "$result"
        echo ""
    fi
done

# 6. Verificar si EasyPanel está instalado como servicio systemd
echo "6. Servicios systemd relacionados con EasyPanel:"
systemctl list-units --type=service | grep -i easypanel || echo "No se encontraron servicios systemd"
echo ""

# 7. Buscar archivos de configuración de EasyPanel
echo "7. Archivos de configuración de EasyPanel:"
find /etc /opt /home /root -name "*easypanel*" -type f 2>/dev/null | head -10
echo ""

# 8. Verificar si hay un docker-compose para EasyPanel
echo "8. Archivos docker-compose relacionados:"
find / -name "*docker-compose*.yml" -o -name "*docker-compose*.yaml" 2>/dev/null | grep -i easypanel | head -5
echo ""

# 9. Verificar procesos que escuchan en puertos comunes
echo "9. Procesos escuchando en puertos comunes:"
for port in 80 443 3000 3006 8080 8090; do
    echo "Puerto $port:"
    sudo lsof -i :$port 2>/dev/null | head -3 || netstat -tulpn | grep :$port | head -2
    echo ""
done

echo "=========================================="
echo "BÚSQUEDA COMPLETADA"
echo "=========================================="
echo ""
echo "Si EasyPanel no aparece, puede que:"
echo "  1. No esté instalado"
echo "  2. Esté corriendo en otro servidor"
echo "  3. Necesite iniciarse manualmente"
echo ""
