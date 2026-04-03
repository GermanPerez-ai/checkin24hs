# 🚀 Guía Completa: Implementar Evolution API para Checkin24hs

## 📋 Resumen

Esta guía te ayudará a implementar Evolution API para conectar 4 WhatsApp con Flor IA, **sin costo** y funcionando en tu propio servidor.

---

## 🎯 Paso 1: Preparar el Servidor

### Opción A: En EasyPanel (Recomendado)

1. **Crear nuevo servicio** en EasyPanel
2. **Tipo**: Docker Compose
3. **Puerto**: 8080 (Evolution API) y 3000 (Adaptador)

### Opción B: En VPS/Servidor Dedicado

```bash
# Instalar Docker y Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

---

## 🎯 Paso 2: Subir Archivos

### En EasyPanel:

1. **Crear carpeta** `evolution-api` en tu repositorio
2. **Subir estos archivos**:
   - `docker-compose.yml`
   - `.env.example` (copiar a `.env`)
   - `server.js` (adaptador)
   - `package.json` (adaptador)

### En VPS:

```bash
# Crear carpeta
mkdir -p evolution-api
cd evolution-api

# Copiar archivos (usando git, scp, o editor)
```

---

## 🎯 Paso 3: Configurar Variables de Entorno

### Crear archivo `.env`:

```bash
cd evolution-api
cp .env.example .env
```

### Editar `.env`:

```env
# API Key (CAMBIA ESTO POR UNA CLAVE SEGURA)
AUTHENTICATION_API_KEY=tu-clave-super-secreta-aqui-2024

# URL del servidor (cambia por tu dominio o IP)
SERVER_URL=http://tu-dominio.com:8080

# URL del webhook (cambia por tu servidor del adaptador)
WEBHOOK_GLOBAL_URL=http://tu-dominio.com:3000/webhook/evolution

# Configuración de Flor IA
GEMINI_API_KEY=tu-gemini-api-key
FLOR_ENABLED=true

# Configuración de Supabase
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=tu-supabase-anon-key
```

---

## 🎯 Paso 4: Iniciar Evolution API

### En EasyPanel:

1. **Abrir terminal** del servicio
2. **Ejecutar**:
```bash
cd evolution-api
docker-compose up -d
```

### En VPS:

```bash
cd evolution-api
docker-compose up -d
```

### Verificar que funciona:

```bash
# Ver logs
docker-compose logs -f evolution-api

# Verificar que responde
curl http://localhost:8080
```

---

## 🎯 Paso 5: Crear las 4 Instancias WhatsApp

### Script para crear todas las instancias:

```bash
#!/bin/bash

API_KEY="tu-clave-super-secreta-aqui-2024"
API_URL="http://localhost:8080"

# Crear instancia 1
curl -X POST $API_URL/instance/create \
  -H "apikey: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "whatsapp-1", "qrcode": true, "integration": "WHATSAPP-BAILEYS"}'

# Crear instancia 2
curl -X POST $API_URL/instance/create \
  -H "apikey: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "whatsapp-2", "qrcode": true, "integration": "WHATSAPP-BAILEYS"}'

# Crear instancia 3
curl -X POST $API_URL/instance/create \
  -H "apikey: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "whatsapp-3", "qrcode": true, "integration": "WHATSAPP-BAILEYS"}'

# Crear instancia 4
curl -X POST $API_URL/instance/create \
  -H "apikey: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "whatsapp-4", "qrcode": true, "integration": "WHATSAPP-BAILEYS"}'
```

Guarda esto como `crear-instancias.sh` y ejecuta:

```bash
chmod +x crear-instancias.sh
./crear-instancias.sh
```

---

## 🎯 Paso 6: Iniciar el Adaptador (Servidor Node.js)

### En EasyPanel:

1. **Crear nuevo servicio** Node.js
2. **Puerto**: 3000
3. **Comando**: `npm start`
4. **Variables de entorno**:
   - `EVOLUTION_API_URL=http://evolution-api:8080`
   - `EVOLUTION_API_KEY=tu-clave-super-secreta-aqui-2024`
   - `GEMINI_API_KEY=tu-gemini-api-key`
   - `SUPABASE_URL=...`
   - `SUPABASE_ANON_KEY=...`

### En VPS:

```bash
cd evolution-api
npm install
npm start
```

O con PM2:

```bash
npm install -g pm2
pm2 start server.js --name evolution-adapter
pm2 save
```

---

## 🎯 Paso 7: Obtener QR Codes

### Opción A: Desde el Adaptador (Recomendado)

```bash
# Instancia 1
curl http://localhost:3000/api/qr/whatsapp-1

# Instancia 2
curl http://localhost:3000/api/qr/whatsapp-2

# Instancia 3
curl http://localhost:3000/api/qr/whatsapp-3

# Instancia 4
curl http://localhost:3000/api/qr/whatsapp-4
```

### Opción B: Directamente desde Evolution API

```bash
curl http://localhost:8080/instance/connect/whatsapp-1 \
  -H "apikey: tu-clave-super-secreta-aqui-2024"
```

---

## 🎯 Paso 8: Conectar WhatsApp

1. **Obtener QR** de cada instancia
2. **Abrir WhatsApp** en tu teléfono
3. **Ir a**: Configuración → Dispositivos vinculados → Vincular un dispositivo
4. **Escanear QR** de cada instancia
5. **Repetir** para las 4 instancias

---

## 🎯 Paso 9: Actualizar Dashboard

El dashboard necesita conectarse a Evolution API. Voy a crear el código para actualizar el dashboard en el siguiente paso.

---

## ✅ Verificar que Funciona

### 1. Verificar instancias:

```bash
curl http://localhost:8080/instance/fetchInstances \
  -H "apikey: tu-clave-super-secreta-aqui-2024"
```

### 2. Enviar mensaje de prueba:

```bash
curl -X POST http://localhost:3000/api/send/whatsapp-1 \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5491112345678",
    "text": "Prueba desde Evolution API"
  }'
```

### 3. Verificar webhook:

Envía un mensaje a uno de los WhatsApp conectados y verifica que:
- El mensaje llega al webhook
- Flor responde automáticamente
- El mensaje se guarda en Supabase

---

## 🔧 Solución de Problemas

### Evolution API no inicia

```bash
# Ver logs
docker-compose logs evolution-api

# Verificar puertos
netstat -tulpn | grep 8080
netstat -tulpn | grep 6379
```

### Las instancias no se crean

```bash
# Verificar API key
curl http://localhost:8080/instance/fetchInstances \
  -H "apikey: TU_API_KEY"

# Ver logs
docker-compose logs evolution-api | grep instance
```

### Los mensajes no llegan al webhook

```bash
# Verificar webhook configurado
docker-compose exec evolution-api env | grep WEBHOOK

# Ver logs del adaptador
pm2 logs evolution-adapter
```

### Flor no responde

```bash
# Verificar Gemini API Key
echo $GEMINI_API_KEY

# Ver logs del adaptador
pm2 logs evolution-adapter | grep Flor
```

---

## 📚 Recursos

- **Evolution API GitHub**: https://github.com/EvolutionAPI/evolution-api
- **Documentación**: https://doc.evolution-api.com
- **API Reference**: https://doc.evolution-api.com/v2/en/api-reference

---

## 🎉 ¡Listo!

Una vez completados estos pasos, tendrás:
- ✅ Evolution API funcionando
- ✅ 4 instancias WhatsApp creadas
- ✅ Adaptador conectado con Flor IA
- ✅ Webhooks configurados
- ✅ Mensajes guardándose en Supabase

**Próximo paso**: Actualizar el dashboard para usar Evolution API.


