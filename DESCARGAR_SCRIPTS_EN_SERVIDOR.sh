#!/bin/bash
# Script para descargar los scripts de actualización directamente en el servidor desde GitHub

echo "=========================================="
echo "📥 Descargar Scripts desde GitHub"
echo "=========================================="
echo ""

cd /root/checkin24hs/

echo "📥 Descargando scripts desde GitHub..."
echo ""

# Descargar ACTUALIZAR_COTIZADOR_FINAL.sh
echo "   📥 Descargando ACTUALIZAR_COTIZADOR_FINAL.sh..."
curl -L -o ACTUALIZAR_COTIZADOR_FINAL.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/ACTUALIZAR_COTIZADOR_FINAL.sh

if [ $? -eq 0 ]; then
    echo "      ✅ ACTUALIZAR_COTIZADOR_FINAL.sh descargado"
    chmod +x ACTUALIZAR_COTIZADOR_FINAL.sh
    echo "      ✅ Permisos configurados"
else
    echo "      ❌ Error al descargar ACTUALIZAR_COTIZADOR_FINAL.sh"
fi

echo ""

# Descargar RECORDATORIO_ACTUALIZAR_COTIZADOR.sh
echo "   📥 Descargando RECORDATORIO_ACTUALIZAR_COTIZADOR.sh..."
curl -L -o RECORDATORIO_ACTUALIZAR_COTIZADOR.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/RECORDATORIO_ACTUALIZAR_COTIZADOR.sh

if [ $? -eq 0 ]; then
    echo "      ✅ RECORDATORIO_ACTUALIZAR_COTIZADOR.sh descargado"
    chmod +x RECORDATORIO_ACTUALIZAR_COTIZADOR.sh
    echo "      ✅ Permisos configurados"
else
    echo "      ❌ Error al descargar RECORDATORIO_ACTUALIZAR_COTIZADOR.sh"
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "📋 Scripts disponibles en /root/checkin24hs/:"
ls -lh /root/checkin24hs/*.sh
echo ""
