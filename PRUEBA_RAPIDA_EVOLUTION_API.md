# ⚡ Prueba Rápida de Evolution API

## 🚀 Método Más Rápido: Script Automático

### En Linux/Mac:

```bash
cd evolution-api
chmod +x probar-evolution-api.sh
./probar-evolution-api.sh
```

### En Windows (PowerShell):

```powershell
cd evolution-api
bash probar-evolution-api.sh
```

---

## 📋 Pruebas Manuales Rápidas

### 1. Verificar que Evolution API está corriendo

```bash
curl http://localhost:8080
```

### 2. Crear las 4 instancias

```bash
# Instancia 1
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "whatsapp-1", "qrcode": true, "integration": "WHATSAPP-BAILEYS"}'

# Instancia 2
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "whatsapp-2", "qrcode": true, "integration": "WHATSAPP-BAILEYS"}'

# Instancia 3
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "whatsapp-3", "qrcode": true, "integration": "WHATSAPP-BAILEYS"}'

# Instancia 4
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "whatsapp-4", "qrcode": true, "integration": "WHATSAPP-BAILEYS"}'
```

### 3. Obtener QR Codes

```bash
# QR para whatsapp-1
curl http://localhost:8080/instance/connect/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024"

# QR para whatsapp-2
curl http://localhost:8080/instance/connect/whatsapp-2 \
  -H "apikey: checkin24hs-secret-key-2024"

# QR para whatsapp-3
curl http://localhost:8080/instance/connect/whatsapp-3 \
  -H "apikey: checkin24hs-secret-key-2024"

# QR para whatsapp-4
curl http://localhost:8080/instance/connect/whatsapp-4 \
  -H "apikey: checkin24hs-secret-key-2024"
```

### 4. Conectar WhatsApp

1. Abre WhatsApp en tu teléfono
2. Ve a: **Configuración → Dispositivos vinculados → Vincular un dispositivo**
3. Escanea el QR que obtuviste
4. Repite para las 4 instancias

### 5. Verificar Estado

```bash
# Ver estado de whatsapp-1
curl http://localhost:8080/instance/fetchInstance/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024"
```

Busca `"status": "open"` para confirmar que está conectado.

### 6. Probar Envío de Mensaje

```bash
curl -X POST http://localhost:8080/message/sendText/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5491112345678",
    "text": "Hola! Prueba desde Evolution API"
  }'
```

Reemplaza `5491112345678` con un número real de WhatsApp.

### 7. Probar Recepción

1. Envía un mensaje desde WhatsApp a uno de los números conectados
2. Verifica los logs del adaptador:
   ```bash
   # Si usas PM2
   pm2 logs evolution-adapter
   
   # Si usas npm start
   # Los logs aparecen en la consola
   ```

---

## ✅ Checklist Rápido

- [ ] Evolution API responde en `http://localhost:8080`
- [ ] Puedo crear instancias
- [ ] Puedo obtener QR codes
- [ ] Puedo conectar WhatsApp
- [ ] El estado cambia a "open"
- [ ] Puedo enviar mensajes
- [ ] Puedo recibir mensajes

---

## 🆘 Si Algo No Funciona

### Ver logs:

```bash
# Evolution API
docker-compose logs -f evolution-api

# Adaptador
pm2 logs evolution-adapter
```

### Reiniciar:

```bash
# Evolution API
docker-compose restart evolution-api

# Adaptador
pm2 restart evolution-adapter
```

---

## 📚 Más Información

- **Guía completa**: `COMO_PROBAR_EVOLUTION_API.md`
- **Script automático**: `evolution-api/probar-evolution-api.sh`


