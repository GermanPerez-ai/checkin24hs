# Script de monitoreo de temperatura del sistema
# Ejecutar como administrador para mejor precisión

Write-Host "=== MONITOREO DE TEMPERATURA ===" -ForegroundColor Green
Write-Host "Presiona Ctrl+C para detener el monitoreo" -ForegroundColor Yellow

try {
    while ($true) {
        Clear-Host
        Write-Host "=== MONITOREO DE TEMPERATURA ===" -ForegroundColor Green
        Write-Host "Fecha: $(Get-Date)" -ForegroundColor Cyan
        
        # Obtener información del sistema
        $cpu = Get-WmiObject -Class Win32_Processor
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        
        # Información básica del sistema
        Write-Host "`n=== INFORMACIÓN DEL SISTEMA ===" -ForegroundColor Yellow
        Write-Host "Procesador: $($cpu.Name)" -ForegroundColor White
        Write-Host "Núcleos: $($cpu.NumberOfCores)" -ForegroundColor White
        Write-Host "RAM Total: $([math]::Round($memory.TotalVisibleMemorySize/1MB, 2)) MB" -ForegroundColor White
        Write-Host "RAM Libre: $([math]::Round($memory.FreePhysicalMemory/1MB, 2)) MB" -ForegroundColor White
        
        # Uso de CPU
        $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
        Write-Host "Uso de CPU: $([math]::Round($cpuUsage, 1))%" -ForegroundColor White
        
        # Procesos que consumen más recursos
        Write-Host "`n=== PROCESOS CON MÁS USO DE CPU ===" -ForegroundColor Yellow
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU, @{Name="Memoria(MB)";Expression={[math]::Round($_.WorkingSet/1MB, 2)}} | Format-Table -AutoSize
        
        # Procesos que consumen más memoria
        Write-Host "`n=== PROCESOS CON MÁS USO DE MEMORIA ===" -ForegroundColor Yellow
        Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 Name, @{Name="Memoria(MB)";Expression={[math]::Round($_.WorkingSet/1MB, 2)}}, CPU | Format-Table -AutoSize
        
        # Verificar si hay procesos Java activos
        $javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
        if ($javaProcesses) {
            Write-Host "`n⚠️  ADVERTENCIA: Procesos Java activos detectados" -ForegroundColor Red
            $javaProcesses | ForEach-Object {
                Write-Host "  - PID: $($_.Id), Memoria: $([math]::Round($_.WorkingSet/1MB, 2)) MB" -ForegroundColor Red
            }
        }
        
        # Verificar espacio en disco
        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpacePercent = ($disk.FreeSpace / $disk.Size) * 100
        Write-Host "`n=== ESPACIO EN DISCO ===" -ForegroundColor Yellow
        Write-Host "Espacio libre en C: $([math]::Round($disk.FreeSpace/1GB, 2)) GB ($([math]::Round($freeSpacePercent, 1))%)" -ForegroundColor White
        
        if ($freeSpacePercent -lt 10) {
            Write-Host "⚠️  ADVERTENCIA: Poco espacio en disco!" -ForegroundColor Red
        }
        
        # Recomendaciones basadas en el estado actual
        Write-Host "`n=== RECOMENDACIONES ===" -ForegroundColor Green
        if ($cpuUsage -gt 80) {
            Write-Host "• CPU muy ocupada - Cierra aplicaciones innecesarias" -ForegroundColor Yellow
        }
        if ($javaProcesses) {
            Write-Host "• Considera cerrar procesos Java si no los necesitas" -ForegroundColor Yellow
        }
        if ($freeSpacePercent -lt 10) {
            Write-Host "• Libera espacio en disco" -ForegroundColor Yellow
        }
        
        Write-Host "`nActualizando en 10 segundos... (Ctrl+C para salir)" -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
} catch {
    Write-Host "`nMonitoreo detenido." -ForegroundColor Green
}
