# Script para forzar actualización agresiva del dashboard

$file = "dashboard.html"
$content = Get-Content $file -Raw -Encoding UTF8

# 1. Agregar meta tags anti-caché en el head
$headPattern = "(<head[^>]*>)"
$metaTags = @"
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <meta name="version" content="2.1.0">
    <meta name="build-timestamp" content="$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')">
"@

if ($content -notmatch 'http-equiv="Cache-Control"') {
    $content = $content -replace $headPattern, "`$1`n$metaTags"
    Write-Host "Meta tags anti-caché agregados" -ForegroundColor Green
}

# 2. Agregar parámetro de versión automático en la URL al cargar
$bodyPattern = "(<body[^>]*>)"
$bodyScript = @"
    <script>
        // Forzar parámetro de versión en la URL para cache busting
        (function() {
            const urlParams = new URLSearchParams(window.location.search);
            const currentVersion = urlParams.get('v');
            const currentTimestamp = urlParams.get('t');
            const expectedVersion = '2.1.0';
            const buildTimestamp = '$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')';
            
            // Si no hay parámetros de versión, agregarlos
            if (!currentVersion || !currentTimestamp) {
                const newUrl = window.location.pathname + '?v=' + expectedVersion + '&t=' + Date.now();
                if (window.location.search !== newUrl.split('?')[1]) {
                    window.location.replace(newUrl);
                    return;
                }
            }
        })();
    </script>
"@

if ($content -notmatch 'Forzar parámetro de versión') {
    $content = $content -replace $bodyPattern, "`$1`n$bodyScript"
    Write-Host "Script de cache busting agregado" -ForegroundColor Green
}

# 3. Mejorar la detección de versión para que sea más agresiva
$detectionPattern = "(// Sistema de verificaci[^n]*?n autom[^a]*?tica de versi[^n]*?n y cache busting)"
$improvedDetection = @"
// Sistema de verificación automática de versión y cache busting MEJORADO
        (function() {
            // Verificar inmediatamente al cargar
            var storedVersion = localStorage.getItem('dashboard_version');
            var storedTimestamp = localStorage.getItem('dashboard_build_timestamp');
            var currentVersion = window.DASHBOARD_VERSION;
            var currentTimestamp = window.BUILD_TIMESTAMP;
            
            // Forzar recarga si la versión o timestamp son diferentes
            if (storedVersion && storedVersion !== currentVersion) {
                console.warn('⚠️ Versión diferente detectada. Forzando recarga...');
                console.warn('Versión almacenada:', storedVersion, 'vs Versión actual:', currentVersion);
                localStorage.clear();
                sessionStorage.clear();
                // Agregar parámetro de versión para evitar caché
                window.location.replace(window.location.pathname + '?v=' + currentVersion + '&t=' + Date.now() + '&force=1');
                return;
            }
            
            if (storedTimestamp && storedTimestamp !== currentTimestamp) {
                console.warn('⚠️ Build timestamp diferente detectado. Forzando recarga...');
                console.warn('Timestamp almacenado:', storedTimestamp, 'vs Timestamp actual:', currentTimestamp);
                localStorage.clear();
                sessionStorage.clear();
                // Agregar parámetro de timestamp para evitar caché
                window.location.replace(window.location.pathname + '?v=' + currentVersion + '&t=' + Date.now() + '&force=1');
                return;
            }
            
            // Guardar la versión y timestamp actuales
            localStorage.setItem('dashboard_version', currentVersion);
            localStorage.setItem('dashboard_build_timestamp', currentTimestamp);
            
            console.log('✅ Versión verificada:', currentVersion);
            console.log('✅ Build timestamp:', currentTimestamp);
            
            // Verificar versión del servidor periódicamente (cada 10 segundos - muy frecuente)
            setInterval(async () => {
                try {
                    const response = await fetch('/api/version?t=' + new Date().getTime());
                    const data = await response.json();
                    if (data.buildTimestamp && data.buildTimestamp !== currentTimestamp) {
                        console.warn('⚠️ Nueva versión del servidor detectada. Forzando recarga...');
                        console.warn('Timestamp del servidor:', data.buildTimestamp, 'vs Timestamp actual:', currentTimestamp);
                        localStorage.clear();
                        sessionStorage.clear();
                        window.location.replace(window.location.pathname + '?v=' + data.version + '&t=' + Date.now() + '&force=1');
                    }
                } catch (error) {
                    console.error('Error al verificar la versión del servidor:', error);
                }
            }, 10000); // Cada 10 segundos (muy frecuente)
            
            // Verificar versión cuando la ventana recupera el foco
            window.addEventListener('focus', async () => {
                try {
                    const response = await fetch('/api/version?t=' + new Date().getTime());
                    const data = await response.json();
                    if (data.buildTimestamp && data.buildTimestamp !== currentTimestamp) {
                        console.warn('⚠️ Nueva versión del servidor detectada al recuperar el foco. Forzando recarga...');
                        localStorage.clear();
                        sessionStorage.clear();
                        window.location.replace(window.location.pathname + '?v=' + data.version + '&t=' + Date.now() + '&force=1');
                    }
                } catch (error) {
                    console.error('Error al verificar la versión del servidor al recuperar el foco:', error);
                }
            });
        })();
"@

# Reemplazar el sistema de detección
$content = $content -replace '(?s)// Sistema de verificaci[^n]*?n autom[^a]*?tica de versi[^n]*?n y cache busting.*?\(\)\);', $improvedDetection

# Guardar
Set-Content -Path $file -Value $content -NoNewline -Encoding UTF8

Write-Host "Sistema de actualización agresivo aplicado" -ForegroundColor Green
Write-Host "1. Meta tags anti-caché agregados" -ForegroundColor Cyan
Write-Host "2. Cache busting automático en URL" -ForegroundColor Cyan
Write-Host "3. Verificación cada 10 segundos" -ForegroundColor Cyan
Write-Host "4. Uso de window.location.replace para evitar historial" -ForegroundColor Cyan
