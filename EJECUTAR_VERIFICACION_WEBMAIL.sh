#!/bin/bash

echo "=========================================="
echo "📥 DESCARGANDO Y EJECUTANDO VERIFICACIÓN"
echo "=========================================="
echo ""

cd ~/checkin24hs

echo "1️⃣ Descargando cambios del repositorio..."
git pull origin main

echo ""
echo "2️⃣ Dando permisos de ejecución..."
chmod +x VERIFICAR_WEBMAIL_TRAEFIK.sh
chmod +x CONFIGURAR_WEBMAIL_HTTPS.sh

echo ""
echo "3️⃣ Ejecutando verificación..."
echo ""
./VERIFICAR_WEBMAIL_TRAEFIK.sh
