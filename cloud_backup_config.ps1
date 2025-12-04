# Configuración de Backup en la Nube - Checkin24hs
# Configura automáticamente los servicios de nube disponibles

param(
    [switch]$Setup = $false,
    [switch]$Test = $false,
    [switch]$List = $false
)

# Configuración por defecto
$configFile = "cloud_backup_config.json"
$defaultConfig = @{
    CloudServices = @{
        GoogleDrive = @{
            Enabled = $false
            Path = "$env:USERPROFILE\Google Drive\Checkin24hs_Backups"
            AutoSync = $false
        }
        OneDrive = @{
            Enabled = $false
            Path = "$env:USERPROFILE\OneDrive\Checkin24hs_Backups"
            AutoSync = $false
        }
        Dropbox = @{
            Enabled = $false
            Path = "$env:USERPROFILE\Dropbox\Checkin24hs_Backups"
            AutoSync = $false
        }
    }
    Compression = @{
        Enabled = $true
        Level = "Optimal"
    }
    Encryption = @{
        Enabled = $false
        Password = ""
    }
    Schedule = @{
        AutoBackup = $false
        Interval = 60 # minutos
        MaxBackups = 10
    }
}

# Función para detectar servicios de nube
function Get-AvailableCloudServices {
    $services = @()
    
    # Google Drive
    $googleDrivePath = "$env:USERPROFILE\Google Drive"
    if (Test-Path $googleDrivePath) {
        $services += @{
            Name = "Google Drive"
            Path = $googleDrivePath
            Available = $true
            Installed = $true
        }
    }
    
    # OneDrive
    $oneDrivePath = "$env:USERPROFILE\OneDrive"
    if (Test-Path $oneDrivePath) {
        $services += @{
            Name = "OneDrive"
            Path = $oneDrivePath
            Available = $true
            Installed = $true
        }
    }
    
    # Dropbox
    $dropboxPath = "$env:USERPROFILE\Dropbox"
    if (Test-Path $dropboxPath) {
        $services += @{
            Name = "Dropbox"
            Path = $dropboxPath
            Available = $true
            Installed = $true
        }
    }
    
    return $services
}

# Función para cargar configuración
function Load-CloudConfig {
    if (Test-Path $configFile) {
        try {
            $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Host "Error al cargar configuración. Usando configuración por defecto."
            return $defaultConfig
        }
    } else {
        return $defaultConfig
    }
}

# Función para guardar configuración
function Save-CloudConfig {
    param([object]$Config)
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configFile -Encoding UTF8
        Write-Host "Configuración guardada en: $configFile"
        return $true
    } catch {
        Write-Host "Error al guardar configuración: $($_.Exception.Message)"
        return $false
    }
}

# Función para configurar servicios
function Setup-CloudServices {
    Write-Host "Configurando servicios de nube..."
    
    $config = Load-CloudConfig
    $availableServices = Get-AvailableCloudServices
    
    Write-Host "Servicios disponibles:"
    for ($i = 0; $i -lt $availableServices.Count; $i++) {
        $service = $availableServices[$i]
        Write-Host "$($i + 1). $($service.Name) - $($service.Path)"
    }
    
    Write-Host "`n¿Qué servicios quieres habilitar? (separar con comas, ej: 1,2)"
    $selection = Read-Host "Selección"
    
    $selectedIndices = $selection -split "," | ForEach-Object { [int]$_.Trim() - 1 }
    
    foreach ($index in $selectedIndices) {
        if ($index -ge 0 -and $index -lt $availableServices.Count) {
            $service = $availableServices[$index]
            $serviceKey = switch ($service.Name) {
                "Google Drive" { "GoogleDrive" }
                "OneDrive" { "OneDrive" }
                "Dropbox" { "Dropbox" }
            }
            
            if ($serviceKey) {
                $config.CloudServices.$serviceKey.Enabled = $true
                $config.CloudServices.$serviceKey.Path = $service.Path + "\Checkin24hs_Backups"
                
                $autoSync = Read-Host "¿Habilitar sincronización automática para $($service.Name)? (s/n)"
                $config.CloudServices.$serviceKey.AutoSync = ($autoSync -eq "s" -or $autoSync -eq "S")
                
                Write-Host "Servicio $($service.Name) configurado."
            }
        }
    }
    
    # Configurar compresión
    $compression = Read-Host "¿Habilitar compresión de backups? (s/n)"
    $config.Compression.Enabled = ($compression -eq "s" -or $compression -eq "S")
    
    # Configurar encriptación
    $encryption = Read-Host "¿Habilitar encriptación de backups? (s/n)"
    if ($encryption -eq "s" -or $encryption -eq "S") {
        $config.Encryption.Enabled = $true
        $password = Read-Host "Ingresa contraseña para encriptación" -AsSecureString
        $config.Encryption.Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    }
    
    # Configurar programación
    $autoBackup = Read-Host "¿Habilitar backup automático en la nube? (s/n)"
    if ($autoBackup -eq "s" -or $autoBackup -eq "S") {
        $config.Schedule.AutoBackup = $true
        $interval = Read-Host "Intervalo en minutos (ej: 60)"
        $config.Schedule.Interval = [int]$interval
    }
    
    Save-CloudConfig -Config $config
    Write-Host "Configuración completada!"
}

# Función para probar servicios
function Test-CloudServices {
    Write-Host "Probando servicios de nube..."
    
    $config = Load-CloudConfig
    $testFile = Join-Path $env:TEMP "test_backup.txt"
    "Test backup - $(Get-Date)" | Out-File -FilePath $testFile
    
    foreach ($serviceKey in $config.CloudServices.Keys) {
        $service = $config.CloudServices.$serviceKey
        if ($service.Enabled) {
            Write-Host "Probando $serviceKey..."
            
            $testPath = $service.Path
            if (!(Test-Path $testPath)) {
                New-Item -ItemType Directory -Path $testPath -Force | Out-Null
            }
            
            $testDest = Join-Path $testPath "test_backup.txt"
            try {
                Copy-Item -Path $testFile -Destination $testDest -Force
                Write-Host "OK $serviceKey OK"
                Remove-Item -Path $testDest -Force
            } catch {
                Write-Host "ERROR $serviceKey Error - $($_.Exception.Message)"
            }
        }
    }
    
    Remove-Item -Path $testFile -Force
}

# Función para listar configuración
function Show-CloudConfig {
    $config = Load-CloudConfig
    $availableServices = Get-AvailableCloudServices
    
    Write-Host "=== CONFIGURACIÓN DE BACKUP EN LA NUBE ==="
    Write-Host ""
    
    Write-Host "Servicios configurados:"
    foreach ($serviceKey in $config.CloudServices.Keys) {
        $service = $config.CloudServices.$serviceKey
        $status = if ($service.Enabled) { "Habilitado" } else { "Deshabilitado" }
        $autoSync = if ($service.AutoSync) { "Auto-sync: SI" } else { "Auto-sync: NO" }
        Write-Host "- $serviceKey $status ($autoSync)"
        if ($service.Enabled) {
            Write-Host "  Ruta: $($service.Path)"
        }
    }
    
    Write-Host ""
    Write-Host "Configuración general:"
    Write-Host "- Compresión: $(if ($config.Compression.Enabled) { 'SI' } else { 'NO' })"
    Write-Host "- Encriptación: $(if ($config.Encryption.Enabled) { 'SI' } else { 'NO' })"
    Write-Host "- Backup automático: $(if ($config.Schedule.AutoBackup) { 'SI' } else { 'NO' })"
    if ($config.Schedule.AutoBackup) {
        Write-Host "  Intervalo: $($config.Schedule.Interval) minutos"
    }
    
    Write-Host ""
    Write-Host "Servicios disponibles:"
    foreach ($service in $availableServices) {
        $status = if ($service.Installed) { "Instalado" } else { "No instalado" }
        Write-Host "- $($service.Name) $status"
    }
}

# Función para instalar servicios faltantes
function Install-CloudServices {
    Write-Host "Instalando servicios de nube faltantes..."
    
    $availableServices = Get-AvailableCloudServices
    $missingServices = @()
    
    # Verificar Google Drive
    if (!($availableServices | Where-Object { $_.Name -eq "Google Drive" })) {
        $missingServices += "Google Drive"
    }
    
    # Verificar OneDrive
    if (!($availableServices | Where-Object { $_.Name -eq "OneDrive" })) {
        $missingServices += "OneDrive"
    }
    
    # Verificar Dropbox
    if (!($availableServices | Where-Object { $_.Name -eq "Dropbox" })) {
        $missingServices += "Dropbox"
    }
    
    if ($missingServices.Count -gt 0) {
        Write-Host "Servicios faltantes:"
        foreach ($service in $missingServices) {
            Write-Host "- $service"
        }
        
        Write-Host "`nPara instalar:"
        Write-Host "- Google Drive: https://www.google.com/drive/download/"
        Write-Host "- OneDrive: Incluido con Windows 10/11"
        Write-Host "- Dropbox: https://www.dropbox.com/downloading"
        
        $install = Read-Host "¿Quieres abrir los enlaces de descarga? (s/n)"
        if ($install -eq "s" -or $install -eq "S") {
            Start-Process "https://www.google.com/drive/download/"
            Start-Process "https://www.dropbox.com/downloading"
        }
    } else {
        Write-Host "Todos los servicios están instalados."
    }
}

# Ejecutar según parámetros
if ($Setup) {
    Setup-CloudServices
} elseif ($Test) {
    Test-CloudServices
} elseif ($List) {
    Show-CloudConfig
} else {
    Write-Host "=== CONFIGURADOR DE BACKUP EN LA NUBE ==="
    Write-Host ""
    Write-Host "Opciones disponibles:"
    Write-Host "1. Configurar servicios (. -Setup)"
    Write-Host "2. Probar servicios (. -Test)"
    Write-Host "3. Ver configuración (. -List)"
    Write-Host "4. Instalar servicios faltantes"
    Write-Host ""
    
    $option = Read-Host "Selecciona una opción (1-4)"
    
    switch ($option) {
        '1' { Setup-CloudServices }
        '2' { Test-CloudServices }
        '3' { Show-CloudConfig }
        '4' { Install-CloudServices }
        default { Write-Host 'Opcion no valida' }
    }
}
