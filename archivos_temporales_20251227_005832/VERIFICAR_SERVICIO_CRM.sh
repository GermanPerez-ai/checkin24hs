#!/bin/bash

# Script para verificar si el servicio CRM existe y su estado

echo "=== Verificando servicios CRM ==="

# Buscar servicios con "crm" en el nombre
echo ""
echo "1. Servicios con 'crm' en el nombre:"
docker service ls | grep -i crm || echo "No se encontraron servicios con 'crm'"

# Buscar servicios con "checkin24hs" en el nombre
echo ""
echo "2. Todos los servicios de checkin24hs:"
docker service ls | grep -i checkin24hs || echo "No se encontraron servicios de checkin24hs"

# Listar todos los servicios
echo ""
echo "3. Todos los servicios Docker:"
docker service ls

# Buscar contenedores con "crm" en el nombre
echo ""
echo "4. Contenedores con 'crm' en el nombre:"
docker ps -a | grep -i crm || echo "No se encontraron contenedores con 'crm'"

# Verificar si hay algún servicio reciente
echo ""
echo "5. Servicios creados recientemente:"
docker service ls --format "table {{.Name}}\t{{.CreatedAt}}\t{{.Replicas}}" | head -10

echo ""
echo "=== Verificación completada ==="
echo ""
echo "Si el servicio no aparece, puede ser que:"
echo "  1. Aún no se haya creado en EasyPanel"
echo "  2. Se esté construyendo (espera 2-5 minutos)"
echo "  3. Se haya creado con otro nombre"
echo "  4. Haya un error en la configuración"






