# Script de Backup en Google Drive para Checkin24hs
# Automático y fácil de usar

param(
    [switch]$Test,
    [switch]$Setup,
    [switch]$Auto
)

Write-Host "=== BACKUP EN GOOGLE DRIVE - CHECKIN24HS ==="
Write-Host ""

# Verificar si Google Drive está instalado
$googleDrivePath = "$env:USERPROFILE\Google Drive"
$isGoogleDriveInstalled = Test-Path $googleDrivePath

if ($isGoogleDriveInstalled) {
    Write-Host "Google Drive: INSTALADO Y DISPONIBLE"
    Write-Host "Ruta: $googleDrivePath"
} else {
    Write-Host "Google Drive: NO INSTALADO"
    Write-Host ""
    Write-Host "Para instalar Google Drive:"
    Write-Host "1. Ve a: https://www.google.com/drive/download/"
    Write-Host "2. Descarga e instala Google Drive"
    Write-Host "3. Inicia sesión con tu cuenta de Google"
    Write-Host "4. Ejecuta este script nuevamente"
    Write-Host ""
    
    $install = Read-Host "¿Quieres abrir la página de descarga? (s/n)"
    if ($install -eq "s" -or $install -eq "S") {
        Start-Process "https://www.google.com/drive/download/"
    }
    return
}

# Función para crear backup comprimido
function New-CompressedBackup {
    param([string]$SourcePath, [string]$DestinationPath)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $zipName = "Checkin24hs_Backup_$timestamp.zip"
    $zipPath = Join-Path $DestinationPath $zipName
    
    try {
        Compress-Archive -Path "$SourcePath\*" -DestinationPath $zipPath -Force
        Write-Host "Backup comprimido creado: $zipName"
        return $zipPath
    } catch {
        Write-Host "Error al comprimir: $($_.Exception.Message)"
        return $null
    }
}

# Función para subir a Google Drive
function Send-ToGoogleDrive {
    param([string]$FilePath)
    
    $destination = Join-Path $googleDrivePath "Checkin24hs_Backups"
    if (!(Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        Write-Host "Directorio creado en Google Drive: Checkin24hs_Backups"
    }
    
    $fileName = Split-Path $FilePath -Leaf
    $destFile = Join-Path $destination $fileName
    
    try {
        Copy-Item -Path $FilePath -Destination $destFile -Force
        Write-Host "Subido a Google Drive: $fileName"
        return $true
    } catch {
        Write-Host "Error al subir a Google Drive: $($_.Exception.Message)"
        return $false
    }
}

# Función para probar Google Drive
function Test-GoogleDrive {
    Write-Host "Probando Google Drive..."
    
    $testFile = Join-Path $env:TEMP "test_google_drive.txt"
    "Test backup - $(Get-Date)" | Out-File -FilePath $testFile
    
    $testPath = Join-Path $googleDrivePath "Checkin24hs_Backups"
    if (!(Test-Path $testPath)) {
        New-Item -ItemType Directory -Path $testPath -Force | Out-Null
    }
    
    $testDest = Join-Path $testPath "test_backup.txt"
    try {
        Copy-Item -Path $testFile -Destination $testDest -Force
        Write-Host "OK Google Drive FUNCIONA"
        Remove-Item -Path $testDest -Force
    } catch {
        Write-Host "ERROR Google Drive $($_.Exception.Message)"
    }
    
    Remove-Item -Path $testFile -Force
}

# Función para configurar backup automático
function Initialize-AutoBackup {
    Write-Host "Configurando backup automático en Google Drive..."
    
    $taskName = "Checkin24hs_GoogleDrive_Backup"
    $scriptPath = Join-Path (Get-Location) "google_drive_backup.ps1"
    
    # Crear tarea programada
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -Auto"
    $trigger = New-ScheduledTaskTrigger -Daily -At 9:00AM
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
    
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Description "Backup automático de Checkin24hs en Google Drive"
        Write-Host "Backup automático configurado para ejecutarse diariamente a las 9:00 AM"
    } catch {
        Write-Host "Error al configurar backup automático: $($_.Exception.Message)"
    }
}

# Función principal de backup
function Start-GoogleDriveBackup {
    Write-Host "Iniciando backup en Google Drive..."
    
    # Obtener el último backup local
    $backupPath = ".\backups"
    $latestBackup = Get-ChildItem -Path $backupPath -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
    
    if (!$latestBackup) {
        Write-Host "No se encontraron backups locales. Ejecutando backup primero..."
        & ".\backup_script.ps1"
        $latestBackup = Get-ChildItem -Path $backupPath -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
    }
    
    if (!$latestBackup) {
        Write-Host "Error: No se pudo crear backup local"
        return
    }
    
    $backupSource = $latestBackup.FullName
    
    # Crear backup comprimido
    $tempDir = Join-Path $env:TEMP "Checkin24hs_GoogleDrive_Backup"
    if (!(Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    $compressedPath = New-CompressedBackup -SourcePath $backupSource -DestinationPath $tempDir
    if (!$compressedPath) {
        Write-Host "Error al comprimir backup"
        return
    }
    
    # Subir a Google Drive
    $uploadSuccess = Send-ToGoogleDrive -FilePath $compressedPath
    
    # Limpiar archivos temporales
    if (Test-Path $compressedPath) {
        Remove-Item -Path $compressedPath -Force
    }
    
    if ($uploadSuccess) {
        Write-Host "Backup en Google Drive completado exitosamente!"
        Write-Host "Puedes encontrar tu backup en: $googleDrivePath\Checkin24hs_Backups"
    } else {
        Write-Host "Error al subir backup a Google Drive"
    }
}

# Ejecutar según parámetros
if ($Test) {
    Test-GoogleDrive
} elseif ($Setup) {
    Initialize-AutoBackup
} elseif ($Auto) {
    Start-GoogleDriveBackup
} else {
    Write-Host "Opciones disponibles:"
    Write-Host "1. Probar Google Drive (. -Test)"
    Write-Host "2. Configurar backup automático (. -Setup)"
    Write-Host "3. Ejecutar backup ahora (. -Auto)"
    Write-Host ""
    
    $option = Read-Host "Selecciona una opción (1-3)"
    
    switch ($option) {
        "1" { Test-GoogleDrive }
        "2" { Initialize-AutoBackup }
        "3" { Start-GoogleDriveBackup }
        default { Write-Host "Opción no válida" }
    }
}
