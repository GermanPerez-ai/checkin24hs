#!/bin/bash

echo "=========================================="
echo "🔧 RESOLVIENDO GIT Y ACTUALIZANDO IP"
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
chmod +x ACTUALIZAR_IP_WEBMAIL_TRAEFIK.sh

echo ""
echo "4️⃣ Ejecutando actualización de IP..."
echo ""
./ACTUALIZAR_IP_WEBMAIL_TRAEFIK.sh
