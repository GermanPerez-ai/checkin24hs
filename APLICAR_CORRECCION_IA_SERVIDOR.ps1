# Script PowerShell para aplicar corrección de IA en el servidor

$SERVER = "root@72.61.58.240"
$ARCHIVO_LOCAL = "whatsapp-server\whatsapp-server-baileys.js"
$ARCHIVO_SERVIDOR = "/tmp/whatsapp-server-baileys.js"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "APLICAR CORRECCIÓN DE IA EN SERVIDOR" -ForegroundColor Cyan
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
# Buscar contenedor de WhatsApp
CONTAINER_ID=\$(docker ps | grep whatsapp | grep -v nginx | awk '{print \$1}' | head -1)

if [ -z "\$CONTAINER_ID" ]; then
    echo "ERROR: No se encontro contenedor de WhatsApp"
    exit 1
fi

echo "Contenedor encontrado: \$CONTAINER_ID"
echo ""

# Crear backup
echo "Creando backup del archivo actual..."
docker exec \$CONTAINER_ID cp /app/whatsapp-server-baileys.js /app/whatsapp-server-baileys.js.backup.\$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado"
echo ""

# Copiar archivo corregido al contenedor
echo "Copiando archivo corregido al contenedor..."
docker cp ${ARCHIVO_SERVIDOR} \$CONTAINER_ID:/app/whatsapp-server-baileys.js
echo "✅ Archivo copiado"
echo ""

# Reiniciar contenedor
echo "Reiniciando contenedor..."
docker restart \$CONTAINER_ID
echo "✅ Contenedor reiniciado"
echo ""

echo "Esperando 5 segundos para que el contenedor inicie..."
sleep 5

# Verificar que está corriendo
echo "Verificando estado del contenedor..."
docker ps | grep \$CONTAINER_ID
echo ""

echo "=========================================="
echo "CORRECCIÓN APLICADA"
echo "=========================================="
echo ""
echo "Verifica los logs con:"
echo "docker logs \$CONTAINER_ID -f"
echo ""
"@

# Ejecutar script en el servidor
ssh $SERVER "bash -s" <<< $SCRIPT_SERVIDOR

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Corrección aplicada correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor Yellow
    Write-Host "1. Verifica los logs: ssh $SERVER 'docker logs \$(docker ps | grep whatsapp | grep -v nginx | awk \"{print \$1}\" | head -1) -f'"
    Write-Host "2. Envía un mensaje de prueba a Flor por WhatsApp"
    Write-Host "3. Verifica que Flor responda"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Hubo un problema al aplicar la corrección" -ForegroundColor Red
    Write-Host ""
}
