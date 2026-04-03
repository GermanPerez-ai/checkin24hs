@echo off
REM Script para crear el archivo .env en Windows
REM Ejecuta este archivo haciendo doble clic

echo Creando archivo .env...

(
echo GEMINI_API_KEY=tu_api_key_de_gemini_aquí
echo GEMINI_MODEL=gemini-2.5-flash
) > .env

if exist .env (
    echo.
    echo ✅ Archivo .env creado exitosamente!
    echo.
    echo ⚠️ IMPORTANTE:
    echo    Ahora debes editar el archivo .env y reemplazar 'tu_api_key_de_gemini_aquí'
    echo    con tu API Key real de Gemini.
    echo.
    echo    Puedes obtener tu API Key en: https://makersuite.google.com/app/apikey
    echo.
    pause
) else (
    echo ❌ Error al crear el archivo .env
    pause
)
