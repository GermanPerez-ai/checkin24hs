# Script PowerShell para actualizar cotizador completo
# Ejecuta: git add, commit, push y luego actualiza en servidor

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🔄 Proceso Completo de Actualización del Cotizador" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Cambiar al directorio del proyecto
$projectPath = "c:\Users\German\Downloads\Checkin24hs"
Set-Location $projectPath

Write-Host "📋 Paso 1: Verificar estado de Git..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "📋 Paso 2: Agregar archivos modificados..." -ForegroundColor Yellow

# Archivos a actualizar
$files = @(
    "cotizador-cliente.html"
    "supabase-config.js"
    "supabase-client.js"
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

# Mensaje de commit
$commitMessage = @'
feat: Actualizar cotizador-cliente con validación de promociones

- Agregar validación de fechas de viaje en promociones
- Agregar validación de cantidad de noches
- Agregar modal de validación con opciones (revisar o enviar igual)
- Mejorar logging y debugging
- Agregar soporte para diferentes formatos de campos (camelCase y snake_case)
'@

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
Write-Host "   2️⃣  Ve al directorio del cotizador:" -ForegroundColor White
Write-Host "      cd /root/checkin24hs" -ForegroundColor Gray
Write-Host ""
Write-Host "   3️⃣  Ejecuta el script de actualización:" -ForegroundColor White
Write-Host "      ./ACTUALIZAR_COTIZADOR_FINAL.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "   4️⃣  Si el script no existe, cópialo desde tu PC:" -ForegroundColor White
Write-Host "      scp ACTUALIZAR_COTIZADOR_FINAL.sh root@72.61.58.240:/root/checkin24hs/" -ForegroundColor Gray
Write-Host "      ssh root@72.61.58.240 'chmod +x /root/checkin24hs/ACTUALIZAR_COTIZADOR_FINAL.sh'" -ForegroundColor Gray
Write-Host ""
Write-Host "   5️⃣  Verifica en el navegador:" -ForegroundColor White
Write-Host "      https://cotizar.checkin24hs.com/" -ForegroundColor Gray
Write-Host "      (Limpia la caché: Ctrl+Shift+R)" -ForegroundColor Gray
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
        scp ACTUALIZAR_COTIZADOR_FINAL.sh "root@${serverIP}:/root/checkin24hs/"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Script copiado" -ForegroundColor Green
            Write-Host ""
            Write-Host "   🎯 Permisos configurados" -ForegroundColor Green
            ssh "root@${serverIP}" "chmod +x /root/checkin24hs/ACTUALIZAR_COTIZADOR_FINAL.sh"
            Write-Host ""
            Write-Host "   ¿Ejecutar el script ahora? [S/N]: " -NoNewline
            $execute = Read-Host
            
            if ($execute -eq "S" -or $execute -eq "s") {
                Write-Host "   🚀 Ejecutando script en servidor..." -ForegroundColor Yellow
                ssh "root@${serverIP}" "cd /root/checkin24hs && ./ACTUALIZAR_COTIZADOR_FINAL.sh"
            } else {
                Write-Host ""
                Write-Host "   💡 Para ejecutarlo después, conecta por SSH y ejecuta:" -ForegroundColor Cyan
                Write-Host "      cd /root/checkin24hs && ./ACTUALIZAR_COTIZADOR_FINAL.sh" -ForegroundColor White
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
Write-Host "🌐 Verifica en: https://cotizar.checkin24hs.com/" -ForegroundColor Cyan
Write-Host ""
