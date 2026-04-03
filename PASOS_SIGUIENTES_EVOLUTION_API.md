# ✅ Pasos Siguientes - Evolution API

## 🎯 Ahora que Evolution API está funcionando:

### Paso 1: Verificar que Evolution API está corriendo

```bash
# Verificar contenedores
docker ps | grep evolution

# Verificar que responde
curl http://localhost:8080

# Ver logs
docker-compose logs -f evolution-api
```

### Paso 2: Crear las 4 instancias WhatsApp

```bash
cd evolution-api
./probar-evolution-api.sh
```

O manualmente:

```bash
API_KEY="checkin24hs-secret-key-2024"
API_URL="http://localhost:8080"

for i in 1 2 3 4; do
  curl -X POST $API_URL/instance/create \
    -H "apikey: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"instanceName\": \"whatsapp-$i\", \"qrcode\": true, \"integration\": \"WHATSAPP-BAILEYS\"}"
done
```

### Paso 3: Obtener QR Codes

```bash
API_KEY="checkin24hs-secret-key-2024"
API_URL="http://localhost:8080"

# QR para whatsapp-1
curl $API_URL/instance/connect/whatsapp-1 -H "apikey: $API_KEY" | grep -o '"qrcode\.url":"[^"]*"'

# QR para whatsapp-2
curl $API_URL/instance/connect/whatsapp-2 -H "apikey: $API_KEY" | grep -o '"qrcode\.url":"[^"]*"'

# QR para whatsapp-3
curl $API_URL/instance/connect/whatsapp-3 -H "apikey: $API_KEY" | grep -o '"qrcode\.url":"[^"]*"'

# QR para whatsapp-4
curl $API_URL/instance/connect/whatsapp-4 -H "apikey: $API_KEY" | grep -o '"qrcode\.url":"[^"]*"'
```

### Paso 4: Conectar WhatsApp

1. **Abre WhatsApp** en tu teléfono
2. **Ve a**: Configuración → Dispositivos vinculados → Vincular un dispositivo
3. **Abre la URL del QR** en tu navegador (o escanea el QR directamente)
4. **Escanea el QR** con WhatsApp
5. **Repite** para las 4 instancias

### Paso 5: Verificar Estado de Conexión

```bash
API_KEY="checkin24hs-secret-key-2024"
API_URL="http://localhost:8080"

for i in 1 2 3 4; do
  echo "Estado whatsapp-$i:"
  curl -s $API_URL/instance/fetchInstance/whatsapp-$i \
    -H "apikey: $API_KEY" | grep -o '"status":"[^"]*"'
done
```

Deberías ver `"status":"open"` para las instancias conectadas.

### Paso 6: Probar Envío de Mensaje

```bash
API_KEY="checkin24hs-secret-key-2024"
API_URL="http://localhost:8080"

curl -X POST $API_URL/message/sendText/whatsapp-1 \
  -H "apikey: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5491112345678",
    "text": "Hola! Prueba desde Evolution API"
  }'
```

Reemplaza `5491112345678` con un número real de WhatsApp.

### Paso 7: Probar Recepción

1. **Envía un mensaje** desde WhatsApp a uno de los números conectados
2. **Verifica los logs**:
   ```bash
   docker-compose logs -f evolution-api | grep -i message
   ```

---

## 🔧 Comandos Útiles

### Ver todas las instancias

```bash
curl http://localhost:8080/instance/fetchInstances \
  -H "apikey: checkin24hs-secret-key-2024"
```

### Reiniciar una instancia

```bash
curl -X PUT http://localhost:8080/instance/restart/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024"
```

### Eliminar una instancia

```bash
curl -X DELETE http://localhost:8080/instance/delete/whatsapp-1 \
  -H "apikey: checkin24hs-secret-key-2024"
```

### Ver logs en tiempo real

```bash
docker-compose logs -f evolution-api
```

---

## ✅ Checklist

- [ ] Evolution API está corriendo
- [ ] Las 4 instancias están creadas
- [ ] Puedo obtener QR codes
- [ ] WhatsApp está conectado (estado "open")
- [ ] Puedo enviar mensajes
- [ ] Puedo recibir mensajes

---

## 🎯 Próximo Paso: Integrar con Dashboard

Una vez que todo funcione, el siguiente paso es actualizar el dashboard para usar Evolution API en lugar del código anterior.

¿Quieres que actualice el dashboard ahora?


