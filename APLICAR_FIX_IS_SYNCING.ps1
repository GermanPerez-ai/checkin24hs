# Script PowerShell para aplicar fix de isSyncingAppState

$SERVER = "root@72.61.58.240"
$ARCHIVO_LOCAL = "whatsapp-server\whatsapp-server-baileys.js"
$ARCHIVO_SERVIDOR = "/tmp/whatsapp-server-baileys.js"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "APLICAR FIX: isSyncingAppState" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe
if (-not (Test-Path $ARCHIVO_LOCAL)) {
    Write-Host "ERROR: No se encuentra el archivo $ARCHIVO_LOCAL" -ForegroundColor Red
    exit 1
}

Write-Host "1. Subiendo archivo corregido al servidor..." -ForegroundColor Yellow
scp $ARCHIVO_LOCAL "${SERVER}:${ARCHIVO_SERVIDOR}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo subir el archivo" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo subido correctamente" -ForegroundColor Green
Write-Host ""

Write-Host "2. Aplicando corrección en el servidor..." -ForegroundColor Yellow
Write-Host ""

# Script para aplicar en el servidor
$SCRIPT_SERVIDOR = @"
#!/bin/bash
# Buscar servicio de WhatsApp
SERVICE_NAME=$(docker service ls | grep whatsapp | awk '{print \$2}' | head -1)

if [ -z "\$SERVICE_NAME" ]; then
    echo "ERROR: No se encontro servicio de WhatsApp"
    exit 1
fi

echo "Servicio encontrado: \$SERVICE_NAME"
echo ""

# Buscar contenedor actual
CONTAINER_ID=\$(docker ps | grep whatsapp | grep -v nginx | awk '{print \$1}' | head -1)

if [ -z "\$CONTAINER_ID" ]; then
    echo "⚠️ No hay contenedor corriendo. El servicio creará uno nuevo."
else
    echo "Contenedor actual: \$CONTAINER_ID"
    echo ""
    
    # Crear backup
    echo "Creando backup del archivo actual..."
    docker exec \$CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.\$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup creado"
    echo ""
    
    # Copiar archivo corregido
    echo "Copiando archivo corregido al contenedor..."
    docker cp ${ARCHIVO_SERVIDOR} \$CONTAINER_ID:/app/whatsapp-server-baileys.js
    echo "✅ Archivo copiado"
    echo ""
fi

# Reiniciar servicio (esto aplicará el fix a todos los contenedores)
echo "Reiniciando servicio..."
docker service update --force \$SERVICE_NAME
echo "✅ Servicio reiniciado"
echo ""

echo "Esperando 10 segundos para que el servicio inicie..."
sleep 10

# Verificar que está corriendo
echo "Verificando estado del servicio..."
docker service ps \$SERVICE_NAME --no-trunc | head -3
echo ""

# Verificar que la variable está definida
echo "Verificando que la corrección se aplicó..."
NEW_CONTAINER=\$(docker ps | grep whatsapp | grep -v nginx | awk '{print \$1}' | head -1)
if [ -n "\$NEW_CONTAINER" ]; then
    echo "Nuevo contenedor: \$NEW_CONTAINER"
    echo ""
    echo "Verificando variable isSyncingAppState:"
    docker exec \$NEW_CONTAINER grep -A 1 "let isSyncingAppState" /app/whatsapp-server-baileys.js
    if [ \$? -eq 0 ]; then
        echo "✅ Corrección aplicada correctamente"
    else
        echo "⚠️ No se encontró la variable. Verifica el archivo."
    fi
else
    echo "⚠️ No se encontró contenedor corriendo. Espera unos segundos más."
fi
echo ""

echo "=========================================="
echo "FIX APLICADO"
echo "=========================================="
echo ""
echo "Verifica los logs con:"
echo "docker logs -f \$(docker ps | grep whatsapp | grep -v nginx | awk '{print \$1}' | head -1)"
echo ""
"@

# Ejecutar script en el servidor
ssh $SERVER "bash -s" <<< $SCRIPT_SERVIDOR

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Fix aplicado correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor Yellow
    Write-Host "1. Verifica los logs del servicio"
    Write-Host "2. El error 'isSyncingAppState is not defined' debería estar resuelto"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Hubo un problema al aplicar el fix" -ForegroundColor Red
    Write-Host ""
}
