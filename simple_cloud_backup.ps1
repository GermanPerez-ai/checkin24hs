# Script Simple de Backup en la Nube para Checkin24hs
# Soporta Google Drive, OneDrive, Dropbox

param(
    [string]$Service = "GoogleDrive",
    [switch]$Compress,
    [switch]$Test
)

Write-Host "=== BACKUP EN LA NUBE - CHECKIN24HS ==="
Write-Host ""

# Detectar servicios disponibles
$services = @()

# Google Drive
$googleDrivePath = "$env:USERPROFILE\Google Drive"
if (Test-Path $googleDrivePath) {
    $services += @{
        Name = "Google Drive"
        Path = $googleDrivePath
        Available = $true
    }
    Write-Host "Google Drive: DISPONIBLE"
} else {
    Write-Host "Google Drive: NO INSTALADO"
}

# OneDrive
$oneDrivePath = "$env:USERPROFILE\OneDrive"
if (Test-Path $oneDrivePath) {
    $services += @{
        Name = "OneDrive"
        Path = $oneDrivePath
        Available = $true
    }
    Write-Host "OneDrive: DISPONIBLE"
} else {
    Write-Host "OneDrive: NO INSTALADO"
}

# Dropbox
$dropboxPath = "$env:USERPROFILE\Dropbox"
if (Test-Path $dropboxPath) {
    $services += @{
        Name = "Dropbox"
        Path = $dropboxPath
        Available = $true
    }
    Write-Host "Dropbox: DISPONIBLE"
} else {
    Write-Host "Dropbox: NO INSTALADO"
}

Write-Host ""

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

# Función para subir a servicio de nube
function Send-ToCloud {
    param([string]$FilePath, [string]$ServiceName, [string]$ServicePath)
    
    $destination = Join-Path $ServicePath "Checkin24hs_Backups"
    if (!(Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        Write-Host "Directorio creado: $destination"
    }
    
    $fileName = Split-Path $FilePath -Leaf
    $destFile = Join-Path $destination $fileName
    
    try {
        Copy-Item -Path $FilePath -Destination $destFile -Force
        Write-Host "Subido a $ServiceName $fileName"
        return $true
    } catch {
        Write-Host "Error al subir a $ServiceName $($_.Exception.Message)"
        return $false
    }
}

# Función para probar servicios
function Test-CloudServices {
    Write-Host "Probando servicios de nube..."
    
    $testFile = Join-Path $env:TEMP "test_backup.txt"
    "Test backup - $(Get-Date)" | Out-File -FilePath $testFile
    
    foreach ($service in $services) {
        if ($service.Available) {
            Write-Host "Probando $($service.Name)..."
            
            $testPath = Join-Path $service.Path "Checkin24hs_Backups"
            if (!(Test-Path $testPath)) {
                New-Item -ItemType Directory -Path $testPath -Force | Out-Null
            }
            
            $testDest = Join-Path $testPath "test_backup.txt"
            try {
                Copy-Item -Path $testFile -Destination $testDest -Force
                Write-Host "OK $($service.Name) FUNCIONA"
                Remove-Item -Path $testDest -Force
            } catch {
                Write-Host "ERROR $($service.Name) $($_.Exception.Message)"
            }
        }
    }
    
    Remove-Item -Path $testFile -Force
}

# Función principal
function Start-CloudBackup {
    Write-Host "Iniciando backup en la nube..."
    
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
    $compressedPath = $null
    if ($Compress) {
        $tempDir = Join-Path $env:TEMP "Checkin24hs_CloudBackup"
        if (!(Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        $compressedPath = New-CompressedBackup -SourcePath $backupSource -DestinationPath $tempDir
        if (!$compressedPath) {
            Write-Host "Error al comprimir backup"
            return
        }
    }
    
    # Subir según el servicio seleccionado
    $uploadSuccess = $false
    $selectedService = $null
    
    switch ($Service.ToLower()) {
        "googledrive" {
            $selectedService = $services | Where-Object { $_.Name -eq "Google Drive" }
        }
        "onedrive" {
            $selectedService = $services | Where-Object { $_.Name -eq "OneDrive" }
        }
        "dropbox" {
            $selectedService = $services | Where-Object { $_.Name -eq "Dropbox" }
        }
        default {
            Write-Host "Servicio no reconocido. Servicios disponibles: GoogleDrive, OneDrive, Dropbox"
            return
        }
    }
    
    if ($selectedService -and $selectedService.Available) {
        $finalPath = if ($Compress) { $compressedPath } else { $backupSource }
        $uploadSuccess = Send-ToCloud -FilePath $finalPath -ServiceName $selectedService.Name -ServicePath $selectedService.Path
    } else {
        Write-Host "Servicio $Service no está disponible"
    }
    
    # Limpiar archivos temporales
    if ($Compress -and $compressedPath -and (Test-Path $compressedPath)) {
        Remove-Item -Path $compressedPath -Force
    }
    
    if ($uploadSuccess) {
        Write-Host "Backup en la nube completado exitosamente!"
    } else {
        Write-Host "Error al subir backup a la nube"
    }
}

# Ejecutar según parámetros
if ($Test) {
    Test-CloudServices
} else {
    Start-CloudBackup
}
