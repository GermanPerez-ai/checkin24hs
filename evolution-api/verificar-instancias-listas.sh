#!/bin/bash

cd /root/checkin24hs/evolution-api

API_KEY="checkin24hs-secret-key-2024"
BASE_URL="http://localhost:8081"

echo "🔍 VERIFICANDO ESTADO DEL SERVIDOR"
echo "==================================="
echo ""

echo "1️⃣  Verificando contenedor Evolution API..."
echo ""

if docker ps | grep -q evolution-api-checkin24hs; then
    echo "   ✅ Contenedor está corriendo"
    echo "   📋 Estado:"
    docker ps | grep evolution-api-checkin24hs
else
    echo "   ❌ Contenedor NO está corriendo"
    echo "   🔄 Iniciando contenedor..."
    docker-compose up -d
    sleep 5
fi
echo ""

echo "2️⃣  Verificando instancias existentes..."
echo ""

INSTANCES=$(curl -s -X GET ${BASE_URL}/instance/fetchInstances \
  -H "apikey: ${API_KEY}" 2>/dev/null)

if [ -z "$INSTANCES" ] || echo "$INSTANCES" | grep -q "error\|401\|403"; then
    echo "   ❌ Error al obtener instancias"
    echo "   📋 Respuesta: $INSTANCES"
else
    echo "   ✅ Instancias obtenidas correctamente"
    echo ""
    echo "   📱 Instancias encontradas:"
    echo "$INSTANCES" | grep -o '"instanceName":"[^"]*"' | \
      sed 's/"instanceName":"//g' | \
      sed 's/"//g' | \
      nl -w2 -s'. '
    echo ""
    
    # Verificar si existen las 4 instancias
    MISSING=0
    
    for i in 1 2 3 4; do
        INSTANCE_NAME="whatsapp-${i}"
        if echo "$INSTANCES" | grep -q "$INSTANCE_NAME"; then
            echo "   ✅ $INSTANCE_NAME existe"
        else
            echo "   ❌ $INSTANCE_NAME NO existe"
            MISSING=$((MISSING + 1))
        fi
    done
    
    echo ""
    
    # Crear instancias faltantes
    if [ $MISSING -gt 0 ]; then
        echo "3️⃣  Creando instancias faltantes..."
        echo ""
        
        for i in 1 2 3 4; do
            INSTANCE_NAME="whatsapp-${i}"
            if ! echo "$INSTANCES" | grep -q "$INSTANCE_NAME"; then
                echo "   📱 Creando $INSTANCE_NAME..."
                RESPONSE=$(curl -s -X POST ${BASE_URL}/instance/create \
                  -H "apikey: ${API_KEY}" \
                  -H "Content-Type: application/json" \
                  -d "{
                    \"instanceName\": \"$INSTANCE_NAME\",
                    \"qrcode\": true,
                    \"integration\": \"WHATSAPP-BAILEYS\"
                  }")
                
                if echo "$RESPONSE" | grep -q "error\|403"; then
                    echo "   ⚠️  Error al crear $INSTANCE_NAME"
                    echo "$RESPONSE" | head -3
                else
                    echo "   ✅ $INSTANCE_NAME creada"
                fi
                sleep 1
            fi
        done
    else
        echo "   ✅ Todas las instancias existen"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RESUMEN FINAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Estado del servidor:"
echo ""
echo "   🐳 Contenedor Evolution API: $(docker ps | grep -q evolution-api-checkin24hs && echo 'CORRIENDO' || echo 'DETENIDO')"
echo "   🌐 Panel web: http://72.61.58.240:8081/manager"
echo "   🔑 API Key: checkin24hs-secret-key-2024"
echo ""
echo "✅ Instancias listas para conectar:"
echo ""
for i in 1 2 3 4; do
    INSTANCE_NAME="whatsapp-${i}"
    if echo "$INSTANCES" | grep -q "$INSTANCE_NAME"; then
        echo "   ✅ $INSTANCE_NAME → Lista para teléfono número $i"
    else
        echo "   ❌ $INSTANCE_NAME → No existe"
    fi
done
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 PRÓXIMOS PASOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Abre el panel web:"
echo "   http://72.61.58.240:8081/manager"
echo ""
echo "2. Conecta cada número a su instancia:"
echo "   - whatsapp-1 → Escanear QR con teléfono número 1"
echo "   - whatsapp-2 → Escanear QR con teléfono número 2"
echo "   - whatsapp-3 → Escanear QR con teléfono número 3"
echo "   - whatsapp-4 → Escanear QR con teléfono número 4"
echo ""
echo "✅ Todo está listo para conectar los números"
echo ""
