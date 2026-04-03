# 🔍 Diagnosticar: Mensajes no aparecen en sección Chat

## 🐛 Problema

Flor IA responde, pero los mensajes no aparecen en la sección Chat del dashboard.

---

## ✅ Verificación Paso a Paso

### Paso 1: Verificar Logs del Servidor

**Ejecuta en el servidor:**

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

# Ver logs de guardado de mensajes
docker logs $CONTAINER_ID --tail 200 | grep -iE "Mensaje guardado|Chat actualizado|obtenerOcrearChatId|Error guardando"
```

**Busca:**
- `✅ Mensaje guardado en whatsapp_messages`
- `✅ Chat actualizado en whatsapp_chats`
- `✅ Nuevo chat creado en whatsapp_chats`
- `❌ Error guardando mensaje`

---

### Paso 2: Verificar Función obtenerOcrearChatId

**Verifica que el código esté actualizado:**

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)

# Verificar que prioriza whatsapp_chats
docker exec $CONTAINER_ID grep -A 10 "async function obtenerOcrearChatId" /app/whatsapp-server-baileys.js | grep -i "whatsapp_chats"
```

**Debe mostrar:**
- `PRIMERO: Intentar con whatsapp_chats`
- `from('whatsapp_chats')`

---

### Paso 3: Verificar en Supabase Directamente

**Accede a Supabase y verifica:**

1. **Tabla `whatsapp_chats`:**
   ```sql
   SELECT * FROM whatsapp_chats 
   ORDER BY updated_at DESC 
   LIMIT 10;
   ```

2. **Tabla `whatsapp_messages`:**
   ```sql
   SELECT * FROM whatsapp_messages 
   ORDER BY created_at DESC 
   LIMIT 10;
   ```

**Si los datos están en Supabase pero no aparecen en el dashboard:**
- El problema está en el frontend (dashboard)
- Verifica que el dashboard esté consultando `whatsapp_chats` correctamente

---

### Paso 4: Verificar Dashboard

**Verifica en el código del dashboard:**

1. Abre `dashboard.html`
2. Busca la función `loadChats()`
3. Verifica que esté consultando `whatsapp_chats`:
   ```javascript
   window.supabaseClient.getWhatsAppChats(50)
   ```

---

## 🔧 Soluciones Comunes

### Problema 1: Código no actualizado en el servidor

**Solución:** Aplicar la corrección nuevamente:

```bash
# Desde tu máquina local (PowerShell)
.\APLICAR_CORRECCION_IA_SERVIDOR.ps1
```

O manualmente:

```bash
# En el servidor
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
docker cp /tmp/whatsapp-server-baileys.js $CONTAINER_ID:/app/whatsapp-server-baileys.js
docker restart $CONTAINER_ID
```

---

### Problema 2: Errores al guardar en Supabase

**Solución:** Verificar variables de entorno:

```bash
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
docker exec $CONTAINER_ID env | grep -E "(SUPABASE|SAVE_TO_SUPABASE)"
```

**Debe mostrar:**
- `SUPABASE_URL=...`
- `SUPABASE_ANON_KEY=...`
- `SAVE_TO_SUPABASE=true` (o no estar configurada, usa true por defecto)

---

### Problema 3: Dashboard no consulta correctamente

**Solución:** Verificar que el dashboard esté usando la función correcta:

1. Abre el dashboard en el navegador
2. Abre la consola del navegador (F12)
3. Verifica que no haya errores al cargar chats
4. Verifica que la función `getWhatsAppChats` esté siendo llamada

---

## 📝 Script de Diagnóstico Completo

He creado un script para diagnosticar automáticamente:

```bash
chmod +x /tmp/VERIFICAR_GUARDADO_CHAT.sh
/tmp/VERIFICAR_GUARDADO_CHAT.sh
```

---

## 🔍 Próximos Pasos

1. Ejecuta el script de diagnóstico
2. Revisa los logs del servidor
3. Verifica en Supabase si los datos se están guardando
4. Comparte los resultados para identificar el problema específico
