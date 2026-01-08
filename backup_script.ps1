# Script de Backup para Checkin24hs
# Autor: Asistente AI
# Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

param(
    [string]$BackupPath = ".\backups",
    [string]$ProjectPath = ".",
    [switch]$AutoBackup = $false
)

# Crear directorio de backup si no existe
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force
    Write-Host "Directorio de backup creado: $BackupPath"
}

# Obtener fecha y hora para el nombre del backup
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupFolder = Join-Path $BackupPath "backup_$timestamp"

# Crear directorio del backup
New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

# Archivos importantes a respaldar
$importantFiles = @(
    "index.html",
    "dashboard.html",
    "styles.css",
    "script.js",
    "README.md",
    "package.json",
    "requirements.txt"
)

# Copiar archivos importantes
$copiedFiles = 0
foreach ($file in $importantFiles) {
    $sourcePath = Join-Path $ProjectPath $file
    if (Test-Path $sourcePath) {
        $destPath = Join-Path $backupFolder $file
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        $copiedFiles++
        Write-Host "Copiado: $file"
    }
}

# Copiar todos los archivos HTML, CSS, JS
Get-ChildItem -Path $ProjectPath -Include "*.html", "*.css", "*.js", "*.json", "*.md", "*.txt" -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring((Resolve-Path $ProjectPath).Path.Length + 1)
    $destPath = Join-Path $backupFolder $relativePath
    $destDir = Split-Path $destPath -Parent
    
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    Copy-Item -Path $_.FullName -Destination $destPath -Force
    Write-Host "Copiado: $relativePath"
}

# Crear archivo de información del backup
$backupInfo = @"
# Backup Checkin24hs
Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Archivos copiados: $copiedFiles
Directorio: $backupFolder

## Archivos incluidos:
$(Get-ChildItem -Path $backupFolder -Recurse | ForEach-Object { $_.Name })

## Comando para restaurar:
Copy-Item -Path "$backupFolder\*" -Destination "." -Recurse -Force
"@

$backupInfo | Out-File -FilePath (Join-Path $backupFolder "BACKUP_INFO.txt") -Encoding UTF8

Write-Host "Backup completado exitosamente!"
Write-Host "Ubicacion: $backupFolder"
Write-Host "Informacion: $backupFolder\BACKUP_INFO.txt"

# Si es backup automático, mantener solo los últimos 5 backups
if ($AutoBackup) {
    $backups = Get-ChildItem -Path $BackupPath -Directory | Sort-Object CreationTime -Descending
    if ($backups.Count -gt 5) {
        $oldBackups = $backups | Select-Object -Skip 5
        foreach ($oldBackup in $oldBackups) {
            Remove-Item -Path $oldBackup.FullName -Recurse -Force
            Write-Host "Eliminado backup antiguo: $($oldBackup.Name)"
        }
    }
}

# Mostrar estadísticas
$totalSize = (Get-ChildItem -Path $backupFolder -Recurse | Measure-Object -Property Length -Sum).Sum
Write-Host "Tamano total del backup: $([math]::Round($totalSize / 1MB, 2)) MB" 