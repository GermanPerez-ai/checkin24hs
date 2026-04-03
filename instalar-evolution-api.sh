#!/bin/bash
# Script para instalar Evolution API en el servidor

set -e

echo "🚀 INSTALANDO EVOLUTION API"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# Crear carpeta
echo "1️⃣  Creando carpeta evolution-api..."
mkdir -p evolution-api
cd evolution-api

# Crear docker-compose.yml
echo "2️⃣  Creando docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  evolution-api:
    image: atendai/evolution-api:latest
    container_name: evolution-api-checkin24hs
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      DATABASE_ENABLED: "true"
      DATABASE_PROVIDER: "sqlite"
      AUTHENTICATION_API_KEY: "checkin24hs-secret-key-2024"
      AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES: "true"
      SERVER_URL: "http://72.61.58.240:8080"
      SERVER_PORT: "8080"
      LOG_LEVEL: "ERROR"
      QRCODE_LIMIT: "30"
      WEBHOOK_GLOBAL_ENABLED: "true"
      WEBHOOK_GLOBAL_URL: "http://72.61.58.240:3001/webhook/evolution"
      WEBSOCKET_GLOBAL_ENABLED: "true"
    volumes:
      - evolution_instances:/evolution/instances
      - evolution_store:/evolution/store
    networks:
      - evolution-network

volumes:
  evolution_instances:
  evolution_store:

networks:
  evolution-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml creado"
echo ""

# Iniciar Evolution API
echo "3️⃣  Iniciando Evolution API..."
docker-compose up -d

echo "✅ Evolution API iniciado"
echo ""

# Esperar a que esté listo
echo "4️⃣  Esperando a que Evolution API esté listo (10 segundos)..."
sleep 10

# Verificar que está corriendo
echo "5️⃣  Verificando que está corriendo..."
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ Evolution API está corriendo en http://72.61.58.240:8080"
else
    echo "⚠️  Evolution API puede tardar unos segundos más en iniciar"
    echo "   Verifica con: docker logs evolution-api-checkin24hs"
fi
echo ""

# Crear script para crear instancias
echo "6️⃣  Creando script para crear instancias..."
cat > crear-instancias.sh << 'SCRIPTEOF'
#!/bin/bash
# Crear las 4 instancias WhatsApp en Evolution API

API_KEY="checkin24hs-secret-key-2024"
BASE_URL="http://localhost:8080"

echo "📱 Creando instancias WhatsApp..."
echo ""

for i in 1 2 3 4; do
    echo "Creando instancia whatsapp-${i}..."
    curl -X POST ${BASE_URL}/instance/create \
      -H "apikey: ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"instanceName\": \"whatsapp-${i}\",
        \"qrcode\": true,
        \"integration\": \"WHATSAPP-BAILEYS\"
      }" 2>/dev/null | jq '.' || echo "Instancia creada (o ya existía)"
    echo ""
done

echo "✅ Instancias creadas"
echo ""
echo "📋 Para ver los QR codes:"
echo "   1. Abre: http://72.61.58.240:8080/manager"
echo "   2. O ejecuta: curl http://localhost:8080/instance/fetchInstances -H \"apikey: ${API_KEY}\""
SCRIPTEOF

chmod +x crear-instancias.sh

echo "✅ Script crear-instancias.sh creado"
echo ""

echo "=============================================================="
echo "✅ INSTALACIÓN COMPLETA"
echo "=============================================================="
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo ""
echo "   1. Crear las instancias:"
echo "      cd /root/checkin24hs/evolution-api"
echo "      ./crear-instancias.sh"
echo ""
echo "   2. Ver el panel web:"
echo "      http://72.61.58.240:8080/manager"
echo ""
echo "   3. Escanear QR codes desde el panel web"
echo ""
echo "   4. Ver logs si algo falla:"
echo "      docker logs evolution-api-checkin24hs"
echo ""
echo "=============================================================="
