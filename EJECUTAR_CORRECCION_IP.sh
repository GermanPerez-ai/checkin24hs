#!/bin/bash

echo "=========================================="
echo "🔧 EJECUTANDO CORRECCIÓN DE IP"
echo "=========================================="
echo ""

cd ~/checkin24hs

echo "1️⃣ Guardando cambios locales..."
git stash

echo ""
echo "2️⃣ Descargando cambios del repositorio..."
git pull origin main

echo ""
echo "3️⃣ Dando permisos de ejecución..."
chmod +x CORREGIR_IP_WEBMAIL_MANUAL.sh

echo ""
echo "4️⃣ Ejecutando corrección de IP..."
echo ""
./CORREGIR_IP_WEBMAIL_MANUAL.sh
