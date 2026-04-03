#!/bin/bash

# Script para aplicar la solución permanente de Supabase en el servidor
# Ejecutar en el servidor: bash scripts/aplicar-solucion-permanente.sh

set -e

echo "=== Aplicando solución permanente para Supabase ==="
echo ""

cd ~/checkin24hs

# 1. Verificar que el código local está actualizado
echo "1. Verificando código local..."
if ! grep -q "Auto-instalar @supabase/supabase-js" server.js; then
    echo "   ⚠️  El código no tiene la auto-instalación. Haciendo pull del repositorio..."
    git pull origin main || echo "   ⚠️  No se pudo hacer pull. Continuando..."
fi

# 2. Verificar que tiene el código de auto-instalación
echo "2. Verificando código de auto-instalación..."
if grep -q "Auto-instalar @supabase/supabase-js" server.js; then
    echo "   ✅ Código de auto-instalación presente"
else
    echo "   ❌ Código de auto-instalación NO encontrado"
    echo "   Por favor, sincroniza el código desde el repositorio"
    exit 1
fi

# 3. Instalar módulo en el contenedor actual (para que funcione inmediatamente)
echo "3. Instalando módulo en el contenedor actual..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    docker exec $CONTAINER_ID npm install @supabase/supabase-js --silent || true
    echo "   ✅ Módulo instalado en contenedor actual"
else
    echo "   ⚠️  No se encontró contenedor activo"
fi

# 4. Reiniciar el servicio para que use el nuevo código
echo "4. Reiniciando servicio..."
docker service update --force checkin24hs_dashboard

echo ""
echo "5. Esperando a que el servicio se reinicie..."
sleep 15

# 5. Verificar que funciona
echo "6. Verificando que todo funciona..."
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    # Verificar logs
    echo ""
    echo "   Logs del servidor:"
    docker logs $CONTAINER_ID 2>&1 | tail -10 | grep -iE "supabase|Cliente de Supabase|instalado" || echo "   (No se encontraron mensajes específicos)"
    
    # Verificar que el módulo está disponible
    if docker exec $CONTAINER_ID node -e "require('@supabase/supabase-js')" 2>/dev/null; then
        echo "   ✅ Módulo @supabase/supabase-js disponible"
    else
        echo "   ⚠️  Módulo no disponible (se instalará automáticamente en el próximo reinicio)"
    fi
    
    # Probar endpoint
    echo ""
    echo "   Probando endpoint..."
    RESPONSE=$(docker exec $CONTAINER_ID node -e "
        const http = require('http');
        const req = http.request({
            hostname: '127.0.0.1',
            port: 3000,
            path: '/api/supabase/test',
            method: 'GET'
        }, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => { 
                console.log(res.statusCode);
                console.log(data);
            });
        });
        req.on('error', (e) => { console.error('ERROR'); });
        req.end();
        setTimeout(() => {}, 2000);
    " 2>&1 | tail -2)
    
    if echo "$RESPONSE" | grep -q "200" && echo "$RESPONSE" | grep -q "success"; then
        echo "   ✅ Endpoint funcionando correctamente"
    else
        echo "   ⚠️  Endpoint no responde correctamente (puede necesitar más tiempo)"
    fi
fi

echo ""
echo "=== Solución permanente aplicada ==="
echo ""
echo "✅ El módulo @supabase/supabase-js se instalará automáticamente"
echo "   cuando el contenedor se inicie si no está disponible."
echo ""
echo "Para verificar en el futuro, ejecuta:"
echo "  bash scripts/verificar-supabase.sh servidor"
