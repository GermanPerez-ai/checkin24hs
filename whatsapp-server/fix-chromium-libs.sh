#!/bin/sh
# Script para copiar librerías del sistema al Chromium de Puppeteer si es necesario

CHROMIUM_DIR="/app/node_modules/puppeteer-core/.local-chromium"
if [ -d "$CHROMIUM_DIR" ]; then
    # Buscar el directorio de Chromium descargado
    CHROME_DIR=$(find "$CHROMIUM_DIR" -type d -name "chrome-linux" | head -1)
    if [ ! -z "$CHROME_DIR" ]; then
        LIB_DIR="$CHROME_DIR/lib"
        mkdir -p "$LIB_DIR"
        
        # Copiar librerías necesarias del sistema
        for lib in libnss3.so libnssutil3.so libnspr4.so libssl3.so; do
            LIB_PATH=$(find /usr/lib -name "$lib*" 2>/dev/null | head -1)
            if [ ! -z "$LIB_PATH" ]; then
                cp "$LIB_PATH" "$LIB_DIR/" 2>/dev/null || true
            fi
        done
        
        # Establecer LD_LIBRARY_PATH para que Chromium encuentre las librerías
        export LD_LIBRARY_PATH="$LIB_DIR:$LD_LIBRARY_PATH"
    fi
fi

# Ejecutar el servidor
exec node /app/whatsapp-server.js

