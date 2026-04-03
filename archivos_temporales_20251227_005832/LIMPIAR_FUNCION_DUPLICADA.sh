#!/bin/bash
# Script para limpiar función duplicada y verificar todo

cd ~/checkin24hs/whatsapp-server

echo "=== Verificando funciones cleanChromeLocks ==="
grep -n "function cleanChromeLocks" whatsapp-server.js

echo ""
echo "=== Verificando que la función correcta esté siendo usada ==="
# Buscar la función que usa dataPath como parámetro
grep -A 5 "function cleanChromeLocks(dataPath)" whatsapp-server.js | head -6

echo ""
echo "=== Verificando directorios de sesión ==="
ls -la | grep wwebjs

echo ""
echo "=== Verificando logs recientes ==="
pm2 logs whatsapp-1 --lines 20 | tail -10

