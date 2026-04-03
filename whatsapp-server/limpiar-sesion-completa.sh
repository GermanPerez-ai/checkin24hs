#!/bin/bash
# 🧹 Script para Limpiar Completamente la Sesión de WhatsApp
# 
# Este script limpia la sesión y prepara todo para una nueva conexión

INSTANCE="${1:-1}"
AUTH_DIR="auth_info_baileys_${INSTANCE}"

echo "=============================================================="
echo "🧹 LIMPIEZA COMPLETA DE SESIÓN WHATSAPP"
echo "=============================================================="
echo ""
echo "📱 Instancia: ${INSTANCE}"
echo "📁 Directorio: ${AUTH_DIR}"
echo ""

# Verificar si estamos en un contenedor Docker
if [ -f /.dockerenv ] || [ -n "$DOCKER_CONTAINER" ]; then
    echo "🐳 Detectado: Ejecutándose en contenedor Docker"
    BASE_DIR="/app"
else
    echo "💻 Detectado: Ejecutándose en servidor local"
    BASE_DIR="."
fi

AUTH_PATH="${BASE_DIR}/${AUTH_DIR}"

echo "🔍 Buscando sesión en: ${AUTH_PATH}"
echo ""

# Verificar si existe
if [ -d "$AUTH_PATH" ]; then
    echo "📂 Sesión encontrada. Contenido:"
    ls -la "$AUTH_PATH" 2>/dev/null | head -10
    echo ""
    
    # Calcular tamaño
    SIZE=$(du -sh "$AUTH_PATH" 2>/dev/null | cut -f1)
    echo "💾 Tamaño: ${SIZE}"
    echo ""
    
    # Confirmar
    echo "⚠️  ADVERTENCIA: Esto eliminará completamente la sesión."
    echo "   Necesitarás escanear el QR nuevamente después de reiniciar."
    echo ""
    read -p "¿Continuar? (s/N): " CONFIRM
    
    if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
        echo "❌ Operación cancelada"
        exit 0
    fi
    
    echo ""
    echo "🗑️  Eliminando sesión..."
    
    # Eliminar recursivamente
    rm -rf "$AUTH_PATH" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Sesión eliminada exitosamente"
    else
        echo "❌ Error eliminando sesión"
        echo ""
        echo "💡 Intenta manualmente:"
        echo "   rm -rf ${AUTH_PATH}"
        exit 1
    fi
else
    echo "ℹ️  No se encontró sesión en ${AUTH_PATH}"
    echo "   (Esto es normal si nunca se ha conectado antes)"
fi

echo ""
echo "=============================================================="
echo "✅ LIMPIEZA COMPLETADA"
echo "=============================================================="
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo ""
echo "1. Reinicia el servicio de WhatsApp:"
if [ -f /.dockerenv ] || [ -n "$DOCKER_CONTAINER" ]; then
    echo "   (El servicio se reiniciará automáticamente si está en Docker)"
else
    echo "   docker service update --force checkin24hs_whatsapp"
    echo "   # O si usas PM2:"
    echo "   pm2 restart whatsapp-${INSTANCE}"
fi
echo ""
echo "2. Espera 30-60 segundos para que se genere un nuevo QR"
echo ""
echo "3. EN TU TELÉFONO:"
echo "   - Ve a WhatsApp → Configuración → Dispositivos vinculados"
echo "   - Desconecta TODAS las sesiones de WhatsApp Web"
echo "   - Cierra completamente WhatsApp"
echo "   - Vuelve a abrir WhatsApp"
echo ""
echo "4. Escanea el nuevo QR INMEDIATAMENTE (expira en 2 minutos)"
echo ""
echo "5. Si usas WiFi, prueba con DATOS MÓVILES para escanear"
echo ""
echo "💡 IMPORTANTE:"
echo "   - Escanea el QR dentro de 2 minutos"
echo "   - No cierres WhatsApp durante la autenticación"
echo "   - Espera pacientemente (puede tardar 2-5 minutos)"
echo ""
