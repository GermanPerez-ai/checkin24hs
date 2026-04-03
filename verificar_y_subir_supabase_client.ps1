# Script para verificar y subir supabase-client.js

$SERVER = "root@72.61.58.240"
$REMOTE_DIR = "/root/checkin24hs"
$FILE = "supabase-client.js"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Verificar y Subir supabase-client.js" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el archivo existe localmente
if (-not (Test-Path $FILE)) {
    Write-Host "❌ Error: $FILE no existe en el directorio actual" -ForegroundColor Red
    exit 1
}

$localFile = Get-Item $FILE
Write-Host "✅ Archivo local encontrado:" -ForegroundColor Green
Write-Host "   Nombre: $($localFile.Name)" -ForegroundColor White
Write-Host "   Tamaño: $([math]::Round($localFile.Length / 1KB, 2)) KB" -ForegroundColor White
Write-Host "   Última modificación: $($localFile.LastWriteTime)" -ForegroundColor White
Write-Host ""

# Verificar si existe en el servidor
Write-Host "Verificando archivo en el servidor..." -ForegroundColor Yellow
$remoteCheck = ssh $SERVER "test -f $REMOTE_DIR/$FILE && echo 'EXISTS' || echo 'NOT_EXISTS'"

if ($remoteCheck -match "EXISTS") {
    Write-Host "✅ El archivo ya existe en el servidor" -ForegroundColor Green
    
    # Obtener información del archivo remoto
    $remoteInfo = ssh $SERVER "ls -lh $REMOTE_DIR/$FILE"
    Write-Host "   Información remota:" -ForegroundColor White
    Write-Host "   $remoteInfo" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "¿Deseas sobrescribirlo? (S/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    
    if ($response -ne "S" -and $response -ne "s") {
        Write-Host "Operación cancelada." -ForegroundColor Yellow
        exit 0
    }
}

# Subir el archivo
Write-Host ""
Write-Host "Subiendo $FILE al servidor..." -ForegroundColor Yellow
scp $FILE "${SERVER}:${REMOTE_DIR}/"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Archivo subido exitosamente" -ForegroundColor Green
    
    # Verificar que se subió correctamente
    Write-Host ""
    Write-Host "Verificando archivo en el servidor..." -ForegroundColor Yellow
    $remoteInfo = ssh $SERVER "ls -lh $REMOTE_DIR/$FILE"
    Write-Host "   $remoteInfo" -ForegroundColor White
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "✅ Proceso completado" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
} else {
    Write-Host "❌ Error al subir el archivo" -ForegroundColor Red
    exit 1
}

