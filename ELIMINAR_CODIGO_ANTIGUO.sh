#!/bin/bash
# Script para eliminar código antiguo del servidor

cd ~/checkin24hs/whatsapp-server

echo "🔧 Eliminando código antiguo..."

# Backup
cp whatsapp-server.js whatsapp-server.js.backup.antes_limpieza

# Encontrar líneas de la función antigua
INICIO_FUNC=$(grep -n "^function cleanChromeLocks() {" whatsapp-server.js | head -1 | cut -d: -f1)
if [ -z "$INICIO_FUNC" ]; then
    INICIO_FUNC=$(grep -n "function cleanChromeLocks()" whatsapp-server.js | head -1 | cut -d: -f1)
fi

if [ -n "$INICIO_FUNC" ]; then
    # Encontrar el final de la función (buscar el cierre })
    FIN_FUNC=$(sed -n "${INICIO_FUNC},/^}$/p" whatsapp-server.js | grep -n "^}$" | tail -1 | cut -d: -f1)
    if [ -n "$FIN_FUNC" ]; then
        FIN_FUNC=$((INICIO_FUNC + FIN_FUNC - 1))
        echo "Eliminando función antigua (líneas $INICIO_FUNC a $FIN_FUNC)"
        sed -i "${INICIO_FUNC},${FIN_FUNC}d" whatsapp-server.js
    fi
fi

# Eliminar línea con sessionPath antiguo
sed -i '/const sessionPath = `\.wwebjs_auth_instance_${CONFIG\.INSTANCE_NUMBER}`;/d' whatsapp-server.js

# Eliminar llamada a función antigua sin parámetros
sed -i '/^cleanChromeLocks();$/d' whatsapp-server.js

# Verificar que se eliminó
echo ""
echo "✅ Verificando eliminación..."
grep -n "_instance_" whatsapp-server.js
if [ $? -eq 0 ]; then
    echo "⚠️  Aún hay referencias a _instance_"
else
    echo "✅ Código antiguo eliminado"
fi

echo ""
echo "✅ Limpieza completada!"

