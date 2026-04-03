#!/bin/bash

# Script para verificar que todas las conexiones de WhatsApp fueron eliminadas
# Ejecutar: bash VERIFICAR_ELIMINACION_COMPLETA.sh

echo "=========================================="
echo "  VERIFICACION DE ELIMINACION COMPLETA"
echo "=========================================="
echo ""

# 1. Verificar procesos PM2
echo "=== 1. PROCESOS PM2 ==="
PROCESOS_PM2=$(pm2 list | grep -c "whatsapp" || echo "0")
if [ "$PROCESOS_PM2" -eq "0" ]; then
    echo "✅ No hay procesos PM2 de WhatsApp"
else
    echo "⚠️  Procesos encontrados:"
    pm2 list | grep whatsapp
fi
echo ""

# 2. Verificar procesos activos
echo "=== 2. PROCESOS ACTIVOS ==="
PROCESOS_ACTIVOS=$(ps aux | grep -E "whatsapp-server|node.*whatsapp" | grep -v grep | wc -l)
if [ "$PROCESOS_ACTIVOS" -eq "0" ]; then
    echo "✅ No hay procesos activos de WhatsApp"
else
    echo "⚠️  Procesos encontrados:"
    ps aux | grep -E "whatsapp-server|node.*whatsapp" | grep -v grep
fi
echo ""

# 3. Verificar puertos
echo "=== 3. PUERTOS ==="
PUERTOS_EN_USO=0
for port in 3001 3002 3003 3004 4001 4002 4003 4004; do
    if lsof -ti:$port >/dev/null 2>&1 || netstat -tulpn 2>/dev/null | grep -q ":$port "; then
        echo "⚠️  Puerto $port: EN USO"
        PUERTOS_EN_USO=$((PUERTOS_EN_USO + 1))
    else
        echo "✅ Puerto $port: Libre"
    fi
done
echo ""

# 4. Verificar archivos de sesión
echo "=== 4. ARCHIVOS DE SESION ==="
ARCHIVOS_SESION=(
    "/root/checkin24hs/whatsapp-server/.wwebjs_auth"
    "/root/checkin24hs/whatsapp-server/.wwebjs_cache"
    "/root/checkin24hs/whatsapp-server/session"
    "/root/whatsapp-server/.wwebjs_auth"
    "/root/whatsapp-server/.wwebjs_cache"
    "/root/whatsapp-server/session"
)

ARCHIVOS_ENCONTRADOS=0
for archivo in "${ARCHIVOS_SESION[@]}"; do
    if [ -d "$archivo" ] || [ -f "$archivo" ]; then
        echo "⚠️  Encontrado: $archivo"
        ARCHIVOS_ENCONTRADOS=$((ARCHIVOS_ENCONTRADOS + 1))
    fi
done

if [ "$ARCHIVOS_ENCONTRADOS" -eq "0" ]; then
    echo "✅ No hay archivos de sesión"
fi
echo ""

# 5. Buscar otros archivos relacionados
echo "=== 5. BUSCAR OTROS ARCHIVOS RELACIONADOS ==="
OTROS_ARCHIVOS=$(find /root -name ".wwebjs*" -type d 2>/dev/null | wc -l)
if [ "$OTROS_ARCHIVOS" -eq "0" ]; then
    echo "✅ No se encontraron otros archivos .wwebjs"
else
    echo "⚠️  Archivos encontrados:"
    find /root -name ".wwebjs*" -type d 2>/dev/null
fi
echo ""

# 6. Resumen final
echo "=========================================="
echo "  RESUMEN FINAL"
echo "=========================================="
echo ""

TOTAL_PROBLEMAS=$((PROCESOS_PM2 + PROCESOS_ACTIVOS + PUERTOS_EN_USO + ARCHIVOS_ENCONTRADOS + OTROS_ARCHIVOS))

if [ "$TOTAL_PROBLEMAS" -eq "0" ]; then
    echo "✅ ✅ ✅ ELIMINACION COMPLETA ✅ ✅ ✅"
    echo ""
    echo "Todas las conexiones de WhatsApp han sido eliminadas correctamente."
    echo ""
    echo "Estado:"
    echo "  - Procesos PM2: ✅ Eliminados"
    echo "  - Procesos activos: ✅ Ninguno"
    echo "  - Puertos: ✅ Todos libres"
    echo "  - Archivos de sesión: ✅ Eliminados"
    echo ""
else
    echo "⚠️  Se encontraron $TOTAL_PROBLEMAS elementos que aún existen:"
    echo "  - Procesos PM2: $PROCESOS_PM2"
    echo "  - Procesos activos: $PROCESOS_ACTIVOS"
    echo "  - Puertos en uso: $PUERTOS_EN_USO"
    echo "  - Archivos de sesión: $ARCHIVOS_ENCONTRADOS"
    echo "  - Otros archivos: $OTROS_ARCHIVOS"
    echo ""
    echo "Ejecuta ELIMINAR_CONEXIONES_WHATSAPP.sh para limpiar completamente."
fi

echo ""




