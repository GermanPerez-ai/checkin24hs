# Script para verificar la versión en el servidor y el display de versión
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "VERIFICAR VERSION EN SERVIDOR" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Este script verifica:" -ForegroundColor Yellow
Write-Host "1. Versión en el contenedor Docker" -ForegroundColor White
Write-Host "2. Versión desde HTTP" -ForegroundColor White
Write-Host "3. Display de versión en el HTML" -ForegroundColor White
Write-Host "4. JavaScript que actualiza la versión" -ForegroundColor White
Write-Host ""

Write-Host "INSTRUCCIONES:" -ForegroundColor Cyan
Write-Host "1. Conecta por SSH al servidor" -ForegroundColor White
Write-Host "2. Ejecuta este comando:" -ForegroundColor White
Write-Host ""
Write-Host "   cd ~/checkin24hs && cat > VERIFICAR_VERSION_COMPLETA.sh << 'EOF'" -ForegroundColor Green
Write-Host "   #!/bin/bash" -ForegroundColor Green
Write-Host "   SERVICE_NAME=`"checkin24hs_dashboard`"" -ForegroundColor Green
Write-Host "   DOMAIN=`"dashboard.checkin24hs.com`"" -ForegroundColor Green
Write-Host "   echo `"==========================================`"" -ForegroundColor Green
Write-Host "   echo `"VERIFICAR VERSION COMPLETA`"" -ForegroundColor Green
Write-Host "   echo `"==========================================`"" -ForegroundColor Green
Write-Host "   echo `"`"" -ForegroundColor Green
Write-Host "   echo `"=== 1. Buscar contenedor activo ===`"" -ForegroundColor Green
Write-Host "   CONTAINER=`$(docker ps --filter `"label=com.docker.swarm.service.name=$SERVICE_NAME`" --format `"{{.Names}}`" | head -1)" -ForegroundColor Green
Write-Host "   if [ -z `"$CONTAINER`" ]; then" -ForegroundColor Green
Write-Host "       CONTAINER=`$(docker ps | grep dashboard | awk '{print `$NF}' | head -1)" -ForegroundColor Green
Write-Host "   fi" -ForegroundColor Green
Write-Host "   if [ -z `"$CONTAINER`" ]; then" -ForegroundColor Green
Write-Host "       echo `"ERROR: No se encontro contenedor`"" -ForegroundColor Green
Write-Host "       exit 1" -ForegroundColor Green
Write-Host "   fi" -ForegroundColor Green
Write-Host "   echo `"OK: Contenedor: $CONTAINER`"" -ForegroundColor Green
Write-Host "   echo `"`"" -ForegroundColor Green
Write-Host "   echo `"=== 2. Version en contenedor ===`"" -ForegroundColor Green
Write-Host "   docker exec `"$CONTAINER`" grep -E `"DASHBOARD_VERSION|DASHBOARD_BUILD_NUMBER|DASHBOARD_BUILD`" /app/dashboard.html | head -3" -ForegroundColor Green
Write-Host "   echo `"`"" -ForegroundColor Green
Write-Host "   echo `"=== 3. Display de version en HTML ===`"" -ForegroundColor Green
Write-Host "   if docker exec `"$CONTAINER`" grep -q `"version-display`" /app/dashboard.html; then" -ForegroundColor Green
Write-Host "       echo `"OK: Display encontrado`"" -ForegroundColor Green
Write-Host "       docker exec `"$CONTAINER`" grep -A 3 `"version-display`" /app/dashboard.html | head -4" -ForegroundColor Green
Write-Host "   else" -ForegroundColor Green
Write-Host "       echo `"ERROR: Display NO encontrado`"" -ForegroundColor Green
Write-Host "   fi" -ForegroundColor Green
Write-Host "   echo `"`"" -ForegroundColor Green
Write-Host "   echo `"=== 4. JavaScript que actualiza version ===`"" -ForegroundColor Green
Write-Host "   if docker exec `"$CONTAINER`" grep -q `"version-number`" /app/dashboard.html; then" -ForegroundColor Green
Write-Host "       echo `"OK: JavaScript encontrado`"" -ForegroundColor Green
Write-Host "       docker exec `"$CONTAINER`" grep -B 2 -A 5 `"version-numberEl`" /app/dashboard.html | head -8" -ForegroundColor Green
Write-Host "   else" -ForegroundColor Green
Write-Host "       echo `"ERROR: JavaScript NO encontrado`"" -ForegroundColor Green
Write-Host "   fi" -ForegroundColor Green
Write-Host "   echo `"`"" -ForegroundColor Green
Write-Host "   echo `"=== 5. Version desde HTTP ===`"" -ForegroundColor Green
Write-Host "   HTTP_VERSION=`$(curl -s `"http://$DOMAIN`" 2>/dev/null | grep -oP `"window\.DASHBOARD_VERSION\s*=\s*'[^']+'`" | grep -oP `"'[^']+'`" | tr -d `"'`" | head -1 || echo `"No encontrada`")" -ForegroundColor Green
Write-Host "   HTTP_BUILD=`$(curl -s `"http://$DOMAIN`" 2>/dev/null | grep -oP `"window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+`" | grep -oP `"\d+`" | head -1 || echo `"No encontrada`")" -ForegroundColor Green
Write-Host "   echo `"Version HTTP: $HTTP_VERSION`"" -ForegroundColor Green
Write-Host "   echo `"Build HTTP: #$HTTP_BUILD`"" -ForegroundColor Green
Write-Host "   echo `"`"" -ForegroundColor Green
Write-Host "   echo `"=== 6. Comparar versiones ===`"" -ForegroundColor Green
Write-Host "   CONTAINER_VERSION=`$(docker exec `"$CONTAINER`" grep -oP `"window\.DASHBOARD_VERSION\s*=\s*'[^']+'`" /app/dashboard.html 2>/dev/null | grep -oP `"'[^']+'`" | tr -d `"'`" | head -1 || echo `"No encontrada`")" -ForegroundColor Green
Write-Host "   CONTAINER_BUILD=`$(docker exec `"$CONTAINER`" grep -oP `"window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+`" /app/dashboard.html 2>/dev/null | grep -oP `"\d+`" | head -1 || echo `"No encontrada`")" -ForegroundColor Green
Write-Host "   echo `"Version contenedor: $CONTAINER_VERSION`"" -ForegroundColor Green
Write-Host "   echo `"Build contenedor: #$CONTAINER_BUILD`"" -ForegroundColor Green
Write-Host "   echo `"Version HTTP: $HTTP_VERSION`"" -ForegroundColor Green
Write-Host "   echo `"Build HTTP: #$HTTP_BUILD`"" -ForegroundColor Green
Write-Host "   if [ `"$CONTAINER_BUILD`" = `"5`" ]; then" -ForegroundColor Green
Write-Host "       echo `"OK: Version actualizada (Build #5)`"" -ForegroundColor Green
Write-Host "   else" -ForegroundColor Green
Write-Host "       echo `"ADVERTENCIA: Version no es la mas reciente (esperado: #5, encontrado: #$CONTAINER_BUILD)`"" -ForegroundColor Yellow
Write-Host "   fi" -ForegroundColor Green
Write-Host "   echo `"`"" -ForegroundColor Green
Write-Host "   echo `"==========================================`"" -ForegroundColor Green
Write-Host "   echo `"OK: Verificacion completada`"" -ForegroundColor Green
Write-Host "   echo `"==========================================`"" -ForegroundColor Green
Write-Host "   EOF" -ForegroundColor Green
Write-Host "   chmod +x VERIFICAR_VERSION_COMPLETA.sh" -ForegroundColor Green
Write-Host "   bash VERIFICAR_VERSION_COMPLETA.sh" -ForegroundColor Green
Write-Host ""
