# 🔍 Diagnosticar Problema de IA en WhatsApp

## 🐛 Problema

Después de la corrección del build 74 a 75, la IA no responde. Los logs muestran "Connecting to websocket...".

---

## ✅ Verificación Paso a Paso

### Paso 1: Verificar Logs del Servidor WhatsApp

**Ejecuta en el servidor:**

```bash
# Buscar contenedor
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

# Ver logs recientes
docker logs $CONTAINER_ID --tail 100

# Buscar errores relacionados con Gemini/IA
docker logs $CONTAINER_ID --tail 200 | grep -iE "(gemini|flor|ia|error|❌|⚠️)"
```

---

### Paso 2: Verificar Variables de Entorno

**Verifica que GEMINI_API_KEY esté configurada:**

```bash
docker exec $CONTAINER_ID env | grep -E "(GEMINI|FLOR|AUTO_REPLY)"
```

**Debe mostrar:**
- `GEMINI_API_KEY=...` (con un valor)
- `FLOR_ENABLED=true` o similar
- `AUTO_REPLY=true` o similar

---

### Paso 3: Verificar Configuración en EasyPanel

1. **Accede a EasyPanel:** `http://72.61.58.240:3006`
2. **Ve al servicio de WhatsApp**
3. **Verifica las variables de entorno:**
   - `GEMINI_API_KEY` - Debe tener un valor
   - `FLOR_ENABLED` - Debe ser `true` o `1`
   - `AUTO_REPLY` - Debe ser `true` o `1`

---

### Paso 4: Probar Mensaje Manualmente

**Envía un mensaje de prueba a Flor por WhatsApp y revisa los logs en tiempo real:**

```bash
# Ver logs en tiempo real
docker logs $CONTAINER_ID -f
```

**Busca mensajes como:**
- `📱 Mensaje recibido de...`
- `🌸 Flor: procesando mensaje...`
- `✅ Flor respondió a...`
- `❌ Error procesando con Flor...`

---

## 🔧 Soluciones Comunes

### Problema 1: GEMINI_API_KEY no configurada

**Solución:** Configurar la variable en EasyPanel:
1. Ve a EasyPanel → Servicio WhatsApp
2. Variables de entorno
3. Agrega/edita `GEMINI_API_KEY` con tu API key de Gemini

---

### Problema 2: API Key inválida o sin permisos

**Solución:** Verificar la API key:
- Ve a Google AI Studio: https://makersuite.google.com/app/apikey
- Verifica que la key esté activa
- Regenera la key si es necesario

---

### Problema 3: FLOR_ENABLED deshabilitado

**Solución:** Habilitar en EasyPanel:
- Variable: `FLOR_ENABLED`
- Valor: `true` o `1`

---

### Problema 4: AUTO_REPLY deshabilitado

**Solución:** Habilitar en EasyPanel:
- Variable: `AUTO_REPLY`
- Valor: `true` o `1`

---

## 📝 Script de Diagnóstico

He creado un script para diagnosticar automáticamente:

```bash
chmod +x /tmp/VERIFICAR_IA_WHATSAPP.sh
/tmp/VERIFICAR_IA_WHATSAPP.sh
```

---

## 🔍 Nota sobre "Connecting to websocket..."

El mensaje "Connecting to websocket..." es del **frontend del dashboard**, no del servidor de WhatsApp. Esto indica que el dashboard está intentando conectarse al servidor de WhatsApp vía Socket.IO para recibir actualizaciones en tiempo real.

**Esto es normal** si:
- El servidor de WhatsApp está corriendo
- El dashboard está intentando conectarse

**Puede ser un problema si:**
- El servidor de WhatsApp no está respondiendo
- Hay un error en la conexión Socket.IO

---

## 📋 Próximos Pasos

1. Ejecuta el script de diagnóstico
2. Revisa los logs del servidor
3. Verifica las variables de entorno en EasyPanel
4. Comparte los resultados para identificar el problema específico
