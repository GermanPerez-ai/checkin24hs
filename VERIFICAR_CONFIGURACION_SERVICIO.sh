#!/bin/bash
# =====================================================
# VERIFICAR CONFIGURACIÓN DEL SERVICIO DOCKER SWARM
# =====================================================
# Este script verifica la configuración del servicio
# y muestra qué mounts están configurados
# =====================================================

echo "=========================================="
echo "🔍 VERIFICANDO CONFIGURACIÓN DEL SERVICIO"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"

# Verificar que el servicio existe
if ! docker service ls | grep -q "${SERVICE_NAME}"; then
    echo "❌ ERROR: El servicio ${SERVICE_NAME} no existe"
    exit 1
fi

echo "📦 Servicio: ${SERVICE_NAME}"
echo ""

# =====================================================
# 1. VERIFICAR MOUNTS EN LA ESPECIFICACIÓN DEL SERVICIO
# =====================================================
echo "=========================================="
echo "1. MOUNTS CONFIGURADOS EN EL SERVICIO"
echo "=========================================="
echo ""

MOUNTS=$(docker service inspect "${SERVICE_NAME}" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}}|{{.Source}}|{{.Destination}}{{"\n"}}{{end}}' 2>/dev/null)

if [ -z "${MOUNTS}" ]; then
    echo "⚠️  No se encontraron mounts configurados en el servicio"
    echo ""
    echo "Esto significa que EasyPanel no aplicó los cambios al servicio de Docker Swarm."
    echo ""
    echo "SOLUCIÓN:"
    echo "1. Ve a EasyPanel → Servicio checkin24hs_dashboard"
    echo "2. Busca un botón 'Deploy', 'Update', 'Apply' o 'Guardar'"
    echo "3. Haz clic en ese botón para aplicar los cambios"
    echo "4. O simplemente guarda la configuración nuevamente"
else
    echo "📋 Mounts encontrados:"
    echo "${MOUNTS}" | while IFS='|' read -r TYPE SOURCE DEST; do
        if [ ! -z "${TYPE}" ]; then
            echo "   ${TYPE}: ${SOURCE} -> ${DEST}"
        fi
    done
    
    # Verificar si supabase-client.js está en los mounts
    if echo "${MOUNTS}" | grep -q "supabase-client.js"; then
        echo ""
        echo "✅ supabase-client.js está configurado en el servicio"
    else
        echo ""
        echo "❌ supabase-client.js NO está configurado en el servicio"
        echo ""
        echo "SOLUCIÓN:"
        echo "1. Ve a EasyPanel → Servicio checkin24hs_dashboard"
        echo "2. Verifica que el bind mount de supabase-client.js esté guardado"
        echo "3. Busca un botón 'Deploy', 'Update', 'Apply' o 'Guardar'"
        echo "4. Haz clic en ese botón para aplicar los cambios"
    fi
fi

echo ""

# =====================================================
# 2. VERIFICAR MOUNTS EN EL CONTENEDOR ACTUAL
# =====================================================
echo "=========================================="
echo "2. MOUNTS EN EL CONTENEDOR ACTUAL"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ -z "${CONTAINER_ID}" ]; then
    echo "⚠️  No se encontró contenedor en ejecución"
else
    echo "📦 Contenedor: ${CONTAINER_ID}"
    echo ""
    
    CONTAINER_MOUNTS=$(docker inspect "${CONTAINER_ID}" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}|{{.Destination}}{{"\n"}}{{end}}{{end}}' 2>/dev/null)
    
    if [ -z "${CONTAINER_MOUNTS}" ]; then
        echo "⚠️  No se encontraron bind mounts en el contenedor"
    else
        echo "📋 Bind mounts en el contenedor:"
        echo "${CONTAINER_MOUNTS}" | while IFS='|' read -r SOURCE DEST; do
            if [ ! -z "${SOURCE}" ]; then
                echo "   ${SOURCE} -> ${DEST}"
            fi
        done
        
        # Verificar si supabase-client.js está montado
        if echo "${CONTAINER_MOUNTS}" | grep -q "supabase-client.js"; then
            echo ""
            echo "✅ supabase-client.js está montado en el contenedor"
        else
            echo ""
            echo "❌ supabase-client.js NO está montado en el contenedor"
        fi
    fi
fi

echo ""

# =====================================================
# 3. COMPARAR CONFIGURACIÓN
# =====================================================
echo "=========================================="
echo "3. COMPARACIÓN"
echo "=========================================="
echo ""

if [ ! -z "${MOUNTS}" ] && echo "${MOUNTS}" | grep -q "supabase-client.js"; then
    if [ ! -z "${CONTAINER_MOUNTS}" ] && echo "${CONTAINER_MOUNTS}" | grep -q "supabase-client.js"; then
        echo "✅ Todo está correcto: el mount está configurado y activo"
    else
        echo "⚠️  El mount está configurado en el servicio pero NO en el contenedor"
        echo ""
        echo "SOLUCIÓN: Reinicia el servicio para que se cree un nuevo contenedor:"
        echo "   docker service update --force ${SERVICE_NAME}"
    fi
else
    echo "❌ El mount NO está configurado en el servicio"
    echo ""
    echo "SOLUCIÓN:"
    echo "1. Ve a EasyPanel → Servicio checkin24hs_dashboard"
    echo "2. Verifica que el bind mount de supabase-client.js esté guardado"
    echo "3. Busca y haz clic en 'Deploy', 'Update', 'Apply' o 'Guardar'"
    echo "4. Espera a que EasyPanel actualice el servicio"
fi

echo ""
