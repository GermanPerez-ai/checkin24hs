#!/bin/bash
# Script de verificación completa - Ejecutar en el servidor

echo "🔍 VERIFICACIÓN COMPLETA DE CAMBIOS"
echo "===================================="
echo ""

echo "1️⃣ Verificando mensajes de directorio de sesión..."
echo "---------------------------------------------------"
for i in 1 2 3 4; do
    echo "whatsapp-$i:"
    pm2 logs whatsapp-$i --lines 50 2>/dev/null | grep "directorio de sesión" | tail -1
done
echo ""

echo "2️⃣ Verificando errores de SingletonLock..."
echo "---------------------------------------------------"
for i in 1 2 3 4; do
    echo "whatsapp-$i errores:"
    pm2 logs whatsapp-$i --err --lines 50 2>/dev/null | grep -i "singleton\|lock\|failed" | tail -3
    if [ $? -ne 0 ]; then
        echo "  ✅ Sin errores de SingletonLock"
    fi
done
echo ""

echo "3️⃣ Verificando directorios creados..."
echo "---------------------------------------------------"
ls -la | grep wwebjs
echo ""

echo "4️⃣ Estado de servicios..."
echo "---------------------------------------------------"
pm2 status
echo ""

echo "5️⃣ Verificando que dataPath está correcto en el código..."
echo "---------------------------------------------------"
grep -n "dataPath: sessionDataPath" whatsapp-server.js
echo ""

echo "✅ Verificación completada!"

