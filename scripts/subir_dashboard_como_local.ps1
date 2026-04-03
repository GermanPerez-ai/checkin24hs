# Subir todo el dashboard como está en local y desplegar en el servidor
# Uso: .\scripts\subir_dashboard_como_local.ps1
# Requiere: Git configurado, push a GitHub, y luego ejecutar los comandos SSH en el servidor

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$repoRoot\.git")) { $repoRoot = (Get-Location).Path }

Set-Location $repoRoot

Write-Host "=== 1. Git: agregar cambios del dashboard y relacionados ===" -ForegroundColor Cyan
# Evitar que la advertencia LF/CRLF de Git detenga el script
$prevErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Continue"
git add dashboard.html deploy/dashboard.html deploy/dashboard-html/BUILD_ID deploy/dashboard-html/server.js deploy/dashboard-html/Dockerfile docker-compose.easypanel.yml supabase-client.js scripts/deploy_dashboard_servidor.sh docs/DASHBOARD_IGUAL_A_LOCAL.md 2>&1 | Out-Null
$ErrorActionPreference = $prevErrorAction
git status --short

$msg = Read-Host "Mensaje de commit (Enter = 'Dashboard: subir como local')"
if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "Dashboard: subir como local" }

Write-Host "`n=== 2. Commit y push ===" -ForegroundColor Cyan
$ErrorActionPreference = "Continue"
git commit -m $msg
git push
$ErrorActionPreference = $prevErrorAction
if ($LASTEXITCODE -ne 0) { Write-Host "Atención: revisa si el push falló (ej. credenciales, red)." -ForegroundColor Yellow }

Write-Host "`n=== 3. En el SERVIDOR (SSH): un solo comando ===" -ForegroundColor Green
Write-Host "Conectate por SSH (root@srv1152402) y ejecutá:`n" -ForegroundColor Yellow
Write-Host "cd /root/checkin24hs && git pull && bash scripts/deploy_dashboard_servidor.sh" -ForegroundColor White
Write-Host "`n(El script hace: pull, build con BUILD_ID del repo, service update --force.)" -ForegroundColor Gray
Write-Host "`nDespués, abre https://dashboard.checkin24hs.com y recarga (Ctrl+Shift+R)." -ForegroundColor Gray
