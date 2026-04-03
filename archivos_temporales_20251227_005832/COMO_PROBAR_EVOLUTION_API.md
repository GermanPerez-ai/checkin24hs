# 🧪 Cómo Probar Evolution API - Guía Paso a Paso

## 📋 Requisitos Previos

Antes de probar, asegúrate de tener:

1. ✅ Evolution API corriendo (`docker-compose up -d`)
2. ✅ Adaptador corriendo (opcional, `npm start`)
3. ✅ Variables de entorno configuradas (`.env`)

---

## 🚀 Método 1: Script Automático (Recomendado)

### Paso 1: Dar permisos al script

```bash
cd evolution-api
chmod +x probar-evolution-api.sh
```

### Paso 2: Configurar variables (opcional)

```bash
export EVOLUTION_API_KEY="tu-clave-secreta"
export EVOLUTION_API_URL="http://localhost:8080"
export ADAPTER_URL="http://localhost:3000"
```

### Paso 3: Ejecutar el script

```bash
./probar-evolution-api.sh
```

El script verificará automáticamente:
- ✅ Que Evolution API está corriendo
- ✅ Que el adaptador está corriendo
- ✅ Lista de instancias existentes
- ✅ Crea instancias si no existen
- ✅ Obtiene QR codes
- ✅ Verifica estado de conexión
- ✅ Permite probar envío de mensajes

---

## 🔧 Método 2: Pruebas Manuales

### 1. Verificar que Evolution API está corriendo

```bash
curl http://localhost:8080
```

**Resultado esperado**: Debe responder con HTML o JSON

### 2. Verificar que el adaptador está corriendo

```bash
curl http://localhost:3000/health
```

**Resultado esperado**:
```json
{"status":"ok","timestamp":"2024-..."}
```

### 3. Listar instancias existentes

```bash
curl http://localhost:8080/instance/fetchInstances \
  -H "apikey: checkin24hs-secret-key-2024"
```

**Resultado esperado**: Lista de instancias (puede estar vacía al inicio)

### 4. Crear una instancia

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

**Resultado esperado**:
```json
{
  "instance": {
    "instanceName": "whatsapp-1",
    "status": "created"
  }
}
```

### 5. Obtener QR Code

```bash
curl http://localhost:8080/instance/connect/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024"
```

**Resultado esperado**:
```json
{
  "qrcode": {
    "base64": "data:image/png;base64,iVBORw0KG...",
    "url": "https://..."
  }
}
```

**O desde el adaptador**:
```bash
curl http://localhost:3000/api/qr/whatsapp-1
```

### 6. Verificar estado de conexión

```bash
curl http://localhost:8080/instance/fetchInstance/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024"
```

**Estados posibles**:
- `"status": "close"` - Desconectado (necesita QR)
- `"status": "open"` - Conectado ✅
- `"status": "connecting"` - Conectando...

### 7. Conectar WhatsApp

1. **Obtener QR** (paso 5)
2. **Abrir WhatsApp** en tu teléfono
3. **Ir a**: Configuración → Dispositivos vinculados → Vincular un dispositivo
4. **Escanear QR** que obtuviste
5. **Esperar** a que el estado cambie a `"open"`

### 8. Probar Envío de Mensaje

```bash
curl -X POST http://localhost:8080/message/sendText/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5491112345678",
    "text": "Hola! Esto es una prueba desde Evolution API"
  }'
```

**O desde el adaptador**:
```bash
curl -X POST http://localhost:3000/api/send/whatsapp-1 \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5491112345678",
    "text": "Hola! Esto es una prueba desde Evolution API"
  }'
```

**Resultado esperado**: El mensaje debe llegar al WhatsApp del número especificado

### 9. Probar Recepción de Mensajes

1. **Enviar un mensaje** desde WhatsApp a uno de los números conectados
2. **Verificar logs** del adaptador:
   ```bash
   # Si usas PM2
   pm2 logs evolution-adapter
   
   # Si usas npm start directamente
   # Verás en la consola:
   # 📥 Evento recibido: messages.upsert
   # 📱 Mensaje recibido en whatsapp-1 de 5491112345678: Hola!
   # ✅ Flor respondió en whatsapp-1 a 5491112345678
   ```

3. **Verificar en Supabase** (si está configurado):
   - Tabla `whatsapp_messages`
   - Debe aparecer el mensaje recibido y la respuesta de Flor

---

## 🧪 Pruebas Específicas

### Prueba 1: Crear las 4 instancias

```bash
for i in 1 2 3 4; do
  curl -X POST http://localhost:8080/instance/create \
    -H "apikey: checkin24hs-secret-key-2024" \
    -H "Content-Type: application/json" \
    -d "{\"instanceName\": \"whatsapp-$i\", \"qrcode\": true, \"integration\": \"WHATSAPP-BAILEYS\"}"
done
```

### Prueba 2: Obtener todos los QR codes

```bash
for i in 1 2 3 4; do
  echo "QR para whatsapp-$i:"
  curl http://localhost:8080/instance/connect/whatsapp-$i \
    -H "apikey: checkin24hs-secret-key-2024" | jq '.qrcode.url'
done
```

### Prueba 3: Verificar estado de todas las instancias

```bash
for i in 1 2 3 4; do
  echo "Estado whatsapp-$i:"
  curl http://localhost:8080/instance/fetchInstance/whatsapp-$i \
    -H "apikey: checkin24hs-secret-key-2024" | jq '.instance.status'
done
```

### Prueba 4: Enviar mensaje a todas las instancias

```bash
for i in 1 2 3 4; do
  curl -X POST http://localhost:8080/message/sendText/whatsapp-$i \
    -H "apikey: checkin24hs-secret-key-2024" \
    -H "Content-Type: application/json" \
    -d '{
      "number": "5491112345678",
      "text": "Prueba desde instancia whatsapp-'$i'"
    }'
done
```

---

## 🔍 Verificar Logs

### Evolution API

```bash
# Ver logs en tiempo real
docker-compose logs -f evolution-api

# Ver últimos 100 líneas
docker-compose logs --tail=100 evolution-api

# Buscar errores
docker-compose logs evolution-api | grep -i error
```

### Adaptador

```bash
# Si usas PM2
pm2 logs evolution-adapter

# Si usas npm start
# Los logs aparecen en la consola donde ejecutaste npm start
```

---

## ✅ Checklist de Pruebas

- [ ] Evolution API está corriendo
- [ ] Adaptador está corriendo (opcional)
- [ ] Puedo crear instancias
- [ ] Puedo obtener QR codes
- [ ] Puedo conectar WhatsApp escaneando QR
- [ ] El estado cambia a "open" después de conectar
- [ ] Puedo enviar mensajes
- [ ] Puedo recibir mensajes
- [ ] Flor IA responde automáticamente (si está configurada)
- [ ] Los mensajes se guardan en Supabase (si está configurado)

---

## 🆘 Solución de Problemas

### Evolution API no responde

```bash
# Verificar que está corriendo
docker ps | grep evolution-api

# Ver logs
docker-compose logs evolution-api

# Reiniciar
docker-compose restart evolution-api
```

### No puedo crear instancias

```bash
# Verificar API key
echo $EVOLUTION_API_KEY

# Verificar que la API responde
curl http://localhost:8080

# Ver logs
docker-compose logs evolution-api | grep instance
```

### QR no aparece

```bash
# Verificar que la instancia existe
curl http://localhost:8080/instance/fetchInstance/whatsapp-1 \
  -H "apikey: tu-api-key"

# Ver logs
docker-compose logs evolution-api | grep qrcode

# Intentar reconectar
curl http://localhost:8080/instance/restart/whatsapp-1 \
  -H "apikey: tu-api-key"
```

### Los mensajes no llegan

```bash
# Verificar webhook configurado
docker-compose exec evolution-api env | grep WEBHOOK

# Ver logs del adaptador
pm2 logs evolution-adapter | grep webhook

# Verificar que el webhook es accesible
curl http://tu-servidor.com:3000/webhook/evolution
```

---

## 🎉 ¡Listo!

Una vez que todas las pruebas pasen, Evolution API está funcionando correctamente y listo para usar con Flor IA.


