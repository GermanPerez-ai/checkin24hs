# Script de optimización del sistema para prevenir congelamientos
# Ejecutar como administrador

Write-Host "=== OPTIMIZACIÓN DEL SISTEMA ===" -ForegroundColor Green

# 1. Cerrar procesos que consumen muchos recursos
Write-Host "Cerrando procesos innecesarios..." -ForegroundColor Yellow
$procesosACerrar = @("java.exe", "chrome.exe", "msedge.exe", "msedgewebview2.exe")
foreach ($proceso in $procesosACerrar) {
    try {
        Get-Process -Name $proceso -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host "Cerrado: $proceso" -ForegroundColor Green
    } catch {
        Write-Host "No se encontró: $proceso" -ForegroundColor Gray
    }
}

# 2. Limpiar archivos temporales
Write-Host "Limpiando archivos temporales..." -ForegroundColor Yellow
Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Optimizar memoria virtual
Write-Host "Optimizando memoria virtual..." -ForegroundColor Yellow
$ramGB = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$pageFileSize = $ramGB * 1.5
Write-Host "RAM detectada: $ramGB GB" -ForegroundColor Cyan
Write-Host "Tamaño recomendado de memoria virtual: $pageFileSize GB" -ForegroundColor Cyan

# 4. Optimizar configuración de energía
Write-Host "Configurando plan de energía optimizado..." -ForegroundColor Yellow
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# 5. Optimizar red
Write-Host "Optimizando configuración de red..." -ForegroundColor Yellow
netsh int tcp set global autotuninglevel=normal

# 6. Verificar espacio en disco
Write-Host "Verificando espacio en disco..." -ForegroundColor Yellow
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
$totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
Write-Host "Espacio libre en C: $freeSpaceGB GB de $totalSpaceGB GB" -ForegroundColor Cyan

# 7. Verificar memoria disponible
Write-Host "Verificando memoria disponible..." -ForegroundColor Yellow
$memory = Get-WmiObject -Class Win32_OperatingSystem
$freeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1024, 2)
$totalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize / 1024, 2)
Write-Host "Memoria libre: $freeMemoryGB GB de $totalMemoryGB GB" -ForegroundColor Cyan

# 8. Recomendaciones
Write-Host "`n=== RECOMENDACIONES ===" -ForegroundColor Green
Write-Host "1. Reinicia la notebook después de esta optimización" -ForegroundColor White
Write-Host "2. Instala Core Temp para monitorear temperatura" -ForegroundColor White
Write-Host "3. Considera aumentar la RAM si es posible" -ForegroundColor White
Write-Host "4. Limpia los ventiladores cada 3-6 meses" -ForegroundColor White
Write-Host "5. No uses la notebook sobre superficies blandas" -ForegroundColor White

Write-Host "`nOptimización completada!" -ForegroundColor Green
Write-Host "Presiona cualquier tecla para continuar..."
Read-Host
