# Script PowerShell para actualizar dashboard completo
# Ejecuta: actualizar build number, git add, commit, push y luego actualiza en servidor

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🔄 Proceso Completo de Actualización del Dashboard" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Cambiar al directorio del proyecto
$projectPath = "c:\Users\German\Downloads\Checkin24hs"
Set-Location $projectPath

# Paso 0: Actualizar Build Number
Write-Host "📋 Paso 0: Actualizar Build Number..." -ForegroundColor Yellow

if (Test-Path "actualizar_build_dashboard.ps1") {
    Write-Host "   🔢 Ejecutando actualizar_build_dashboard.ps1..." -ForegroundColor Gray
    & .\actualizar_build_dashboard.ps1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Build number actualizado" -ForegroundColor Green
        
        # Leer el nuevo build number
        $dashboardContent = Get-Content "dashboard.html" -Raw
        if ($dashboardContent -match "DASHBOARD_BUILD_NUMBER = (\d+)") {
            $buildNumber = $matches[1]
            Write-Host "   📊 Build Number: #$buildNumber" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   ⚠️  Advertencia: No se pudo actualizar build number automáticamente" -ForegroundColor Yellow
        Write-Host "   💡 Puedes actualizarlo manualmente en dashboard.html" -ForegroundColor Gray
    }
} else {
    Write-Host "   ⚠️  Script actualizar_build_timestamp.ps1 no encontrado" -ForegroundColor Yellow
    Write-Host "   💡 Actualiza manualmente DASHBOARD_BUILD_NUMBER en dashboard.html" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📋 Paso 1: Verificar estado de Git..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "📋 Paso 2: Agregar archivos modificados..." -ForegroundColor Yellow

# Archivos a actualizar
$files = @(
    "dashboard.html"
)

# Verificar qué archivos existen y han cambiado
$filesToAdd = @()
foreach ($file in $files) {
    if (Test-Path $file) {
        $status = git status --porcelain $file
        if ($status) {
            Write-Host "   ✅ $file tiene cambios" -ForegroundColor Green
            $filesToAdd += $file
        } else {
            Write-Host "   ℹ️  $file no tiene cambios" -ForegroundColor Gray
        }
    } else {
        Write-Host "   ⚠️  $file no existe" -ForegroundColor Yellow
    }
}

if ($filesToAdd.Count -eq 0) {
    Write-Host ""
    Write-Host "⚠️  No hay archivos para agregar" -ForegroundColor Yellow
    Write-Host "   ¿Deseas continuar de todos modos? [S/N]: " -NoNewline
    $continue = Read-Host
    if ($continue -ne "S" -and $continue -ne "s") {
        Write-Host "❌ Proceso cancelado" -ForegroundColor Red
        exit
    }
} else {
    Write-Host ""
    Write-Host "📤 Agregando archivos a Git..." -ForegroundColor Yellow
    git add $filesToAdd
    Write-Host "   ✅ Archivos agregados" -ForegroundColor Green
}

Write-Host ""
Write-Host "📝 Paso 3: Hacer commit..." -ForegroundColor Yellow

# Obtener build number para el mensaje de commit
$buildNumber = ""
if (Test-Path "dashboard.html") {
    $dashboardContent = Get-Content "dashboard.html" -Raw
    if ($dashboardContent -match "DASHBOARD_BUILD_NUMBER = (\d+)") {
        $buildNumber = $matches[1]
    }
}

# Mensaje de commit
$commitMessage = @"
feat: Actualizar dashboard

- Actualizar dashboard.html
$(if ($buildNumber) { "- Build #$buildNumber" })
"@

Write-Host "   Mensaje de commit:" -ForegroundColor Gray
Write-Host "   $commitMessage" -ForegroundColor Gray
Write-Host ""
Write-Host "   ¿Continuar con el commit? [S/N]: " -NoNewline
$confirm = Read-Host

if ($confirm -eq "S" -or $confirm -eq "s") {
    git commit -m "$commitMessage"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Commit realizado" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Error al hacer commit" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "❌ Proceso cancelado" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "📤 Paso 4: Subir a GitHub..." -ForegroundColor Yellow
Write-Host "   ¿Subir cambios a GitHub? [S/N]: " -NoNewline
$push = Read-Host

if ($push -eq "S" -or $push -eq "s") {
    git push origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Cambios subidos a GitHub" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Error al subir a GitHub" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "   ⚠️  Cambios no subidos a GitHub" -ForegroundColor Yellow
    Write-Host "   Recuerda hacer 'git push' manualmente" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Proceso local completado" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "⚠️  ⚠️  ⚠️  RECORDATORIO IMPORTANTE  ⚠️  ⚠️  ⚠️" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 SIGUIENTE PASO: Actualizar en el servidor" -ForegroundColor Cyan
Write-Host ""
Write-Host "   1️⃣  Conéctate por SSH al servidor:" -ForegroundColor White
Write-Host "      ssh root@72.61.58.240" -ForegroundColor Gray
Write-Host ""
Write-Host "   2️⃣  Ve al directorio:" -ForegroundColor White
Write-Host "      cd /root/checkin24hs" -ForegroundColor Gray
Write-Host ""
Write-Host "   3️⃣  Ejecuta el script de actualización:" -ForegroundColor White
Write-Host "      ./ACTUALIZAR_DASHBOARD_FINAL.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "   4️⃣  Si el script no existe, cópialo desde tu PC:" -ForegroundColor White
Write-Host "      scp ACTUALIZAR_DASHBOARD_FINAL.sh root@72.61.58.240:/root/checkin24hs/" -ForegroundColor Gray
Write-Host "      ssh root@72.61.58.240 'chmod +x /root/checkin24hs/ACTUALIZAR_DASHBOARD_FINAL.sh'" -ForegroundColor Gray
Write-Host ""
Write-Host "   5️⃣  Verifica en el navegador:" -ForegroundColor White
Write-Host "      https://dashboard.checkin24hs.com/" -ForegroundColor Gray
Write-Host "      (Limpia la caché: Ctrl+Shift+R)" -ForegroundColor Gray
Write-Host "      Verifica build number: window.DASHBOARD_BUILD_NUMBER" -ForegroundColor Gray
Write-Host ""
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "   ¿Deseas copiar el script al servidor ahora? [S/N]: " -NoNewline
$copyScript = Read-Host

if ($copyScript -eq "S" -or $copyScript -eq "s") {
    $defaultIP = "72.61.58.240"
    Write-Host "   Ingresa la IP del servidor" -ForegroundColor Yellow
    Write-Host "      (Presiona Enter para usar: $defaultIP): " -NoNewline -ForegroundColor Gray
    $serverIP = Read-Host
    
    if (-not $serverIP) {
        $serverIP = $defaultIP
        Write-Host "      ✅ Usando IP por defecto: $serverIP" -ForegroundColor Green
    }
    
    if ($serverIP) {
        Write-Host "   📤 Copiando script al servidor..." -ForegroundColor Yellow
        
        # Crear directorio si no existe
        ssh "root@${serverIP}" "mkdir -p /root/checkin24hs"
        
        # Copiar script
        scp ACTUALIZAR_DASHBOARD_FINAL.sh "root@${serverIP}:/root/checkin24hs/"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Script copiado" -ForegroundColor Green
            Write-Host ""
            Write-Host "   🎯 Permisos configurados" -ForegroundColor Green
            ssh "root@${serverIP}" "chmod +x /root/checkin24hs/ACTUALIZAR_DASHBOARD_FINAL.sh"
            Write-Host ""
            Write-Host "   ¿Ejecutar el script ahora? [S/N]: " -NoNewline
            $execute = Read-Host
            
            if ($execute -eq "S" -or $execute -eq "s") {
                Write-Host "   🚀 Ejecutando script en servidor..." -ForegroundColor Yellow
                ssh "root@${serverIP}" "cd /root/checkin24hs && ./ACTUALIZAR_DASHBOARD_FINAL.sh"
            } else {
                Write-Host ""
                Write-Host "   💡 Para ejecutarlo después, conecta por SSH y ejecuta:" -ForegroundColor Cyan
                Write-Host "      cd /root/checkin24hs && ./ACTUALIZAR_DASHBOARD_FINAL.sh" -ForegroundColor White
            }
        } else {
            Write-Host "   ❌ Error al copiar script" -ForegroundColor Red
        }
    }
} else {
    Write-Host ""
    Write-Host "   💡 Recuerda copiar y ejecutar el script en el servidor" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Proceso completado" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Verifica en: https://dashboard.checkin24hs.com/" -ForegroundColor Cyan
Write-Host ""
