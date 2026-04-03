# 🚀 Migrar a Evolution API - Solución Estable para WhatsApp

## ✅ Por qué Evolution API es mejor

1. **✅ Más estable**: Diseñada específicamente para múltiples instancias
2. **✅ Mejor autenticación**: Maneja mejor los errores de conexión
3. **✅ API REST simple**: Fácil de integrar
4. **✅ Interfaz web**: Panel de administración incluido
5. **✅ Webhooks**: Recibe mensajes automáticamente
6. **✅ Mejor soporte**: Comunidad activa y documentación completa

---

## 📋 PASO 1: Instalar Evolution API en el Servidor

### Opción A: Con Docker Compose (Recomendado)

```bash
cd /root/checkin24hs

# Crear carpeta para Evolution API
mkdir -p evolution-api
cd evolution-api

# Crear docker-compose.yml
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

# Iniciar Evolution API
docker-compose up -d

# Ver logs
docker-compose logs -f evolution-api
```

---

## 📋 PASO 2: Crear las 4 Instancias WhatsApp

Una vez que Evolution API esté corriendo, crea las instancias:

```bash
# API Key
API_KEY="checkin24hs-secret-key-2024"
BASE_URL="http://72.61.58.240:8080"

# Instancia 1
curl -X POST ${BASE_URL}/instance/create \
  -H "apikey: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "whatsapp-1",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'

# Instancia 2
curl -X POST ${BASE_URL}/instance/create \
  -H "apikey: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "whatsapp-2",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'

# Instancia 3
curl -X POST ${BASE_URL}/instance/create \
  -H "apikey: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "whatsapp-3",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'

# Instancia 4
curl -X POST ${BASE_URL}/instance/create \
  -H "apikey: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "whatsapp-4",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'
```

---

## 📋 PASO 3: Obtener QR Codes

```bash
# Ver QR Code de instancia 1
curl -X GET ${BASE_URL}/instance/connect/whatsapp-1 \
  -H "apikey: ${API_KEY}"

# O abrir en el navegador:
# http://72.61.58.240:8080/manager
```

**Panel Web**: Abre `http://72.61.58.240:8080/manager` en tu navegador para ver todas las instancias y sus QR codes.

---

## 📋 PASO 4: Conectar WhatsApp

1. **Abre el panel**: `http://72.61.58.240:8080/manager`
2. **Selecciona la instancia** (ej: whatsapp-1)
3. **Verás el QR code**
4. **En tu teléfono**: WhatsApp → Configuración → Dispositivos vinculados → Vincular un dispositivo
5. **Escanea el QR**
6. **Espera 10-30 segundos** - debería conectarse automáticamente

---

## 📋 PASO 5: Enviar/Recibir Mensajes

### Enviar mensaje:

```bash
curl -X POST ${BASE_URL}/message/sendText/whatsapp-1 \
  -H "apikey: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5491234567890",
    "text": "Hola desde Evolution API!"
  }'
```

### Recibir mensajes (via Webhook):

Los mensajes llegarán automáticamente a: `http://72.61.58.240:3001/webhook/evolution`

---

## 🔧 Integración con tu Código Existente

Necesitarás modificar tu código para usar Evolution API en lugar de Baileys directo:

1. **Cambiar endpoints**: En lugar de usar el servidor Baileys, usa Evolution API
2. **Webhooks**: Configura webhooks para recibir mensajes
3. **API Key**: Usa la misma API key para todas las operaciones

---

## ✅ Ventajas vs Baileys Directo

| Característica | Baileys Directo | Evolution API |
|---|---|---|
| Estabilidad | ❌ Problemas frecuentes | ✅ Muy estable |
| Múltiples instancias | ⚠️ Requiere configuración manual | ✅ Diseñado para múltiples |
| Autenticación | ❌ Errores frecuentes | ✅ Manejo robusto |
| Panel web | ❌ No incluye | ✅ Incluido |
| Documentación | ⚠️ Limitada | ✅ Completa |
| Comunidad | ⚠️ Pequeña | ✅ Grande y activa |

---

## 🚨 Si algo falla

1. **Ver logs**: `docker logs evolution-api-checkin24hs`
2. **Reiniciar**: `docker restart evolution-api-checkin24hs`
3. **Verificar puerto**: `curl http://72.61.58.240:8080`

---

## 📝 Próximos Pasos

1. Instalar Evolution API
2. Crear las 4 instancias
3. Conectar los WhatsApp escaneando QR codes
4. Probar enviar/recibir mensajes
5. Integrar con tu código existente

¿Quieres que te ayude a instalar Evolution API ahora?
