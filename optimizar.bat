@echo off
echo === OPTIMIZACION DEL SISTEMA ===

echo Cerrando procesos innecesarios...
taskkill /f /im java.exe 2>nul
taskkill /f /im chrome.exe 2>nul
taskkill /f /im msedge.exe 2>nul

echo Limpiando archivos temporales...
del /q /f /s %temp%\*.* 2>nul
del /q /f /s C:\Windows\Temp\*.* 2>nul

echo Verificando memoria...
wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /format:table

echo Verificando disco...
wmic logicaldisk where "DeviceID='C:'" get Size,FreeSpace /format:table

echo Optimizacion completada!
pause
