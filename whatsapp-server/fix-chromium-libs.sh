#!/bin/sh
# Script para copiar librerías del sistema al Chromium de Puppeteer si es necesario

# Establecer LD_LIBRARY_PATH globalmente para que todas las librerías del sistema sean accesibles
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:/usr/lib:$LD_LIBRARY_PATH"

# Función para copiar librerías cuando Chromium se descargue
copy_libs_to_chromium() {
    CHROMIUM_DIR="/app/node_modules/puppeteer-core/.local-chromium"
    if [ -d "$CHROMIUM_DIR" ]; then
        # Buscar el directorio de Chromium descargado
        CHROME_DIR=$(find "$CHROMIUM_DIR" -type d -name "chrome-linux" 2>/dev/null | head -1)
        if [ ! -z "$CHROME_DIR" ]; then
            LIB_DIR="$CHROME_DIR/lib"
            mkdir -p "$LIB_DIR"
            
            # Copiar librerías necesarias del sistema
            for lib in libnss3.so libnssutil3.so libnspr4.so libssl3.so; do
                LIB_PATH=$(find /usr/lib/x86_64-linux-gnu /lib/x86_64-linux-gnu /usr/lib -name "$lib*" 2>/dev/null | head -1)
                if [ ! -z "$LIB_PATH" ]; then
                    cp "$LIB_PATH" "$LIB_DIR/" 2>/dev/null || true
                    # También crear symlinks si es necesario
                    ln -sf "$LIB_PATH" "$LIB_DIR/$(basename $LIB_PATH)" 2>/dev/null || true
                fi
            done
            
            # Establecer LD_LIBRARY_PATH específico para Chromium
            export LD_LIBRARY_PATH="$LIB_DIR:$LD_LIBRARY_PATH"
        fi
    fi
}

# Intentar copiar librerías antes de iniciar (por si ya están descargadas)
copy_libs_to_chromium

# Ejecutar el servidor (el código de Node.js manejará la descarga de Chromium)
exec node /app/whatsapp-server.js

