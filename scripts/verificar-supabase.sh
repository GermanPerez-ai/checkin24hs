#!/bin/bash

# Script para verificar que Supabase está correctamente configurado
# Uso: bash scripts/verificar-supabase.sh [servidor|local]

MODE=${1:-local}

echo "=== Verificación de Supabase ($MODE) ==="
echo ""

if [ "$MODE" = "servidor" ]; then
    CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
    if [ -z "$CONTAINER_ID" ]; then
        echo "❌ No se encontró contenedor activo"
        exit 1
    fi
    
    echo "📦 Contenedor: $CONTAINER_ID"
    echo ""
    
    # 1. Verificar código de inicialización
    echo "1. Verificando código de inicialización..."
    if docker exec $CONTAINER_ID grep -q "createClient.*supabase-js" /app/server.js; then
        echo "   ✅ Código de inicialización presente"
    else
        echo "   ❌ Código de inicialización NO encontrado"
    fi
    
    # 2. Verificar orden de endpoints
    echo "2. Verificando orden de endpoints..."
    TEST_LINE=$(docker exec $CONTAINER_ID grep -n "app.get('/api/supabase/test'" /app/server.js | cut -d: -f1)
    TABLE_LINE=$(docker exec $CONTAINER_ID grep -n "app.get('/api/supabase/:table'" /app/server.js | cut -d: -f1)
    if [ ! -z "$TEST_LINE" ] && [ ! -z "$TABLE_LINE" ] && [ "$TEST_LINE" -lt "$TABLE_LINE" ]; then
        echo "   ✅ Orden correcto (test antes de :table)"
    else
        echo "   ❌ Orden incorrecto"
    fi
    
    # 3. Verificar módulo instalado
    echo "3. Verificando módulo @supabase/supabase-js..."
    if docker exec $CONTAINER_ID node -e "require('@supabase/supabase-js')" 2>/dev/null; then
        echo "   ✅ Módulo instalado"
    else
        echo "   ❌ Módulo NO instalado"
    fi
    
    # 4. Verificar variables de entorno
    echo "4. Verificando variables de entorno..."
    SUPABASE_URL=$(docker exec $CONTAINER_ID env | grep "^SUPABASE_URL=" | cut -d= -f2)
    SUPABASE_KEY=$(docker exec $CONTAINER_ID env | grep "^SUPABASE_SERVICE_KEY=" | cut -d= -f2)
    if [ ! -z "$SUPABASE_URL" ] && [ ! -z "$SUPABASE_KEY" ]; then
        echo "   ✅ Variables de entorno configuradas"
    else
        echo "   ❌ Variables de entorno NO configuradas"
    fi
    
    # 5. Verificar logs
    echo "5. Verificando logs del servidor..."
    if docker logs $CONTAINER_ID 2>&1 | tail -30 | grep -q "Cliente de Supabase inicializado"; then
        echo "   ✅ Cliente de Supabase inicializado"
    else
        echo "   ⚠️  No se encontró mensaje de inicialización en logs"
    fi
    
    # 6. Probar endpoint
    echo "6. Probando endpoint /api/supabase/test..."
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
        req.on('error', (e) => { console.error('ERROR:', e.message); });
        req.end();
        setTimeout(() => {}, 2000);
    " 2>&1 | tail -2)
    
    if echo "$RESPONSE" | grep -q "200" && echo "$RESPONSE" | grep -q "success"; then
        echo "   ✅ Endpoint funcionando correctamente"
    else
        echo "   ❌ Endpoint NO funciona"
        echo "   Respuesta: $RESPONSE"
    fi
    
else
    # Verificación local
    echo "1. Verificando código de inicialización..."
    if grep -q "createClient.*supabase-js" server.js; then
        echo "   ✅ Código de inicialización presente"
    else
        echo "   ❌ Código de inicialización NO encontrado"
    fi
    
    echo "2. Verificando orden de endpoints..."
    TEST_LINE=$(grep -n "app.get('/api/supabase/test'" server.js | cut -d: -f1)
    TABLE_LINE=$(grep -n "app.get('/api/supabase/:table'" server.js | cut -d: -f1)
    if [ ! -z "$TEST_LINE" ] && [ ! -z "$TABLE_LINE" ] && [ "$TEST_LINE" -lt "$TABLE_LINE" ]; then
        echo "   ✅ Orden correcto (test antes de :table)"
    else
        echo "   ❌ Orden incorrecto"
    fi
    
    echo "3. Verificando package.json..."
    if grep -q "@supabase/supabase-js" package.json; then
        echo "   ✅ Dependencia en package.json"
    else
        echo "   ❌ Dependencia NO encontrada en package.json"
    fi
    
    echo "4. Verificando módulo instalado localmente..."
    if node -e "require('@supabase/supabase-js')" 2>/dev/null; then
        echo "   ✅ Módulo instalado localmente"
    else
        echo "   ⚠️  Módulo NO instalado localmente (ejecuta: npm install)"
    fi
fi

echo ""
echo "=== Verificación completada ==="
