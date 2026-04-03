#!/bin/bash
# Verificar y reiniciar el servicio dashboard

echo "🔍 Verificando que el archivo se actualizó correctamente..."

# Verificar que tiene la nueva función
if grep -q "MODO TEMPORAL: Acceso sin autenticación habilitado" /etc/easypanel/projects/checkin24hs/dashboard/code/dashboard.html; then
    echo "✅ Archivo actualizado correctamente"
else
    echo "⚠️  El archivo podría no tener la última versión"
fi

echo ""
echo "🔄 Para aplicar los cambios, necesitas reiniciar el servicio dashboard desde EasyPanel"
echo ""
echo "O ejecuta (si tienes permisos):"
echo "   docker service update --force checkin24hs_dashboard"
echo ""
echo "Luego espera 30-60 segundos y prueba acceder a: https://dashboard.checkin24hs.com"
