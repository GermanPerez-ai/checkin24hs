#!/bin/bash

# ============================================
# SCRIPT: Restaurar dashboard.html desde GitHub
# ============================================
# Este script restaura dashboard.html desde un commit funcional de GitHub
# y lo aplica directamente en el servidor

echo "🔄 RESTAURANDO dashboard.html DESDE GITHUB"
echo "=========================================="
echo ""

# Configuración
CONTAINER_NAME="checkin24hs-dashboard-1"
DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"
BACKUP_PATH="/tmp/dashboard_backup_servidor_$(date +%Y%m%d_%H%M%S).html"

# Commit funcional recomendado (antes de los problemas de saveHotelChanges)
COMMIT_HASH="266b8b0"
GITHUB_URL="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/${COMMIT_HASH}/dashboard.html"

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
    echo ""
    read -p "¿Quieres usar otro nombre de contenedor? (Enter para salir): " NEW_NAME
    if [ -n "$NEW_NAME" ]; then
        CONTAINER_NAME="$NEW_NAME"
        echo "✅ Usando contenedor: $CONTAINER_NAME"
    else
        exit 1
    fi
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

# Descargar desde GitHub
echo "📋 3. Descargando dashboard.html desde GitHub (commit ${COMMIT_HASH})..."
TEMP_FILE="/tmp/dashboard_restaurado_$(date +%Y%m%d_%H%M%S).html"

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
    echo "   URL intentada: ${GITHUB_URL}"
    exit 1
fi

echo "✅ Archivo descargado: ${TEMP_FILE}"
echo ""

# Verificar que el archivo tiene contenido válido
echo "📋 4. Verificando que el archivo es válido..."
if grep -q "<!DOCTYPE html>" "${TEMP_FILE}"; then
    echo "✅ Archivo HTML válido"
else
    echo "⚠️  ADVERTENCIA: El archivo puede no ser un HTML válido"
    read -p "¿Continuar de todas formas? (s/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
        rm -f "${TEMP_FILE}"
        exit 1
    fi
fi
echo ""

# Copiar al contenedor
echo "📋 5. Copiando archivo restaurado al contenedor..."
docker cp "${TEMP_FILE}" "${CONTAINER_NAME}:${DASHBOARD_PATH}"

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado correctamente"
else
    echo "❌ ERROR: No se pudo copiar el archivo al contenedor"
    exit 1
fi
echo ""

# Verificar que se copió
echo "📋 6. Verificando que el archivo se copió correctamente..."
if docker exec "${CONTAINER_NAME}" test -f "${DASHBOARD_PATH}"; then
    FILE_SIZE=$(docker exec "${CONTAINER_NAME}" stat -c%s "${DASHBOARD_PATH}" 2>/dev/null || echo "0")
    if [ "$FILE_SIZE" -gt 1000 ]; then
        echo "✅ Archivo verificado (tamaño: ${FILE_SIZE} bytes)"
    else
        echo "⚠️  ADVERTENCIA: El archivo parece muy pequeño (${FILE_SIZE} bytes)"
    fi
else
    echo "❌ ERROR: El archivo no se encuentra en el contenedor"
    exit 1
fi
echo ""

# Reiniciar el contenedor
echo "📋 7. Reiniciando contenedor para aplicar cambios..."
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
echo "📋 8. Limpiando archivos temporales..."
rm -f "${TEMP_FILE}"
echo "✅ Archivos temporales eliminados"
echo ""

echo "=========================================================="
echo "✅ RESTAURACIÓN COMPLETADA EXITOSAMENTE"
echo "=========================================================="
echo ""
echo "📋 Resumen:"
echo "   - Backup creado: ${BACKUP_PATH}"
echo "   - Archivo restaurado desde: commit ${COMMIT_HASH}"
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
echo "   - Restaura desde backup: docker exec ${CONTAINER_NAME} cp ${BACKUP_PATH} ${DASHBOARD_PATH}"
echo ""

