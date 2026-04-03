#!/bin/bash
# =====================================================
# VERIFICAR MOUNTS DEL CONTENEDOR
# =====================================================
# Este script verifica qué archivos están montados
# como bind mount en el contenedor
# =====================================================

echo "=========================================="
echo "🔍 VERIFICANDO MOUNTS DEL CONTENEDOR"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"
CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ -z "${CONTAINER_ID}" ]; then
    echo "❌ No se encontró contenedor en ejecución"
    exit 1
fi

echo "📦 Contenedor: ${CONTAINER_ID}"
echo ""

# Verificar mounts del contenedor
echo "=========================================="
echo "MOUNTS DEL CONTENEDOR:"
echo "=========================================="
docker inspect "${CONTAINER_ID}" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' | grep -E "(bind|volume)"

echo ""
echo "=========================================="
echo "VERIFICANDO ARCHIVOS EN /app/"
echo "=========================================="
echo ""

# Listar archivos en /app/
echo "📋 Archivos en /app/:"
docker exec "${CONTAINER_ID}" ls -lh /app/ 2>/dev/null | grep -E "(dashboard|supabase)" || echo "   (No se encontraron archivos)"

echo ""
echo "=========================================="
echo "VERIFICANDO UBICACIÓN DE supabase-client.js"
echo "=========================================="
echo ""

# Buscar supabase-client.js en el contenedor
echo "🔍 Buscando supabase-client.js en el contenedor..."
docker exec "${CONTAINER_ID}" find /app -name "supabase-client.js" -type f 2>/dev/null | while read file; do
    echo "   Encontrado: ${file}"
    echo "   Tamaño: $(docker exec "${CONTAINER_ID}" stat -c%s "${file}" 2>/dev/null) bytes"
    
    # Verificar si tiene la corrección
    if docker exec "${CONTAINER_ID}" grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" "${file}" 2>/dev/null; then
        echo "   ✅ Tiene la corrección"
    else
        echo "   ❌ NO tiene la corrección"
    fi
    echo ""
done

echo "=========================================="
echo "VERIFICANDO SERVICIO DOCKER SWARM"
echo "=========================================="
echo ""

# Verificar configuración del servicio
echo "📋 Configuración de mounts del servicio:"
docker service inspect "${SERVICE_NAME}" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null | grep -E "(bind|volume)" || echo "   (No se encontraron mounts configurados)"

echo ""
