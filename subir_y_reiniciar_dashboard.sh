#!/bin/bash
# Subir dashboard.html al servidor y reiniciar servicio (Docker).
# Ejecutar desde tu PC (Git Bash o WSL). Alternativa: SUBIR_DASHBOARD_AL_SERVIDOR.ps1 en PowerShell.

SERVIDOR="${1:-root@srv1152402.hstgr.cloud}"
RUTA_LOCAL="$(cd "$(dirname "$0")" && pwd)"
RUTA_SERVIDOR="/root/checkin24hs"

echo "=========================================="
echo "  Subir dashboard al servidor"
echo "=========================================="
echo ""
echo "Servidor: $SERVIDOR"
echo ""

# Subir dashboard.html
echo "1. Subiendo dashboard.html..."
scp "$RUTA_LOCAL/dashboard.html" "${SERVIDOR}:${RUTA_SERVIDOR}/dashboard.html" || { echo "Error al subir"; exit 1; }
echo "   OK"
echo ""

# Subir supabase-client.js si existe
if [ -f "$RUTA_LOCAL/supabase-client.js" ]; then
    echo "2. Subiendo supabase-client.js..."
    scp "$RUTA_LOCAL/supabase-client.js" "${SERVIDOR}:${RUTA_SERVIDOR}/supabase-client.js" 2>/dev/null && echo "   OK" || echo "   (omitido)"
else
    echo "2. supabase-client.js no encontrado (omitido)"
fi
echo ""

# Subir script de actualización si existe
if [ -f "$RUTA_LOCAL/ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh" ]; then
    echo "3. Subiendo ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh..."
    scp "$RUTA_LOCAL/ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh" "${SERVIDOR}:${RUTA_SERVIDOR}/" 2>/dev/null && echo "   OK" || echo "   (omitido)"
fi
echo ""

# Aplicar en servidor: reiniciar servicio Docker
echo "4. Reiniciando servicio en servidor..."
ssh "$SERVIDOR" "cd $RUTA_SERVIDOR && (test -f ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh && chmod +x ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh && ./ACTUALIZAR_DASHBOARD_DESPUES_SUBIR.sh) || (docker service update --force checkin24hs_dashboard 2>/dev/null; echo 'Servicio reiniciado')"
echo ""

echo "=========================================="
echo "  Listo"
echo "=========================================="
echo ""
echo "Verificar: https://dashboard.checkin24hs.com (Ctrl+Shift+R para evitar cache)"
echo ""
echo "Uso: ./subir_y_reiniciar_dashboard.sh [usuario@host]"
echo "     Por defecto: root@srv1152402.hstgr.cloud"
echo ""
