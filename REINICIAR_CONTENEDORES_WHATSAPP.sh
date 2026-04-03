#!/bin/bash
# Script para reiniciar todos los contenedores whatsapp

echo "=== REINICIANDO CONTENEDORES WHATSAPP ==="
echo ""

# Reiniciar todos los contenedores whatsapp
docker ps --filter "name=whatsapp" --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        echo "🔄 Reiniciando $container..."
        docker restart $container
        echo "✅ Reiniciado $container"
        echo ""
    fi
done

echo "✅✅✅ TODOS LOS CONTENEDORES REINICIADOS ✅✅✅"
echo ""
echo "Espera 10-15 segundos y luego revisa los logs con:"
echo "docker logs -f checkin24hs_whatsapp.1.wy1zd6fu5x7zn8mqw5b2929r5"








