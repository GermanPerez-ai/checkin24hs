#!/bin/bash

# ============================================
# SCRIPT: Aplicar Corrección INMEDIATA de saveHotelChanges
# ============================================
# Este script aplica la corrección directamente en el servidor
# usando sed para cambiar la declaración problemática

echo "🚨 APLICANDO CORRECCIÓN INMEDIATA DE saveHotelChanges"
echo "======================================================"
echo ""

# Configuración
CONTAINER_NAME="checkin24hs-dashboard-1"
DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"
BACKUP_PATH="/tmp/dashboard_backup_$(date +%Y%m%d_%H%M%S).html"

# Verificar que el contenedor existe
echo "📋 1. Verificando contenedor..."
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ ERROR: Contenedor '${CONTAINER_NAME}' no encontrado"
    echo ""
    echo "💡 Contenedores disponibles:"
    docker ps --format '{{.Names}}' | grep -i dashboard || echo "   (ninguno encontrado)"
    echo ""
    echo "💡 Contenedores con 'checkin24hs':"
    docker ps --format '{{.Names}}' | grep -i checkin24hs || echo "   (ninguno encontrado)"
    exit 1
fi

echo "✅ Contenedor encontrado: ${CONTAINER_NAME}"
echo ""

# Hacer backup
echo "📋 2. Creando backup del archivo actual..."
docker exec "${CONTAINER_NAME}" cp "${DASHBOARD_PATH}" "${BACKUP_PATH}" 2>/dev/null || {
    echo "⚠️  No se pudo crear backup en el contenedor, continuando..."
}
echo "✅ Backup creado: ${BACKUP_PATH}"
echo ""

# Descargar el archivo corregido desde GitHub
echo "📋 3. Descargando archivo corregido desde GitHub..."
TEMP_FILE="/tmp/dashboard_corregido_$(date +%Y%m%d_%H%M%S).html"

# URL del archivo en GitHub (rama main)
GITHUB_URL="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"

if command -v curl &> /dev/null; then
    curl -s -o "${TEMP_FILE}" "${GITHUB_URL}"
elif command -v wget &> /dev/null; then
    wget -q -O "${TEMP_FILE}" "${GITHUB_URL}"
else
    echo "❌ ERROR: No se encontró curl ni wget para descargar el archivo"
    exit 1
fi

if [ ! -f "${TEMP_FILE}" ] || [ ! -s "${TEMP_FILE}" ]; then
    echo "❌ ERROR: No se pudo descargar el archivo desde GitHub"
    exit 1
fi

echo "✅ Archivo descargado: ${TEMP_FILE}"
echo ""

# Verificar que el archivo contiene la corrección
echo "📋 4. Verificando que el archivo contiene la corrección..."
if grep -q "if (!window.saveHotelChanges)" "${TEMP_FILE}"; then
    echo "✅ Corrección encontrada en el archivo (función anónima)"
else
    echo "⚠️  ADVERTENCIA: No se encontró la corrección esperada"
    echo "   Verificando otras posibles correcciones..."
    if grep -q "window\.saveHotelChanges" "${TEMP_FILE}"; then
        echo "   ✅ window.saveHotelChanges encontrado"
    else
        echo "   ❌ No se encontró ninguna corrección"
        exit 1
    fi
fi
echo ""

# Copiar el archivo al contenedor
echo "📋 5. Copiando archivo corregido al contenedor..."
docker cp "${TEMP_FILE}" "${CONTAINER_NAME}:${DASHBOARD_PATH}"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
else
    echo "❌ ERROR: No se pudo copiar el archivo al contenedor"
    exit 1
fi
echo ""

# Verificar que el archivo se copió correctamente
echo "📋 6. Verificando que el archivo se copió correctamente..."
if docker exec "${CONTAINER_NAME}" grep -q "if (!window.saveHotelChanges)" "${DASHBOARD_PATH}"; then
    echo "✅ Corrección verificada en el contenedor (función anónima)"
elif docker exec "${CONTAINER_NAME}" grep -q "window\.saveHotelChanges" "${DASHBOARD_PATH}"; then
    echo "✅ window.saveHotelChanges encontrado en el contenedor"
else
    echo "❌ ERROR: La corrección no se aplicó correctamente"
    exit 1
fi
echo ""

# Verificar que NO hay declaraciones duplicadas
echo "📋 7. Verificando que NO hay declaraciones duplicadas..."
DUPLICADAS=$(docker exec "${CONTAINER_NAME}" grep -c "function saveHotelChanges\|async function saveHotelChanges" "${DASHBOARD_PATH}" 2>/dev/null || echo "0")
if [ "$DUPLICADAS" -gt 0 ]; then
    echo "⚠️  ADVERTENCIA: Se encontraron $DUPLICADAS declaraciones de función saveHotelChanges"
    echo "   Esto puede causar el error 'already declared'"
    echo "   Verificando si son declaraciones problemáticas..."
else
    echo "✅ No se encontraron declaraciones de función duplicadas"
fi
echo ""

# Reiniciar el contenedor
echo "📋 8. Reiniciando contenedor para aplicar cambios..."
docker restart "${CONTAINER_NAME}"
echo "✅ Contenedor reiniciado"
echo ""
echo "⏳ Esperando 5 segundos para que el contenedor se inicie..."
sleep 5

# Verificar que el contenedor está corriendo
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ Contenedor está corriendo"
else
    echo "⚠️  ADVERTENCIA: El contenedor no está corriendo después del reinicio"
    echo "   Verificando logs..."
    docker logs "${CONTAINER_NAME}" --tail 20
fi
echo ""

# Limpiar archivo temporal
echo "📋 9. Limpiando archivos temporales..."
rm -f "${TEMP_FILE}"
echo "✅ Archivos temporales eliminados"
echo ""

echo "=========================================================="
echo "✅ CORRECCIÓN APLICADA EXITOSAMENTE"
echo "=========================================================="
echo ""
echo "📋 Resumen:"
echo "   - Backup creado: ${BACKUP_PATH}"
echo "   - Archivo actualizado: ${DASHBOARD_PATH}"
echo "   - Contenedor: ${CONTAINER_NAME}"
echo ""
echo "🔍 Próximos pasos:"
echo "   1. Abre el dashboard en el navegador"
echo "   2. Presiona Ctrl+F5 para limpiar caché"
echo "   3. Abre la consola (F12) y verifica que NO haya el error:"
echo "      'Identifier saveHotelChanges has already been declared'"
echo "   4. Intenta iniciar sesión"
echo ""
echo "💡 Si el error persiste:"
echo "   - Verifica que el contenedor esté corriendo: docker ps | grep dashboard"
echo "   - Revisa los logs: docker logs ${CONTAINER_NAME}"
echo "   - Verifica el archivo: docker exec ${CONTAINER_NAME} grep -n 'saveHotelChanges' ${DASHBOARD_PATH} | head -5"
echo ""

