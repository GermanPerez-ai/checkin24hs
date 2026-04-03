#!/bin/bash
# Comando rápido para corregir la verificación de estado en el script

sed -i 's/if \[ "$SERVICE_STATUS" != "Running" \]; then/if echo "$SERVICE_STATUS" | grep -q "Running"; then\n    echo "✅ Servicio está corriendo"\nelse\n    # El servicio NO está corriendo/' REVISAR_Y_ACTUALIZAR_DASHBOARD.sh

# Mejor opción: reemplazar toda la sección de verificación
cat > /tmp/fix_status_check.sh << 'FIX_END'
#!/bin/bash
# Fix temporal para el script

sed -i '/# 2. Verificar estado del servicio/,/echo "✅ Servicio está corriendo"/c\
# 2. Verificar estado del servicio\
echo "2️⃣ Verificando estado del servicio..."\
SERVICE_STATUS=$(docker service ps "$DASHBOARD_SERVICE" --no-trunc --format "{{.CurrentState}}" | head -1)\
echo "   Estado: $SERVICE_STATUS"\
\
# Verificar si el estado contiene "Running" (puede ser "Running" o "Running X seconds ago")\
if echo "$SERVICE_STATUS" | grep -q "Running"; then\
    echo "✅ Servicio está corriendo"\
else\
    echo "⚠️ El servicio NO está corriendo"\
    echo "   Estado actual: $SERVICE_STATUS"\
    echo ""\
    echo "📋 Tareas del servicio:"\
    docker service ps "$DASHBOARD_SERVICE" --no-trunc | head -5\
    echo ""\
    echo "❓ ¿Deseas intentar reiniciar el servicio? (esto puede tardar varios minutos)"\
    echo "   Ejecuta: docker service update --force $DASHBOARD_SERVICE"\
    exit 1\
fi\
\
echo ""
' REVISAR_Y_ACTUALIZAR_DASHBOARD.sh

FIX_END

echo "✅ Comando de corrección creado"
echo "   Ejecuta: bash /tmp/fix_status_check.sh"
