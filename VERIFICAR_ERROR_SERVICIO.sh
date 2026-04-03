#!/bin/bash
# Script para verificar el error del servicio de WhatsApp

echo "=========================================="
echo "VERIFICAR ERROR DEL SERVICIO"
echo "=========================================="
echo ""

# Buscar el último contenedor que falló
LAST_CONTAINER=$(docker ps -a | grep whatsapp | grep "Exited\|Failed" | head -1 | awk '{print $1}')

if [ -z "$LAST_CONTAINER" ]; then
    echo "⚠️ No se encontró contenedor que haya fallado"
    echo ""
    echo "Buscando contenedores recientes:"
    docker ps -a | grep whatsapp | head -5
    exit 1
fi

echo "Último contenedor que falló: $LAST_CONTAINER"
echo ""

# Ver logs completos
echo "=== LOGS COMPLETOS (últimas 100 líneas) ==="
echo ""
docker logs $LAST_CONTAINER --tail 100 2>&1
echo ""

# Buscar errores específicos
echo "=== ERRORES ENCONTRADOS ==="
echo ""
docker logs $LAST_CONTAINER 2>&1 | grep -iE "error|fatal|exception|ReferenceError|is not defined" | tail -20
echo ""

# Verificar si el error de isSyncingAppState persiste
echo "=== VERIFICAR ERROR isSyncingAppState ==="
echo ""
ERROR_IS_SYNCING=$(docker logs $LAST_CONTAINER 2>&1 | grep -i "isSyncingAppState is not defined")
if [ -n "$ERROR_IS_SYNCING" ]; then
    echo "❌ El error persiste:"
    echo "$ERROR_IS_SYNCING"
    echo ""
    echo "El archivo en el contenedor no tiene la corrección."
    echo "Necesitas copiar el archivo corregido al contenedor antes de reiniciar."
else
    echo "✅ No se encontró el error de isSyncingAppState"
    echo "   Puede haber otro error. Revisa los logs arriba."
fi
echo ""

echo "=========================================="
