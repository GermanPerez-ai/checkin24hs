#!/bin/bash

echo "=========================================="
echo "🔧 RESOLVIENDO GIT Y CONFIGURANDO TRAEFIK"
echo "=========================================="
echo ""

# 1. Guardar cambios locales temporalmente
echo "1️⃣ Guardando cambios locales..."
git stash

# 2. Hacer pull
echo ""
echo "2️⃣ Actualizando desde GitHub..."
git pull origin main

# 3. Dar permisos al script
echo ""
echo "3️⃣ Configurando permisos..."
chmod +x CONFIGURAR_TRAEFIK_WHATSAPP_1.sh

# 4. Ejecutar script de configuración
echo ""
echo "4️⃣ Ejecutando configuración de Traefik..."
./CONFIGURAR_TRAEFIK_WHATSAPP_1.sh

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
