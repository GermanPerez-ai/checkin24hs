@echo off
echo Abriendo verificador de servidores WhatsApp en Chrome...
echo.

REM Intentar abrir con Chrome
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "file:///%CD%\verificar_servidores_whatsapp.html"

REM Si Chrome no está en la ruta por defecto, intentar con el navegador predeterminado
timeout /t 2 /nobreak >nul
if errorlevel 1 (
    echo Chrome no encontrado en la ruta predeterminada.
    echo Intentando abrir con el navegador predeterminado...
    start verificar_servidores_whatsapp.html
)

echo.
echo Si el archivo no se abre correctamente:
echo 1. Arrastra el archivo verificar_servidores_whatsapp.html a la ventana de Chrome
echo 2. O usa Ctrl+O en Chrome y selecciona el archivo
echo 3. O instala un servidor local simple: python -m http.server 8000
echo    luego abre: http://localhost:8000/verificar_servidores_whatsapp.html
echo.
pause
