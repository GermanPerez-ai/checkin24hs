#!/bin/bash

echo "=========================================="
echo "🔄 Reconfigurar WhatsApp - Nuevos Puertos"
echo "=========================================="
echo ""

# 1. Detener y eliminar servicios actuales
echo "=== 1. Deteniendo servicios WhatsApp actuales ==="
pm2 stop whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4 2>/dev/null
pm2 delete whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4 2>/dev/null
echo "✅ Servicios eliminados"
echo ""

# 2. Verificar puertos en uso
echo "=== 2. Verificando puertos en uso ==="
echo "Puertos actuales ocupados:"
netstat -tulpn 2>/dev/null | grep -E ':(3001|3002|3003|3004|3010|3000|8080)' || ss -tulpn 2>/dev/null | grep -E ':(3001|3002|3003|3004|3010|3000|8080)' || echo "No se encontraron puertos ocupados"
echo ""

# 3. Verificar puertos disponibles (sugeridos: 4001-4004)
echo "=== 3. Verificando puertos disponibles (4001-4004) ==="
NEW_PORTS=(4001 4002 4003 4004)
AVAILABLE_PORTS=()

for port in "${NEW_PORTS[@]}"; do
    if netstat -tulpn 2>/dev/null | grep -q ":$port " || ss -tulpn 2>/dev/null | grep -q ":$port "; then
        echo "❌ Puerto $port: OCUPADO"
    else
        echo "✅ Puerto $port: DISPONIBLE"
        AVAILABLE_PORTS+=($port)
    fi
done
echo ""

# 4. Si hay puertos disponibles, actualizar configuración
if [ ${#AVAILABLE_PORTS[@]} -eq 4 ]; then
    echo "=== 4. Actualizando configuración de WhatsApp ==="
    cd ~/checkin24hs/whatsapp-server || cd /root/checkin24hs/whatsapp-server || { echo "❌ No se encontró el directorio whatsapp-server"; exit 1; }
    
    # Actualizar ecosystem.config.js
    echo "Actualizando ecosystem.config.js..."
    cat > ecosystem.config.js << 'EOF'
// Configuración PM2 para múltiples instancias de WhatsApp
module.exports = {
  apps: [
    {
      name: 'whatsapp-1',
      script: './whatsapp-server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 4001,
        INSTANCE_NUMBER: 1,
        NODE_ENV: 'production',
        SUPABASE_URL: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4',
        PUPPETEER_EXECUTABLE_PATH: '/usr/bin/chromium-browser'
      },
      error_file: './logs/whatsapp-1-error.log',
      out_file: './logs/whatsapp-1-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G'
    },
    {
      name: 'whatsapp-2',
      script: './whatsapp-server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 4002,
        INSTANCE_NUMBER: 2,
        NODE_ENV: 'production',
        SUPABASE_URL: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4',
        PUPPETEER_EXECUTABLE_PATH: '/usr/bin/chromium-browser'
      },
      error_file: './logs/whatsapp-2-error.log',
      out_file: './logs/whatsapp-2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G'
    },
    {
      name: 'whatsapp-3',
      script: './whatsapp-server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 4003,
        INSTANCE_NUMBER: 3,
        NODE_ENV: 'production',
        SUPABASE_URL: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4',
        PUPPETEER_EXECUTABLE_PATH: '/usr/bin/chromium-browser'
      },
      error_file: './logs/whatsapp-3-error.log',
      out_file: './logs/whatsapp-3-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G'
    },
    {
      name: 'whatsapp-4',
      script: './whatsapp-server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 4004,
        INSTANCE_NUMBER: 4,
        NODE_ENV: 'production',
        SUPABASE_URL: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4',
        PUPPETEER_EXECUTABLE_PATH: '/usr/bin/chromium-browser'
      },
      error_file: './logs/whatsapp-4-error.log',
      out_file: './logs/whatsapp-4-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G'
    }
  ]
};
EOF
    
    echo "✅ ecosystem.config.js actualizado con puertos 4001-4004"
    echo ""
    
    # 5. Asegurar que el servidor escuche en 0.0.0.0
    echo "=== 5. Verificando configuración del servidor ==="
    if ! grep -q "server.listen(CONFIG.PORT, '0.0.0.0'" whatsapp-server.js; then
        echo "Corrigiendo configuración del servidor..."
        sed -i "s/server.listen(CONFIG.PORT/server.listen(CONFIG.PORT, '0.0.0.0'/g" whatsapp-server.js
        echo "✅ Configuración corregida"
    else
        echo "✅ El servidor ya está configurado correctamente"
    fi
    echo ""
    
    # 6. Iniciar servicios con nuevos puertos
    echo "=== 6. Iniciando servicios con nuevos puertos ==="
    pm2 start ecosystem.config.js --only whatsapp-1
    sleep 3
    pm2 start ecosystem.config.js --only whatsapp-2
    sleep 3
    pm2 start ecosystem.config.js --only whatsapp-3
    sleep 3
    pm2 start ecosystem.config.js --only whatsapp-4
    sleep 3
    echo ""
    
    # 7. Guardar configuración
    echo "=== 7. Guardando configuración ==="
    pm2 save
    echo "✅ Configuración guardada"
    echo ""
    
    # 8. Verificar estado
    echo "=== 8. Verificando estado final ==="
    pm2 list | grep whatsapp
    echo ""
    
    echo "=== 9. Verificando puertos activos ==="
    for port in 4001 4002 4003 4004; do
        if netstat -tulpn 2>/dev/null | grep -q ":$port " || ss -tulpn 2>/dev/null | grep -q ":$port "; then
            echo "✅ Puerto $port: ACTIVO"
        else
            echo "❌ Puerto $port: INACTIVO"
        fi
    done
    echo ""
    
    # 9. Probar acceso
    echo "=== 10. Probando acceso a los servicios ==="
    HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    for port in 4001 4002 4003 4004; do
        echo -n "Puerto $port: "
        if curl -s --max-time 3 "http://$HOST_IP:$port/api/status" > /dev/null 2>&1; then
            echo "✅ Funciona"
        else
            echo "❌ No responde"
        fi
    done
    echo ""
    
    echo "=========================================="
    echo "✅ Reconfiguración completada"
    echo "=========================================="
    echo ""
    echo "📱 Nuevos puertos configurados:"
    echo "   - WhatsApp-1: Puerto 4001"
    echo "   - WhatsApp-2: Puerto 4002"
    echo "   - WhatsApp-3: Puerto 4003"
    echo "   - WhatsApp-4: Puerto 4004"
    echo ""
    echo "⚠️ IMPORTANTE: Actualiza la URL en el dashboard a: http://72.61.58.240"
    echo "   El sistema automáticamente usará los puertos 4001-4004"
    echo ""
    
else
    echo "❌ No hay suficientes puertos disponibles"
    echo "Puertos disponibles: ${AVAILABLE_PORTS[@]}"
    echo "Se necesitan 4 puertos libres"
fi

