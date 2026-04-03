# 🔍 Verificar Por Qué Flor IA No Responde

## Ejecuta en el servidor:

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

# 1. Verificar variables de entorno
docker exec $CONTAINER_ID env | grep -E "FLOR_ENABLED|AUTO_REPLY|GEMINI_API_KEY|FLOR_DELAY"

# 2. Ver logs recientes de mensajes
docker logs $CONTAINER_ID --since 2m | grep -iE "mensaje recibido|message received|from:" | tail -10

# 3. Ver errores de Flor IA
docker logs $CONTAINER_ID --since 2m | grep -iE "flor|gemini|ia|ai|error.*gemini" | tail -20

# 4. Ver logs completos recientes
docker logs $CONTAINER_ID --tail 50
```

---

## Posibles Causas

### 1. Flor IA deshabilitada
**Síntomas:**
- `FLOR_ENABLED=false` o no está configurado
- `AUTO_REPLY=false`

**Solución:**
- Verificar en EasyPanel que `FLOR_ENABLED=true` y `AUTO_REPLY=true`

### 2. API Key de Gemini incorrecta o faltante
**Síntomas:**
- `GEMINI_API_KEY` vacío o incorrecto
- Errores como "API key not found" o "Invalid API key"

**Solución:**
- Verificar en EasyPanel que `GEMINI_API_KEY` esté configurado correctamente

### 3. Error al llamar a Gemini API
**Síntomas:**
- Errores como "Error calling Gemini API" o "Failed to get response"
- Errores 400, 401, 403, 429, 500

**Solución:**
- Verificar que la API key sea válida
- Verificar cuota de Gemini API
- Verificar conectividad a internet

### 4. Mensaje no se está recibiendo
**Síntomas:**
- No aparecen logs de "mensaje recibido"
- WhatsApp no está conectado

**Solución:**
- Verificar conexión de WhatsApp
- Verificar que el bot esté escuchando mensajes

### 5. Error en el código de Flor IA
**Síntomas:**
- Errores de JavaScript relacionados con `flor` o `gemini`
- Stack traces en los logs

**Solución:**
- Revisar logs completos para identificar el error específico

---

## Verificar en EasyPanel

1. **Ve a EasyPanel** → Servicio WhatsApp
2. **Verifica Variables de Entorno:**
   - `FLOR_ENABLED=true`
   - `AUTO_REPLY=true`
   - `GEMINI_API_KEY=AIzaSyDvza5tlt0fjEgTamUKG1ZjTuqU8qCaxI` (o tu key)
3. **Reinicia el servicio** si cambiaste algo

---

## Comandos Rápidos

```bash
# Ver si Flor está habilitada
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
docker exec $CONTAINER_ID env | grep FLOR_ENABLED

# Ver últimos errores
docker logs $CONTAINER_ID --tail 100 | grep -i error

# Ver si hay mensajes recibidos
docker logs $CONTAINER_ID --tail 100 | grep -i "mensaje recibido"
```
