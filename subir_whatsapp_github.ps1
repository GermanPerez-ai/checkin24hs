# Script PowerShell para verificar y subir WhatsApp a GitHub
# Ejecutar desde la carpeta raíz del proyecto

Write-Host "🔍 Verificando archivos de WhatsApp..." -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "whatsapp-server")) {
    Write-Host "❌ Error: No se encontró la carpeta whatsapp-server" -ForegroundColor Red
    Write-Host "   Asegúrate de ejecutar este script desde la raíz del proyecto" -ForegroundColor Yellow
    exit 1
}

# Verificar archivos necesarios
$archivosNecesarios = @(
    "whatsapp-server/whatsapp-server.js",
    "whatsapp-server/package.json",
    "whatsapp-server/Dockerfile",
    "whatsapp-server/README.md"
)

Write-Host "`n📋 Verificando archivos necesarios..." -ForegroundColor Cyan
$archivosFaltantes = @()

foreach ($archivo in $archivosNecesarios) {
    if (Test-Path $archivo) {
        Write-Host "  ✅ $archivo" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $archivo (FALTA)" -ForegroundColor Red
        $archivosFaltantes += $archivo
    }
}

if ($archivosFaltantes.Count -gt 0) {
    Write-Host "`n⚠️  Faltan algunos archivos necesarios:" -ForegroundColor Yellow
    foreach ($archivo in $archivosFaltantes) {
        Write-Host "   - $archivo" -ForegroundColor Yellow
    }
    Write-Host "`n¿Deseas continuar de todos modos? (S/N): " -ForegroundColor Yellow -NoNewline
    $continuar = Read-Host
    if ($continuar -ne "S" -and $continuar -ne "s") {
        exit 1
    }
}

# Verificar estado de Git
Write-Host "`n🔍 Verificando estado de Git..." -ForegroundColor Cyan
try {
    $gitStatus = git status --porcelain whatsapp-server/ 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error: No se pudo verificar el estado de Git" -ForegroundColor Red
        Write-Host "   Asegúrate de que Git esté instalado y configurado" -ForegroundColor Yellow
        exit 1
    }
    
    if ($gitStatus) {
        Write-Host "📝 Archivos modificados o sin seguimiento:" -ForegroundColor Yellow
        Write-Host $gitStatus
        Write-Host "`n¿Deseas agregar estos archivos a Git? (S/N): " -ForegroundColor Yellow -NoNewline
        $agregar = Read-Host
        if ($agregar -eq "S" -or $agregar -eq "s") {
            Write-Host "`n➕ Agregando archivos a Git..." -ForegroundColor Cyan
            git add whatsapp-server/
            Write-Host "✅ Archivos agregados" -ForegroundColor Green
            
            Write-Host "`n💬 Ingresa un mensaje para el commit: " -ForegroundColor Yellow -NoNewline
            $mensaje = Read-Host
            if (-not $mensaje) {
                $mensaje = "Agregar servidor WhatsApp con integración Flor IA"
            }
            
            Write-Host "`n📝 Creando commit..." -ForegroundColor Cyan
            git commit -m $mensaje
            Write-Host "✅ Commit creado" -ForegroundColor Green
            
            Write-Host "`n🚀 ¿Deseas subir los cambios a GitHub? (S/N): " -ForegroundColor Yellow -NoNewline
            $subir = Read-Host
            if ($subir -eq "S" -or $subir -eq "s") {
                Write-Host "`n⬆️  Subiendo a GitHub..." -ForegroundColor Cyan
                git push origin main
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ ¡Archivos subidos exitosamente a GitHub!" -ForegroundColor Green
                } else {
                    Write-Host "❌ Error al subir a GitHub" -ForegroundColor Red
                    Write-Host "   Verifica tu conexión y permisos de GitHub" -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "✅ Todos los archivos de WhatsApp ya están en Git" -ForegroundColor Green
        
        # Verificar si hay cambios sin commitear
        $gitStatusAll = git status --porcelain 2>&1
        if ($gitStatusAll) {
            Write-Host "`n⚠️  Hay otros archivos modificados:" -ForegroundColor Yellow
            Write-Host $gitStatusAll
        } else {
            Write-Host "`n✅ No hay cambios pendientes" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Verificación completada" -ForegroundColor Green
Write-Host "`n📋 Próximos pasos:" -ForegroundColor Cyan
Write-Host "   1. Verifica en GitHub que los archivos estén presentes" -ForegroundColor White
Write-Host "   2. En EasyPanel, configura la ruta: /whatsapp-server" -ForegroundColor White
Write-Host "   3. Despliega el servicio" -ForegroundColor White

