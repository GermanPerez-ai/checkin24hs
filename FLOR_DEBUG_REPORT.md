# 🚨 REPORTE: Flor respondiendo con fallback de error

## Síntoma
Flor responde con mensaje de fallback después de 2 intentos fallidos:
```
"Parece que hubo un problema para entender. ¿Empezamos de nuevo? Escribí, por ejemplo: "info del Hotel Huilo Huilo" o "qué hoteles tienen?"."
```

## Causa raíz detectada

El mensaje se dispara en `maybeResetContextAndNoEntendido()` (línea 5514) cuando hay **2 fallos consecutivos** de Flor.

Los fallos ocurren cuando:
1. **Error al llamar a Gemini API** (catch en línea 5473-5493)
2. **Respuesta vacía de Gemini** (línea 5496-5499)

## Posibles causas del fallo de Gemini

### 1. **GEMINI_API_KEY no configurada o inválida** (MÁS PROBABLE)
- **Línea 4817-4819**: Valida si `GEMINI_API_KEY` está vacía
- **Línea 5213**: Usa la key en la URL: `?key=${CONFIG.GEMINI_API_KEY}`
- **Error esperado**: 403 (API key sin permisos o inválida) o 400 (key malformada)

### 2. **Error 403: API key sin permisos o cuota excedida**
- Logs esperados (línea 5480-5484):
  ```
  ❌ Error 403 de Gemini: API key sin permisos o cuota excedida.
     Detalle: {...}
  ```

### 3. **Error 400: Request inválido**
- Logs esperados (línea 5476-5479):
  ```
  ❌ Error 400 de Gemini: [mensaje de error]
     Detalle: {...}
  ```

### 4. **Timeout de 45 segundos**
- Logs esperados (línea 5486-5487):
  ```
  ❌ Timeout al procesar con Flor (30s).
  ```
  Nota: El mensaje dice "30s" pero el timeout real es 45000ms (línea 5215)

### 5. **Otro error genérico**
- Logs esperados (línea 5488):
  ```
  ❌ Error procesando con Flor: [error.message o error.response?.data]
  ```

## 🔍 Comandos de diagnóstico para German

### 1. Ver todos los errores de Flor/Gemini en los logs:
```bash
docker logs checkin24hs_whatsapp 2>&1 | grep -i "error.*flor\|error.*gemini\|error 403\|error 400\|error 404\|timeout.*flor" | tail -50
```

### 2. Ver el estado de GEMINI_API_KEY al arranque (CRÍTICO):
```bash
docker logs checkin24hs_whatsapp 2>&1 | grep -i "gemini_api_key\|gemini.*configurad\|gemini.*no funcionará" | head -10
```
**Si ves "⚠️ GEMINI_API_KEY no configurada. Flor IA no funcionará."** → La API key NO está configurada (ver Solución temporal más abajo)

### 3. Ver TODOS los logs relacionados con Flor desde las 13:30:
```bash
docker logs checkin24hs_whatsapp 2>&1 | grep -E "🌸|❌|⚠️.*Flor|⚠️.*Gemini|Flor:.*reset" | tail -100
```

### 4. Ver el mensaje específico de "problema para entender":
```bash
docker logs checkin24hs_whatsapp 2>&1 | grep -i "reset.*tras.*fallos\|problema para entender\|no entiendo" | tail -20
```

### 5. Ver si hay errores HTTP de la API de Gemini:
```bash
docker logs checkin24hs_whatsapp 2>&1 | grep -i "generativelanguage.googleapis.com\|error [45]0[0-9]" | tail -30
```

### 6. Verificar que GEMINI_API_KEY esté configurada en el contenedor:
```bash
docker exec checkin24hs_whatsapp sh -c 'echo "GEMINI_API_KEY length: ${#GEMINI_API_KEY}"'
```
(Debería devolver un número > 0, típicamente ~40 caracteres)

### 7. Ver logs completos de los últimos 5 minutos:
```bash
docker logs --since 5m checkin24hs_whatsapp 2>&1 | tail -200
```

## ✅ Solución temporal mientras se investiga

Si GEMINI_API_KEY no está configurada o es inválida:

1. **Obtener una API key válida de Google AI Studio:**
   - https://aistudio.google.com/app/apikey
   
2. **Configurar en Easypanel:**
   - Servicio `checkin24hs_whatsapp` → Pestaña "Entorno"
   - Agregar variable: `GEMINI_API_KEY=<tu_api_key>`
   - Click "Implementar"

3. **Verificar después del deploy:**
   ```bash
   docker logs checkin24hs_whatsapp 2>&1 | grep "GEMINI_API_KEY\|Flor IA"
   ```
   Debería ver: `✅ Flor IA configurada correctamente` (o similar)

## 📋 Siguiente paso

**German debe ejecutar PRIMERO el comando #2** (verificar GEMINI_API_KEY al arranque).

Si ve el warning "GEMINI_API_KEY no configurada", esa es la causa raíz → seguir Solución temporal.

Si NO ve ese warning, ejecutar comandos #1, #3 y #6 para diagnosticar más.
