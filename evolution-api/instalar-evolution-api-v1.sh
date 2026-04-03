#!/bin/bash
# Instalar Evolution API v1 (más simple y estable, sin Redis)

cd /root/checkin24hs/evolution-api

echo "🔄 Cambiando a Evolution API v1 (más estable)..."
echo ""

# 1. Detener contenedores actuales
echo "1️⃣  Deteniendo Evolution API v2..."
docker-compose down
echo ""

# 2. Crear docker-compose.yml para v1
echo "2️⃣  Creando docker-compose.yml para Evolution API v1..."
cat > docker-compose.yml << 'EOF'
services:
  evolution-api:
    image: atendai/evolution-api:v1.2.1
    container_name: evolution-api-checkin24hs
    restart: unless-stopped
    ports:
      - "8081:8080"
    environment:
      # NO necesita base de datos ni Redis en v1
      AUTHENTICATION_API_KEY: "checkin24hs-secret-key-2024"
      AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES: "true"
      SERVER_URL: "http://72.61.58.240:8081"
      SERVER_PORT: "8080"
      LOG_LEVEL: "ERROR"
      QRCODE_LIMIT: "30"
      # Webhooks desactivados para evitar errores 404
      WEBHOOK_GLOBAL_ENABLED: "false"
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

echo "✅ docker-compose.yml creado para v1"
echo ""

# 3. Limpiar volúmenes antiguos si es necesario (opcional)
echo "3️⃣  Limpiando volúmenes de v2 (opcional)..."
# No los limpiamos automáticamente para no perder datos
# docker volume rm evolution-api_postgres_data evolution-api_redis_data 2>/dev/null || true
echo "   (Volúmenes de v2 preservados - no se eliminan)"
echo ""

# 4. Iniciar Evolution API v1
echo "4️⃣  Iniciando Evolution API v1..."
docker-compose up -d

# 5. Esperar a que inicie
echo "5️⃣  Esperando 10 segundos para que Evolution API v1 inicie..."
sleep 10

# 6. Verificar logs
echo ""
echo "6️⃣  Verificando logs de Evolution API v1..."
docker logs evolution-api-checkin24hs --tail 30 | grep -v "redis\|webhook" | tail -15
echo ""

# 7. Verificar que está corriendo
echo "7️⃣  Verificando que está corriendo..."
curl -s http://localhost:8081 | python3 -m json.tool 2>/dev/null | head -10 || \
curl -s http://localhost:8081 | head -5
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Evolution API v1 instalado"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo ""
echo "   1. Crea las instancias:"
echo "      cd /root/checkin24hs/evolution-api"
echo "      bash crear-instancias-evolution.sh"
echo ""
echo "   2. Abre el panel web:"
echo "      http://72.61.58.240:8081/manager"
echo ""
echo "   3. Haz clic en 'Get QR Code' en cada instancia"
echo ""
echo "   4. Evolution API v1 NO necesita Redis ni PostgreSQL"
echo "      Es más simple y estable"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
