#!/bin/bash

# Script completo para subir y aplicar cambios del CRM
# Ejecutar desde el servidor o desde tu máquina local con acceso SSH

SERVER_IP="72.61.58.240"
SERVER_USER="root"
SERVER_PATH="/root/checkin24hs/deploy"
LOCAL_FILE="deploy/crm.js"

echo "=== Subir y aplicar cambios del CRM ==="

# Verificar que estamos en el directorio correcto
if [ ! -f "$LOCAL_FILE" ]; then
    echo "❌ Error: No se encuentra el archivo $LOCAL_FILE"
    echo "Asegúrate de estar en el directorio raíz del proyecto"
    exit 1
fi

# Si estamos en el servidor, copiar directamente
if [ "$(hostname)" = "srv1152402" ] || [ -f "/root/checkin24hs/deploy/crm.js" ]; then
    echo "Ejecutando en el servidor, copiando directamente..."
    cp "$LOCAL_FILE" "$SERVER_PATH/crm.js"
    chmod +x "$SERVER_PATH/APLICAR_CAMBIOS_CRM_SERVIDOR.sh"
    "$SERVER_PATH/APLICAR_CAMBIOS_CRM_SERVIDOR.sh"
else
    # Si estamos en local, subir por SCP y luego ejecutar script remoto
    echo "1. Subiendo archivo al servidor..."
    scp "$LOCAL_FILE" "${SERVER_USER}@${SERVER_IP}:${SERVER_PATH}/crm.js"
    
    if [ $? -eq 0 ]; then
        echo "✅ Archivo subido correctamente"
        
        echo ""
        echo "2. Aplicando cambios en el servidor..."
        ssh "${SERVER_USER}@${SERVER_IP}" "cd $SERVER_PATH && chmod +x APLICAR_CAMBIOS_CRM_SERVIDOR.sh && ./APLICAR_CAMBIOS_CRM_SERVIDOR.sh"
    else
        echo "❌ Error al subir el archivo"
        exit 1
    fi
fi

echo ""
echo "=== Proceso completado ==="


















