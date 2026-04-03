# 🚀 Evolution API para Checkin24hs

## 📋 Descripción

Este es el despliegue de Evolution API para conectar 4 WhatsApp con Flor IA.

## 🎯 Características

- ✅ **4 instancias WhatsApp** (whatsapp-1, whatsapp-2, whatsapp-3, whatsapp-4)
- ✅ **API REST simple** para enviar/recibir mensajes
- ✅ **Webhooks** para recibir mensajes automáticamente
- ✅ **QR Code automático** para conectar WhatsApp
- ✅ **Sin Chrome/Puppeteer** - funciona en cualquier servidor
- ✅ **Gratis** - código abierto

## 📦 Requisitos

- Docker y Docker Compose instalados
- Puerto 8080 disponible
- Puerto 6379 disponible (Redis)

## 🚀 Instalación Rápida

### Paso 1: Clonar/Copiar archivos

```bash
cd evolution-api
```

### Paso 2: Configurar variables de entorno

```bash
cp .env.example .env
# Edita .env y cambia AUTHENTICATION_API_KEY por una clave segura
```

### Paso 3: Iniciar Evolution API

```bash
docker-compose up -d
```

### Paso 4: Verificar que funciona

```bash
# Ver logs
docker-compose logs -f evolution-api

# Verificar que está corriendo
curl http://localhost:8080
```

## 📱 Crear Instancias WhatsApp

### Instancia 1

```bash
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "whatsapp-1",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'
```

### Instancia 2

```bash
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "whatsapp-2",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'
```

### Instancia 3

```bash
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "whatsapp-3",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'
```

### Instancia 4

```bash
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "whatsapp-4",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'
```

## 🔗 Obtener QR Code

```bash
# Instancia 1
curl http://localhost:8080/instance/connect/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024"

# Instancia 2
curl http://localhost:8080/instance/connect/whatsapp-2 \
  -H "apikey: checkin24hs-secret-key-2024"

# Instancia 3
curl http://localhost:8080/instance/connect/whatsapp-3 \
  -H "apikey: checkin24hs-secret-key-2024"

# Instancia 4
curl http://localhost:8080/instance/connect/whatsapp-4 \
  -H "apikey: checkin24hs-secret-key-2024"
```

## 📤 Enviar Mensaje

```bash
curl -X POST http://localhost:8080/message/sendText/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5491112345678",
    "text": "Hola desde Flor IA!"
  }'
```

## 📥 Recibir Mensajes (Webhook)

Los mensajes se enviarán automáticamente a la URL configurada en `WEBHOOK_GLOBAL_URL`.

El webhook recibirá eventos como:
- `messages.upsert` - Nuevo mensaje recibido
- `qrcode.updated` - QR actualizado
- `connection.update` - Estado de conexión cambiado

## 🔧 Comandos Útiles

```bash
# Ver logs
docker-compose logs -f evolution-api

# Reiniciar
docker-compose restart evolution-api

# Detener
docker-compose down

# Detener y eliminar volúmenes (CUIDADO: borra todas las instancias)
docker-compose down -v

# Ver estado de instancias
curl http://localhost:8080/instance/fetchInstances \
  -H "apikey: checkin24hs-secret-key-2024"
```

## 📚 Documentación Completa

- **GitHub**: https://github.com/EvolutionAPI/evolution-api
- **Documentación**: https://doc.evolution-api.com
- **API Reference**: https://doc.evolution-api.com/v2/en/api-reference

## 🔒 Seguridad

⚠️ **IMPORTANTE**: Cambia `AUTHENTICATION_API_KEY` en producción por una clave segura.

## 🆘 Solución de Problemas

### El contenedor no inicia

```bash
# Ver logs
docker-compose logs evolution-api

# Verificar puertos
netstat -tulpn | grep 8080
netstat -tulpn | grep 6379
```

### Las instancias no se crean

```bash
# Verificar que la API está funcionando
curl http://localhost:8080

# Verificar la API key
curl http://localhost:8080/instance/fetchInstances \
  -H "apikey: TU_API_KEY"
```

### Los mensajes no llegan

```bash
# Verificar webhook configurado
docker-compose exec evolution-api env | grep WEBHOOK

# Ver logs de webhook
docker-compose logs -f evolution-api | grep webhook
```


