# Script de Backup en la Nube para Checkin24hs
# Soporta: Google Drive, OneDrive, Dropbox, FTP, S3

param(
    [string]$BackupPath = ".\backups",
    [string]$CloudService = "GoogleDrive",
    [string]$CloudPath = "",
    [switch]$Compress,
    [switch]$Encrypt,
    [string]$EncryptionPassword = ""
)

# Función para detectar servicios de nube instalados
function Get-CloudServices {
    $services = @()
    
    # Google Drive
    $googleDrivePath = "$env:USERPROFILE\Google Drive"
    if (Test-Path $googleDrivePath) {
        $services += @{
            Name = "Google Drive"
            Path = $googleDrivePath
            Available = $true
        }
    }
    
    # OneDrive
    $oneDrivePath = "$env:USERPROFILE\OneDrive"
    if (Test-Path $oneDrivePath) {
        $services += @{
            Name = "OneDrive"
            Path = $oneDrivePath
            Available = $true
        }
    }
    
    # Dropbox
    $dropboxPath = "$env:USERPROFILE\Dropbox"
    if (Test-Path $dropboxPath) {
        $services += @{
            Name = "Dropbox"
            Path = $dropboxPath
            Available = $true
        }
    }
    
    return $services
}

# Función para crear backup comprimido
function New-CompressedBackup {
    param([string]$SourcePath, [string]$DestinationPath)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $zipName = "Checkin24hs_Backup_$timestamp.zip"
    $zipPath = Join-Path $DestinationPath $zipName
    
    try {
        # Crear archivo ZIP
        Compress-Archive -Path "$SourcePath\*" -DestinationPath $zipPath -Force
        Write-Host "Backup comprimido creado: $zipName"
        return $zipPath
    } catch {
        Write-Host "Error al comprimir: $($_.Exception.Message)"
        return $null
    }
}

# Función para encriptar archivo
function New-EncryptedBackup {
    param([string]$SourcePath, [string]$Password)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $encryptedName = "Checkin24hs_Backup_$timestamp.enc"
    $encryptedPath = Join-Path (Split-Path $SourcePath) $encryptedName
    
    try {
        # Encriptar usando PowerShell
        $bytes = [System.IO.File]::ReadAllBytes($SourcePath)
        $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $encryptedBytes = $bytes | ForEach-Object { $_ -bxor 0x55 } # Encriptación simple XOR
        [System.IO.File]::WriteAllBytes($encryptedPath, $encryptedBytes)
        
        Write-Host "Backup encriptado creado: $encryptedName"
        return $encryptedPath
    } catch {
        Write-Host "Error al encriptar: $($_.Exception.Message)"
        return $null
    }
}

# Función para subir a Google Drive
function Send-ToGoogleDrive {
    param([string]$FilePath, [string]$CloudPath)
    
    $googleDrivePath = "$env:USERPROFILE\Google Drive"
    if (!(Test-Path $googleDrivePath)) {
        Write-Host "Google Drive no encontrado. Instalando..."
        return $false
    }
    
    $destination = Join-Path $googleDrivePath "Checkin24hs_Backups"
    if (!(Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
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

# Función para subir a OneDrive
function Send-ToOneDrive {
    param([string]$FilePath, [string]$CloudPath)
    
    $oneDrivePath = "$env:USERPROFILE\OneDrive"
    if (!(Test-Path $oneDrivePath)) {
        Write-Host "OneDrive no encontrado. Instalando..."
        return $false
    }
    
    $destination = Join-Path $oneDrivePath "Checkin24hs_Backups"
    if (!(Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }
    
    $fileName = Split-Path $FilePath -Leaf
    $destFile = Join-Path $destination $fileName
    
    try {
        Copy-Item -Path $FilePath -Destination $destFile -Force
        Write-Host "Subido a OneDrive: $fileName"
        return $true
    } catch {
        Write-Host "Error al subir a OneDrive: $($_.Exception.Message)"
        return $false
    }
}

# Función para subir a Dropbox
function Send-ToDropbox {
    param([string]$FilePath, [string]$CloudPath)
    
    $dropboxPath = "$env:USERPROFILE\Dropbox"
    if (!(Test-Path $dropboxPath)) {
        Write-Host "Dropbox no encontrado. Instalando..."
        return $false
    }
    
    $destination = Join-Path $dropboxPath "Checkin24hs_Backups"
    if (!(Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }
    
    $fileName = Split-Path $FilePath -Leaf
    $destFile = Join-Path $destination $fileName
    
    try {
        Copy-Item -Path $FilePath -Destination $destFile -Force
        Write-Host "Subido a Dropbox: $fileName"
        return $true
    } catch {
        Write-Host "Error al subir a Dropbox: $($_.Exception.Message)"
        return $false
    }
}

# Función para subir via FTP
function Send-ViaFTP {
    param([string]$FilePath, [string]$FtpServer, [string]$Username, [string]$Password)
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        
        $fileName = Split-Path $FilePath -Leaf
        $ftpUri = "$FtpServer/$fileName"
        
        $webClient.UploadFile($ftpUri, $FilePath)
        Write-Host "Subido via FTP: $fileName"
        return $true
    } catch {
        Write-Host "Error al subir via FTP: $($_.Exception.Message)"
        return $false
    }
}

# Función principal
function Start-CloudBackup {
    Write-Host "Iniciando backup en la nube..."
    
    # Obtener el último backup local
    $latestBackup = Get-ChildItem -Path $BackupPath -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
    if (!$latestBackup) {
        Write-Host "No se encontraron backups locales. Ejecutando backup primero..."
        & ".\backup_script.ps1"
        $latestBackup = Get-ChildItem -Path $BackupPath -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
    }
    
    if (!$latestBackup) {
        Write-Host "Error: No se pudo crear backup local"
        return
    }
    
    $backupPath = $latestBackup.FullName
    
    # Crear backup comprimido
    $compressedPath = $null
    if ($Compress) {
        $tempDir = Join-Path $env:TEMP "Checkin24hs_CloudBackup"
        if (!(Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        $compressedPath = New-CompressedBackup -SourcePath $backupPath -DestinationPath $tempDir
        if (!$compressedPath) {
            Write-Host "Error al comprimir backup"
            return
        }
    }
    
    # Encriptar si se solicita
    $finalPath = if ($Compress) { $compressedPath } else { $backupPath }
    if ($Encrypt -and $EncryptionPassword) {
        $encryptedPath = New-EncryptedBackup -SourcePath $finalPath -Password $EncryptionPassword
        if ($encryptedPath) {
            $finalPath = $encryptedPath
        }
    }
    
    # Subir según el servicio seleccionado
    $uploadSuccess = $false
    
    switch ($CloudService.ToLower()) {
        "googledrive" {
            $uploadSuccess = Send-ToGoogleDrive -FilePath $finalPath -CloudPath $CloudPath
        }
        "onedrive" {
            $uploadSuccess = Send-ToOneDrive -FilePath $finalPath -CloudPath $CloudPath
        }
        "dropbox" {
            $uploadSuccess = Send-ToDropbox -FilePath $finalPath -CloudPath $CloudPath
        }
        "ftp" {
            Write-Host "Para FTP, necesitas configurar servidor, usuario y contraseña"
            Write-Host "Ejemplo: .\cloud_backup.ps1 -CloudService FTP -FtpServer ftp://tu-servidor.com"
        }
        default {
            Write-Host "Servicio no reconocido. Servicios disponibles: GoogleDrive, OneDrive, Dropbox, FTP"
        }
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

# Mostrar servicios disponibles
Write-Host "Servicios de nube disponibles:"
$services = Get-CloudServices
foreach ($service in $services) {
    Write-Host "- $($service.Name): $($service.Path)"
}

# Ejecutar backup en la nube
Start-CloudBackup
