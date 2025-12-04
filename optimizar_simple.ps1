# Script de optimización simplificado
Write-Host "=== OPTIMIZACIÓN DEL SISTEMA ===" -ForegroundColor Green

# Cerrar procesos innecesarios
Write-Host "Cerrando procesos innecesarios..." -ForegroundColor Yellow
$procesos = @("java.exe", "chrome.exe", "msedge.exe")
foreach ($proceso in $procesos) {
    try {
        Get-Process -Name $proceso -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host "Cerrado: $proceso" -ForegroundColor Green
    } catch {
        Write-Host "No se encontró: $proceso" -ForegroundColor Gray
    }
}

# Limpiar archivos temporales
Write-Host "Limpiando archivos temporales..." -ForegroundColor Yellow
Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

# Verificar memoria
Write-Host "Verificando memoria..." -ForegroundColor Yellow
$memory = Get-WmiObject -Class Win32_OperatingSystem
$freeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1024, 2)
$totalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize / 1024, 2)
Write-Host "Memoria libre: $freeMemoryGB GB de $totalMemoryGB GB" -ForegroundColor Cyan

# Verificar disco
Write-Host "Verificando disco..." -ForegroundColor Yellow
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
Write-Host "Espacio libre en C: $freeSpaceGB GB" -ForegroundColor Cyan

Write-Host "Optimización completada!" -ForegroundColor Green
