#!/bin/bash
# Script para limpiar la sesión de WhatsApp bloqueada (Linux/Mac)

echo "🧹 Limpiando sesión de WhatsApp..."

# Directorio de sesión
SESSION_DIR=".wwebjs_auth"

# Eliminar archivos de lock
if [ -d "$SESSION_DIR" ]; then
    echo "📋 Eliminando archivos de lock..."
    
    # Eliminar archivos de lock específicos
    rm -f "$SESSION_DIR/Default/SingletonLock" 2>/dev/null
    rm -f "$SESSION_DIR/Default/SingletonSocket" 2>/dev/null
    rm -f "$SESSION_DIR/Default/SingletonCookie" 2>/dev/null
    
    # Eliminar otros archivos de lock
    find "$SESSION_DIR/Default" -name "*Lock*" -o -name "*Singleton*" 2>/dev/null | xargs rm -f 2>/dev/null
    
    echo "✅ Archivos de lock eliminados."
else
    echo "⚠️  Directorio de sesión no encontrado."
fi

# Matar procesos de Chrome/Puppeteer si existen
echo "🔍 Buscando procesos de Chrome/Puppeteer..."
pkill -f "chromium" 2>/dev/null
pkill -f "chrome" 2>/dev/null
pkill -f "puppeteer" 2>/dev/null

echo "✅ Limpieza completada."

# Opción para limpiar toda la sesión
if [ "$1" == "--clear-all" ]; then
    echo "🗑️  Eliminando toda la sesión..."
    rm -rf "$SESSION_DIR"
    echo "✅ Sesión completa eliminada. Necesitarás escanear el QR nuevamente."
fi

echo "✅ Puedes reiniciar el servidor ahora."

