# 📤 Subir Evolution API al Servidor

## 🎯 Opción 1: Crear Archivos Directamente en el Servidor (Más Rápido)

### Paso 1: Crear la carpeta

```bash
mkdir -p evolution-api
cd evolution-api
```

### Paso 2: Crear docker-compose.yml

```bash
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
      REDIS_ENABLED: "true"
      REDIS_URI: "redis://redis:6379"
      AUTHENTICATION_API_KEY: "${AUTHENTICATION_API_KEY:-checkin24hs-secret-key-2024}"
      AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES: "true"
      SERVER_URL: "${SERVER_URL:-http://localhost:8080}"
      SERVER_PORT: "8080"
      LOG_LEVEL: "ERROR"
      LOG_COLOR: "true"
      LOG_BAILEYS: "error"
      QRCODE_LIMIT: "30"
      QRCODE_COLOR: "198, 31, 31"
      WEBHOOK_GLOBAL_URL: "${WEBHOOK_GLOBAL_URL:-http://localhost:3000/webhook/evolution}"
      WEBHOOK_GLOBAL_ENABLED: "true"
      WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS: "false"
      TYPEBOT_ENABLED: "false"
      CHATWOOT_ENABLED: "false"
      S3_ENABLED: "false"
      RABBITMQ_ENABLED: "false"
      WEBSOCKET_GLOBAL_ENABLED: "true"
      WEBSOCKET_GLOBAL_EVENTS: "APPLICATION_STARTUP,QRCODE_UPDATED,MESSAGES_UPSERT,MESSAGES_UPDATE,MESSAGES_DELETE,SEND_MESSAGE,CONNECTION_UPDATE,CONTACTS_UPDATE,CONTACTS_UPSERT,PRESENCE_UPDATE,CHATS_UPDATE,CHATS_UPSERT,CHATS_DELETE,GROUPS_UPSERT,GROUP_UPDATE,GROUP_PARTICIPANTS_UPDATE,TYPEBOT_START,TYPEBOT_CHANGE_STATUS"
    volumes:
      - evolution_instances:/evolution/instances
      - evolution_store:/evolution/store
    networks:
      - evolution-network
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    container_name: evolution-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - evolution-network
    command: redis-server --appendonly yes

volumes:
  evolution_instances:
  evolution_store:
  redis_data:

networks:
  evolution-network:
    driver: bridge
EOF
```

### Paso 3: Crear archivo .env

```bash
cat > .env << 'EOF'
AUTHENTICATION_API_KEY=checkin24hs-secret-key-2024-cambiar-en-produccion
SERVER_URL=http://localhost:8080
WEBHOOK_GLOBAL_URL=http://localhost:3000/webhook/evolution
REDIS_ENABLED=true
REDIS_URI=redis://redis:6379
EOF
```

### Paso 4: Crear script de prueba

```bash
cat > probar-evolution-api.sh << 'EOF'
#!/bin/bash

# Script para probar Evolution API paso a paso

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

API_KEY="${EVOLUTION_API_KEY:-checkin24hs-secret-key-2024}"
API_URL="${EVOLUTION_API_URL:-http://localhost:8080}"

echo -e "${BLUE}🧪 PROBANDO EVOLUTION API${NC}"
echo "=========================================="

# Verificar que Evolution API está corriendo
echo -e "\n${BLUE}📋 Verificando Evolution API...${NC}"
if curl -s "$API_URL" > /dev/null; then
    echo -e "${GREEN}✅ Evolution API está corriendo${NC}"
else
    echo -e "${RED}❌ Evolution API no está corriendo${NC}"
    echo "Ejecuta: docker-compose up -d"
    exit 1
fi

# Crear instancias
echo -e "\n${BLUE}📋 Creando instancias...${NC}"
for i in 1 2 3 4; do
    instance_name="whatsapp-$i"
    echo -e "${YELLOW}📱 Creando instancia: $instance_name${NC}"
    
    response=$(curl -s -X POST "$API_URL/instance/create" \
        -H "apikey: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"instanceName\": \"$instance_name\", \"qrcode\": true, \"integration\": \"WHATSAPP-BAILEYS\"}")
    
    if echo "$response" | grep -q "instance"; then
        echo -e "${GREEN}✅ Instancia $instance_name creada${NC}"
    else
        echo -e "${YELLOW}⚠️ Instancia $instance_name puede que ya exista${NC}"
    fi
done

# Obtener QR codes
echo -e "\n${BLUE}📋 Obteniendo QR Codes...${NC}"
for i in 1 2 3 4; do
    instance_name="whatsapp-$i"
    echo -e "\n${YELLOW}📱 QR Code para $instance_name:${NC}"
    
    qr_response=$(curl -s "$API_URL/instance/connect/$instance_name" \
        -H "apikey: $API_KEY")
    
    qr_url=$(echo "$qr_response" | grep -o '"qrcode\.url":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$qr_url" ]; then
        echo -e "${GREEN}✅ QR Code disponible${NC}"
        echo "URL: $qr_url"
        echo "Abre esta URL en tu navegador para ver el QR"
    else
        status=$(echo "$qr_response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        if [ "$status" == "open" ]; then
            echo -e "${GREEN}✅ Instancia ya conectada${NC}"
        else
            echo -e "${YELLOW}⚠️ QR no disponible aún${NC}"
        fi
    fi
done

# Verificar estado
echo -e "\n${BLUE}📋 Estado de conexión:${NC}"
for i in 1 2 3 4; do
    instance_name="whatsapp-$i"
    status_response=$(curl -s "$API_URL/instance/fetchInstance/$instance_name" \
        -H "apikey: $API_KEY")
    
    status=$(echo "$status_response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    phone=$(echo "$status_response" | grep -o '"phoneNumber":"[^"]*"' | cut -d'"' -f4)
    
    case "$status" in
        "open")
            echo -e "${GREEN}✅ $instance_name: Conectado${NC}"
            [ -n "$phone" ] && echo "   Teléfono: $phone"
            ;;
        "close")
            echo -e "${RED}❌ $instance_name: Desconectado${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️ $instance_name: $status${NC}"
            ;;
    esac
done

echo -e "\n${GREEN}✅ Prueba completada!${NC}"
EOF

chmod +x probar-evolution-api.sh
```

### Paso 5: Crear script para crear instancias

```bash
cat > crear-instancias.sh << 'EOF'
#!/bin/bash

API_KEY="${EVOLUTION_API_KEY:-checkin24hs-secret-key-2024}"
API_URL="${EVOLUTION_API_URL:-http://localhost:8080}"

echo "🚀 Creando instancias de WhatsApp..."

for i in 1 2 3 4; do
    instance_name="whatsapp-$i"
    echo "📱 Creando instancia: $instance_name"
    
    curl -s -X POST "$API_URL/instance/create" \
        -H "apikey: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"instanceName\": \"$instance_name\", \"qrcode\": true, \"integration\": \"WHATSAPP-BAILEYS\"}"
    
    echo ""
done

echo "✅ Proceso completado!"
EOF

chmod +x crear-instancias.sh
```

---

## 🎯 Opción 2: Subir Archivos desde tu Computadora

### Paso 1: Comprimir los archivos

En tu computadora (Windows):

```powershell
# Crear ZIP con los archivos
Compress-Archive -Path evolution-api\* -DestinationPath evolution-api.zip
```

### Paso 2: Subir al servidor

```bash
# Desde tu computadora, usar SCP o SFTP
scp evolution-api.zip root@TU_SERVIDOR_IP:/root/

# O usar WinSCP, FileZilla, etc.
```

### Paso 3: Descomprimir en el servidor

```bash
cd /root
unzip evolution-api.zip -d evolution-api
cd evolution-api
```

---

## 🚀 Iniciar Evolution API

Una vez que tengas los archivos:

```bash
cd evolution-api

# Iniciar Evolution API
docker-compose up -d

# Ver logs
docker-compose logs -f evolution-api

# Probar
./probar-evolution-api.sh
```

---

## ✅ Verificar que Funciona

```bash
# Verificar que está corriendo
curl http://localhost:8080

# Ver contenedores
docker ps | grep evolution

# Ver logs
docker-compose logs evolution-api
```


