#!/bin/bash

# Script para eliminar todas las conexiones de WhatsApp
# Ejecutar: bash ELIMINAR_CONEXIONES_WHATSAPP.sh

echo "=========================================="
echo "  ELIMINANDO CONEXIONES DE WHATSAPP"
echo "=========================================="
echo ""

# 1. Detener y eliminar procesos PM2
echo "=== 1. ELIMINANDO PROCESOS PM2 ==="
echo ""

# Verificar procesos existentes
pm2 list | grep -q "whatsapp" && {
    echo "📋 Procesos encontrados:"
    pm2 list | grep whatsapp
    echo ""
    
    echo "🛑 Deteniendo procesos..."
    pm2 stop whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4 2>/dev/null
    
    echo "🗑️  Eliminando procesos de PM2..."
    pm2 delete whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4 2>/dev/null
    
    echo "💾 Guardando configuración PM2..."
    pm2 save
    
    echo "✅ Procesos PM2 eliminados"
} || {
    echo "ℹ️  No se encontraron procesos PM2 de WhatsApp"
}

echo ""

# 2. Verificar y eliminar procesos que puedan estar corriendo de otra forma
echo "=== 2. VERIFICANDO PROCESOS ACTIVOS ==="
echo ""

# Buscar procesos de Node.js relacionados con WhatsApp
PROCESOS=$(ps aux | grep -E "whatsapp-server|node.*whatsapp" | grep -v grep | awk '{print $2}')

if [ ! -z "$PROCESOS" ]; then
    echo "⚠️  Procesos encontrados:"
    ps aux | grep -E "whatsapp-server|node.*whatsapp" | grep -v grep
    echo ""
    echo "🛑 Eliminando procesos..."
    echo "$PROCESOS" | xargs kill -9 2>/dev/null
    echo "✅ Procesos eliminados"
else
    echo "ℹ️  No se encontraron procesos activos"
fi

echo ""

# 3. Verificar puertos en uso
echo "=== 3. VERIFICANDO PUERTOS ==="
echo ""

for port in 3001 3002 3003 3004 4001 4002 4003 4004; do
    PID=$(lsof -ti:$port 2>/dev/null || netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1)
    if [ ! -z "$PID" ] && [ "$PID" != "-" ]; then
        echo "⚠️  Puerto $port en uso por proceso $PID"
        kill -9 $PID 2>/dev/null && echo "   ✅ Proceso eliminado" || echo "   ⚠️  No se pudo eliminar"
    else
        echo "✅ Puerto $port: Libre"
    fi
done

echo ""

# 4. Eliminar archivos de sesión
echo "=== 4. ELIMINANDO ARCHIVOS DE SESION ==="
echo ""

DIRECTORIOS_SESION=(
    "/root/checkin24hs/whatsapp-server/.wwebjs_auth"
    "/root/checkin24hs/whatsapp-server/.wwebjs_cache"
    "/root/checkin24hs/whatsapp-server/session"
    "/root/whatsapp-server/.wwebjs_auth"
    "/root/whatsapp-server/.wwebjs_cache"
    "/root/whatsapp-server/session"
)

for dir in "${DIRECTORIOS_SESION[@]}"; do
    if [ -d "$dir" ]; then
        echo "🗑️  Eliminando: $dir"
        rm -rf "$dir"
        echo "   ✅ Eliminado"
    else
        echo "ℹ️  No existe: $dir"
    fi
done

# Buscar y eliminar archivos de sesión en otros lugares comunes
find /root -name ".wwebjs*" -type d 2>/dev/null | while read dir; do
    if [ ! -z "$dir" ]; then
        echo "🗑️  Eliminando: $dir"
        rm -rf "$dir"
    fi
done

echo ""

# 5. Eliminar logs de PM2
echo "=== 5. ELIMINANDO LOGS ==="
echo ""

LOG_DIRS=(
    "/root/checkin24hs/whatsapp-server/logs"
    "/root/.pm2/logs"
)

for log_dir in "${LOG_DIRS[@]}"; do
    if [ -d "$log_dir" ]; then
        echo "🗑️  Eliminando logs en: $log_dir"
        rm -f "$log_dir"/*whatsapp* 2>/dev/null
        echo "   ✅ Logs eliminados"
    fi
done

echo ""

# 6. Resumen final
echo "=========================================="
echo "  RESUMEN"
echo "=========================================="
echo ""
echo "✅ Procesos PM2: Eliminados"
echo "✅ Procesos activos: Verificados y eliminados"
echo "✅ Puertos: Liberados"
echo "✅ Archivos de sesión: Eliminados"
echo "✅ Logs: Limpiados"
echo ""
echo "📋 Estado actual de PM2:"
pm2 list
echo ""
echo "⚠️  NOTA: Los datos en Supabase (whatsapp_cards) NO se eliminaron."
echo "   Para eliminarlos, ejecuta el SQL en CONSULTAR_CONEXIONES_WHATSAPP.sql"
echo ""




