# ==========================================
# ARREGLAR WEBMAIL - Bad Gateway
# ==========================================
# Script para diagnosticar y solucionar el error Bad Gateway (502) del webmail

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "ARREGLAR WEBMAIL - Bad Gateway" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# PASO 1: DIAGNOSTICO INICIAL
# ==========================================
Write-Host "1. DIAGNOSTICO INICIAL" -ForegroundColor Yellow
Write-Host ""

$webmailUrl = "https://webmail.checkin24hs.com"
Write-Host "   Verificando acceso a: $webmailUrl" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri $webmailUrl -Method Get -TimeoutSec 5 -ErrorAction Stop -UseBasicParsing
    Write-Host "   [OK] Webmail accesible - Codigo: $($response.StatusCode)" -ForegroundColor Green
    
    if ($response.StatusCode -eq 502 -or $response.StatusCode -eq 503) {
        Write-Host "   [ADVERTENCIA] Error detectado: $($response.StatusCode)" -ForegroundColor Red
        Write-Host "   Esto confirma el problema de Bad Gateway" -ForegroundColor Yellow
    }
} catch {
    try {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   [ERROR] Error al acceder: $statusCode" -ForegroundColor Red
    } catch {
        Write-Host "   [ERROR] Error al acceder al webmail" -ForegroundColor Red
    }
    Write-Host "   Mensaje: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""

# ==========================================
# PASO 2: CONFIGURACION EN EASYPANEL
# ==========================================
Write-Host "2. CONFIGURACION EN EASYPANEL" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Abre EasyPanel y sigue estos pasos:" -ForegroundColor White
Write-Host ""

Write-Host "   PASO 2.1: Verificar Recursos" -ForegroundColor Cyan
Write-Host "   ---------------------------------------" -ForegroundColor Gray
Write-Host "   1. Ve a: Proyecto 'checkin24hs' -> Servicio 'webmail'" -ForegroundColor White
Write-Host "   2. Haz clic en 'Recursos' (menu lateral)" -ForegroundColor White
Write-Host "   3. Verifica estos valores:" -ForegroundColor White
Write-Host "      - Reserva de memoria: 512 MB (minimo)" -ForegroundColor Green
Write-Host "      - Limite de memoria: 1024 MB (recomendado)" -ForegroundColor Green
Write-Host "      - Reserva de CPU: 0.5 (minimo)" -ForegroundColor Green
Write-Host "      - Limite de CPU: 1.0 (recomendado)" -ForegroundColor Green
Write-Host "   4. Si estan en 0 o muy bajos, CAMBIALOS" -ForegroundColor Yellow
Write-Host "   5. Guarda los cambios" -ForegroundColor White
Write-Host ""

Write-Host "   PASO 2.2: Verificar Dominio" -ForegroundColor Cyan
Write-Host "   ---------------------------------------" -ForegroundColor Gray
Write-Host "   1. Haz clic en 'Dominios' (menu lateral)" -ForegroundColor White
Write-Host "   2. Busca: webmail.checkin24hs.com" -ForegroundColor White
Write-Host "   3. Haz clic en el dominio para editarlo" -ForegroundColor White
Write-Host "   4. Verifica el PUERTO:" -ForegroundColor Yellow
Write-Host "      [IMPORTANTE] El puerto debe ser 80 (puerto INTERNO)" -ForegroundColor Yellow
Write-Host "      [ERROR] NO debe ser 8080 (ese es el externo)" -ForegroundColor Red
Write-Host "   5. Si el puerto es 8080, cambialo a 80" -ForegroundColor Yellow
Write-Host "   6. Guarda los cambios" -ForegroundColor White
Write-Host ""

Write-Host "   PASO 2.3: Verificar Variables de Entorno" -ForegroundColor Cyan
Write-Host "   ---------------------------------------" -ForegroundColor Gray
Write-Host "   1. Haz clic en 'Entorno' (menu lateral)" -ForegroundColor White
Write-Host "   2. Verifica que tengas estas variables:" -ForegroundColor White
Write-Host ""
Write-Host "      ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com" -ForegroundColor Gray
Write-Host "      ROUNDCUBEMAIL_DEFAULT_PORT=993" -ForegroundColor Gray
Write-Host "      ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com" -ForegroundColor Gray
Write-Host "      ROUNDCUBEMAIL_SMTP_PORT=587" -ForegroundColor Gray
Write-Host "      ROUNDCUBEMAIL_PLUGINS=archive,zipdownload" -ForegroundColor Gray
Write-Host "      ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE=5M" -ForegroundColor Gray
Write-Host ""
Write-Host "   3. Si faltan, agregalas" -ForegroundColor Yellow
Write-Host "   4. Guarda los cambios" -ForegroundColor White
Write-Host ""

Write-Host "   PASO 2.4: Verificar Fuente (Docker Image)" -ForegroundColor Cyan
Write-Host "   ---------------------------------------" -ForegroundColor Gray
Write-Host "   1. Haz clic en 'Fuente' (menu lateral)" -ForegroundColor White
Write-Host "   2. Verifica que la imagen sea:" -ForegroundColor White
Write-Host "      roundcube/roundcubemail:1.6.11-apache" -ForegroundColor Gray
Write-Host "   3. Si esta correcta, no cambies nada" -ForegroundColor Green
Write-Host ""

# ==========================================
# PASO 3: VERIFICAR LOGS
# ==========================================
Write-Host "3. VERIFICAR LOGS" -ForegroundColor Yellow
Write-Host ""
Write-Host "   1. En EasyPanel, ve a la seccion 'Registros' (abajo)" -ForegroundColor White
Write-Host "   2. Haz clic en 'Actualizar registros' (boton refresh)" -ForegroundColor White
Write-Host "   3. Revisa los ultimos mensajes buscando:" -ForegroundColor White
Write-Host ""
Write-Host "      [ERROR] 'Killed' -> Problema de memoria" -ForegroundColor Red
Write-Host "      [ERROR] 'Out of memory' -> Falta de memoria" -ForegroundColor Red
Write-Host "      [ERROR] 'Port already in use' -> Conflicto de puertos" -ForegroundColor Red
Write-Host "      [ERROR] 'Cannot bind' -> Puerto en uso" -ForegroundColor Red
Write-Host "      [ERROR] '502 Bad Gateway' -> Nginx no puede conectar" -ForegroundColor Red
Write-Host ""
Write-Host "   4. Si encuentras alguno de estos errores, anotalo" -ForegroundColor Yellow
Write-Host ""

# ==========================================
# PASO 4: SOLUCIONES ESPECIFICAS
# ==========================================
Write-Host "4. SOLUCIONES ESPECIFICAS" -ForegroundColor Yellow
Write-Host ""

Write-Host "   SOLUCION 1: Si el servicio esta en ROJO (detenido)" -ForegroundColor Cyan
Write-Host "   ---------------------------------------" -ForegroundColor Gray
Write-Host "   1. Verifica que los Recursos NO esten en 0" -ForegroundColor White
Write-Host "   2. Verifica que el Dominio tenga puerto 80" -ForegroundColor White
Write-Host "   3. Haz clic en el boton verde 'Implementar'" -ForegroundColor Green
Write-Host "   4. Espera 1-2 minutos" -ForegroundColor White
Write-Host "   5. Observa los logs para ver el progreso" -ForegroundColor White
Write-Host "   6. El punto debe cambiar de ROJO a VERDE" -ForegroundColor Green
Write-Host ""

Write-Host "   SOLUCION 2: Si el servicio esta en VERDE pero sigue 502" -ForegroundColor Cyan
Write-Host "   ---------------------------------------" -ForegroundColor Gray
Write-Host "   1. Ve a 'Dominios' -> webmail.checkin24hs.com" -ForegroundColor White
Write-Host "   2. Verifica que el puerto sea 80 (NO 8080)" -ForegroundColor Yellow
Write-Host "   3. Si es 8080, cambialo a 80" -ForegroundColor Yellow
Write-Host "   4. Guarda los cambios" -ForegroundColor White
Write-Host "   5. Espera 10-15 segundos" -ForegroundColor White
Write-Host "   6. Actualiza la pagina del webmail (F5)" -ForegroundColor White
Write-Host ""

Write-Host "   SOLUCION 3: Si el log muestra 'Killed' o 'Out of memory'" -ForegroundColor Cyan
Write-Host "   ---------------------------------------" -ForegroundColor Gray
Write-Host "   1. Ve a 'Recursos'" -ForegroundColor White
Write-Host "   2. Aumenta la memoria:" -ForegroundColor White
Write-Host "      - Limite de memoria: 2048 MB (2 GB)" -ForegroundColor Green
Write-Host "   3. Guarda los cambios" -ForegroundColor White
Write-Host "   4. Haz clic en 'Implementar'" -ForegroundColor Green
Write-Host ""

Write-Host "   SOLUCION 4: Si el log muestra 'Port already in use'" -ForegroundColor Cyan
Write-Host "   ---------------------------------------" -ForegroundColor Gray
Write-Host "   1. Ve a 'Dominios'" -ForegroundColor White
Write-Host "   2. Cambia el puerto a 8081 o 8082" -ForegroundColor Yellow
Write-Host "   3. Guarda los cambios" -ForegroundColor White
Write-Host "   4. Haz clic en 'Implementar'" -ForegroundColor Green
Write-Host ""

# ==========================================
# PASO 5: CHECKLIST FINAL
# ==========================================
Write-Host "5. CHECKLIST ANTES DE IMPLEMENTAR" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Antes de hacer clic en 'Implementar', verifica:" -ForegroundColor White
Write-Host ""
Write-Host "   [ ] Recursos: Memoria al menos 512 MB (mejor 1024 MB)" -ForegroundColor Gray
Write-Host "   [ ] Recursos: CPU al menos 0.5 (mejor 1.0)" -ForegroundColor Gray
Write-Host "   [ ] Dominio: Puerto configurado en 80 (NO 8080)" -ForegroundColor Gray
Write-Host "   [ ] Variables de entorno: Todas configuradas" -ForegroundColor Gray
Write-Host "   [ ] Fuente: Imagen Docker correcta" -ForegroundColor Gray
Write-Host "   [ ] Logs: Revisados para entender errores previos" -ForegroundColor Gray
Write-Host ""

# ==========================================
# PASO 6: ORDEN DE ACCION RECOMENDADO
# ==========================================
Write-Host "6. ORDEN DE ACCION RECOMENDADO" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Sigue este orden exacto:" -ForegroundColor White
Write-Host ""
Write-Host "   1. Ve a 'Recursos' -> Aumenta memoria a 1024 MB -> Guarda" -ForegroundColor Cyan
Write-Host "   2. Ve a 'Dominios' -> Verifica/cambia puerto a 80 -> Guarda" -ForegroundColor Cyan
Write-Host "   3. Ve a 'Entorno' -> Verifica variables -> Guarda" -ForegroundColor Cyan
Write-Host "   4. Haz clic en 'Implementar' (boton verde)" -ForegroundColor Green
Write-Host "   5. Espera 1-2 minutos" -ForegroundColor White
Write-Host "   6. Observa los logs y espera a que el punto cambie a VERDE" -ForegroundColor White
Write-Host "   7. Intenta acceder a: https://webmail.checkin24hs.com" -ForegroundColor White
Write-Host ""

# ==========================================
# PASO 7: VERIFICACION FINAL
# ==========================================
Write-Host "7. VERIFICACION FINAL" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Despues de implementar:" -ForegroundColor White
Write-Host ""
Write-Host "   [OK] El punto junto a 'webmail' debe estar VERDE" -ForegroundColor Green
Write-Host "   [OK] Los recursos deben mostrar valores > 0%" -ForegroundColor Green
Write-Host "   [OK] Al acceder a webmail.checkin24hs.com debe aparecer Roundcube" -ForegroundColor Green
Write-Host "   [OK] NO debe aparecer 'Bad Gateway' o '502'" -ForegroundColor Green
Write-Host ""

# ==========================================
# NOTA IMPORTANTE SOBRE PUERTOS
# ==========================================
Write-Host "[IMPORTANTE] NOTA SOBRE PUERTOS" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "   En EasyPanel, el puerto en 'Dominios' debe ser el puerto INTERNO:" -ForegroundColor White
Write-Host ""
Write-Host "   - Roundcube/Apache escucha en puerto 80 INTERNO (dentro del contenedor)" -ForegroundColor Gray
Write-Host "   - EasyPanel mapea automaticamente: puerto externo -> puerto interno" -ForegroundColor Gray
Write-Host "   - En 'Dominios', debes usar el puerto INTERNO (80)" -ForegroundColor Yellow
Write-Host "   - NO uses el puerto externo (8080) en 'Dominios'" -ForegroundColor Red
Write-Host ""
Write-Host "   Ejemplo correcto:" -ForegroundColor Green
Write-Host "   - Puerto en 'Dominios': 80 [OK]" -ForegroundColor Green
Write-Host "   - EasyPanel mapea: 8080:80 (externo:interno)" -ForegroundColor Gray
Write-Host ""

# ==========================================
# RESUMEN
# ==========================================
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   El error Bad Gateway (502) generalmente se debe a:" -ForegroundColor White
Write-Host ""
Write-Host "   1. [ERROR] Servicio detenido (punto rojo)" -ForegroundColor Red
Write-Host "      -> Solucion: Configurar recursos y hacer clic en 'Implementar'" -ForegroundColor Yellow
Write-Host ""
Write-Host "   2. [ERROR] Puerto incorrecto en 'Dominios' (8080 en lugar de 80)" -ForegroundColor Red
Write-Host "      -> Solucion: Cambiar puerto a 80 en 'Dominios'" -ForegroundColor Yellow
Write-Host ""
Write-Host "   3. [ERROR] Falta de memoria (recursos en 0)" -ForegroundColor Red
Write-Host "      -> Solucion: Aumentar memoria a 1024 MB minimo" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Una vez que el servicio este en VERDE y el puerto sea 80," -ForegroundColor White
Write-Host "   el error Bad Gateway deberia desaparecer." -ForegroundColor White
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
