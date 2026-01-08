# Script de Backup Automático para Checkin24hs
# Este script se ejecuta automáticamente cada 30 minutos

param(
    [string]$BackupPath = ".\backups",
    [int]$IntervalMinutes = 30,
    [switch]$RunOnce = $false
)

Write-Host "🔄 Iniciando sistema de backup automático..."
Write-Host "⏰ Intervalo: $IntervalMinutes minutos"
Write-Host "📁 Directorio de backup: $BackupPath"

# Función para ejecutar el backup
function Start-Backup {
    Write-Host "`n🔄 Ejecutando backup automático... $(Get-Date -Format 'HH:mm:ss')"
    
    # Llamar al script principal de backup
    & ".\backup_script.ps1" -BackupPath $BackupPath -AutoBackup $true
    
    Write-Host "✅ Backup completado: $(Get-Date -Format 'HH:mm:ss')"
}

# Si solo se ejecuta una vez
if ($RunOnce) {
    Start-Backup
    exit
}

# Bucle infinito para backup automático
while ($true) {
    try {
        Start-Backup
        
        # Esperar el intervalo especificado
        Write-Host "⏳ Esperando $IntervalMinutes minutos hasta el próximo backup..."
        Start-Sleep -Seconds ($IntervalMinutes * 60)
        
    } catch {
        Write-Host "❌ Error en el backup: $($_.Exception.Message)"
        Write-Host "🔄 Reintentando en 5 minutos..."
        Start-Sleep -Seconds 300
    }
} 