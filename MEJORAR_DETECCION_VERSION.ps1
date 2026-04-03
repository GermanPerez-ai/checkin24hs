# Script para mejorar el sistema de detección de versión

$file = "dashboard.html"
$content = Get-Content $file -Raw -Encoding UTF8

# 1. Mejorar la detección de versión para usar window.location.href en lugar de location.reload
$pattern1 = "(if \(storedVersion && storedVersion !== window\.DASHBOARD_VERSION\) \{[^}]*?location\.reload\(true\);)"
$replacement1 = @"
if (storedVersion && storedVersion !== window.DASHBOARD_VERSION) {
                console.warn('⚠️ Versión diferente detectada. Forzando recarga...');
                console.warn('Versión almacenada:', storedVersion, 'vs Versión actual:', window.DASHBOARD_VERSION);
                localStorage.clear();
                sessionStorage.clear();
                window.location.href = window.location.pathname + '?v=' + window.DASHBOARD_VERSION + '&t=' + Date.now();
"@
$content = $content -replace $pattern1, $replacement1

# 2. Mejorar la detección de timestamp
$pattern2 = "(if \(storedTimestamp && storedTimestamp !== window\.BUILD_TIMESTAMP\) \{[^}]*?location\.reload\(true\);)"
$replacement2 = @"
if (storedTimestamp && storedTimestamp !== window.BUILD_TIMESTAMP) {
                console.warn('⚠️ Build timestamp diferente detectado. Forzando recarga...');
                console.warn('Timestamp almacenado:', storedTimestamp, 'vs Timestamp actual:', window.BUILD_TIMESTAMP);
                localStorage.clear();
                sessionStorage.clear();
                window.location.href = window.location.pathname + '?v=' + window.DASHBOARD_VERSION + '&t=' + Date.now();
"@
$content = $content -replace $pattern2, $replacement2

# 3. Agregar logs después de guardar versión
$pattern3 = "(localStorage\.setItem\('dashboard_version', window\.DASHBOARD_VERSION\);\s+localStorage\.setItem\('dashboard_build_timestamp', window\.BUILD_TIMESTAMP\);)"
$replacement3 = @"
localStorage.setItem('dashboard_version', window.DASHBOARD_VERSION);
            localStorage.setItem('dashboard_build_timestamp', window.BUILD_TIMESTAMP);
            
            console.log('✅ Versión verificada:', window.DASHBOARD_VERSION);
            console.log('✅ Build timestamp:', window.BUILD_TIMESTAMP);
"@
$content = $content -replace $pattern3, $replacement3

# 4. Mejorar verificación periódica (cada 15 segundos)
$pattern4 = "(setInterval\(async \(\) => \{[^}]*?location\.reload\(true\);[^}]*?\}, 30000\);)"
$replacement4 = @"
setInterval(async () => {
                try {
                    const response = await fetch('/api/version?t=' + new Date().getTime());
                    const data = await response.json();
                    if (data.buildTimestamp && data.buildTimestamp !== window.BUILD_TIMESTAMP) {
                        console.warn('⚠️ Nueva versión del servidor detectada. Forzando recarga...');
                        console.warn('Timestamp del servidor:', data.buildTimestamp, 'vs Timestamp actual:', window.BUILD_TIMESTAMP);
                        localStorage.clear();
                        sessionStorage.clear();
                        window.location.href = window.location.pathname + '?v=' + data.version + '&t=' + Date.now();
                    }
                } catch (error) {
                    console.error('Error al verificar la versión del servidor:', error);
                }
            }, 15000); // Cada 15 segundos (más frecuente)
"@
$content = $content -replace $pattern4, $replacement4

# 5. Mejorar verificación al recuperar foco
$pattern5 = "(window\.addEventListener\('focus', async \(\) => \{[^}]*?location\.reload\(true\);[^}]*?\}\);)"
$replacement5 = @"
window.addEventListener('focus', async () => {
                try {
                    const response = await fetch('/api/version?t=' + new Date().getTime());
                    const data = await response.json();
                    if (data.buildTimestamp && data.buildTimestamp !== window.BUILD_TIMESTAMP) {
                        console.warn('⚠️ Nueva versión del servidor detectada al recuperar el foco. Forzando recarga...');
                        console.warn('Timestamp del servidor:', data.buildTimestamp, 'vs Timestamp actual:', window.BUILD_TIMESTAMP);
                        localStorage.clear();
                        sessionStorage.clear();
                        window.location.href = window.location.pathname + '?v=' + data.version + '&t=' + Date.now();
                    }
                } catch (error) {
                    console.error('Error al verificar la versión del servidor al recuperar el foco:', error);
                }
            });
"@
$content = $content -replace $pattern5, $replacement5

# Guardar
Set-Content -Path $file -Value $content -NoNewline -Encoding UTF8

Write-Host "Sistema de detección de versión mejorado" -ForegroundColor Green
