#!/bin/bash
# Script para subir cambios de la ruta /og-cotizar.jpg
# Ejecuta este script desde la raíz del proyecto

echo "🔧 Preparando cambios para subir..."

# Cambiar al directorio del proyecto
cd ~/Checkin24hs || cd /root/Checkin24hs || cd "$(dirname "$0")"

# Eliminar archivo de bloqueo si existe
if [ -f .git/index.lock ]; then
    echo "⚠️ Eliminando archivo de bloqueo..."
    rm -f .git/index.lock
fi

# Agregar archivos modificados
echo "📦 Agregando archivos al staging..."
git add checkin24hs-admin/server.js
git add checkin24hs-admin/Dockerfile
git add cotizador-cliente.html
git add server.js
git add AGREGAR_RUTA_OG_IMAGE_DASHBOARD.md

# Verificar qué se agregó
echo ""
echo "📋 Archivos en staging:"
git status --short

# Hacer commit
echo ""
echo "💾 Creando commit..."
git commit -m "Agregar ruta /og-cotizar.jpg en dashboard para preview de Open Graph/WhatsApp

- Agregada ruta /og-cotizar.jpg en checkin24hs-admin/server.js
- Actualizado Dockerfile para copiar server.js real
- Actualizados metadatos Open Graph en cotizador-cliente.html
- Agregada ruta /og-cotizar.jpg también en server.js principal"

# Subir a GitHub
echo ""
echo "🚀 Subiendo cambios a GitHub..."
git push origin main

echo ""
echo "✅ ¡Cambios subidos exitosamente!"
echo ""
echo "📝 Próximos pasos:"
echo "1. Ve a EasyPanel"
echo "2. Abre el servicio del dashboard"
echo "3. Haz clic en 'Redeploy' o 'Reconstruir'"
echo "4. Espera 2-5 minutos a que termine"
echo "5. Verifica: https://dashboard.checkin24hs.com/og-cotizar.jpg"
