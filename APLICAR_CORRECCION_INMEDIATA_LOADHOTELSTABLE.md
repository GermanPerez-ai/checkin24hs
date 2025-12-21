# 🚀 Aplicar Corrección loadHotelsTable - INMEDIATO

## ⚠️ Problema

El servidor todavía tiene el código antiguo con `loadHotelsTable` duplicado, aunque el código en GitHub ya está corregido.

---

## 🔧 Solución Rápida

### Opción 1: Usar el Script Automático (Recomendado)

1. **Conecta al servidor por SSH:**
   ```bash
   ssh root@tu_servidor
   ```

2. **Descarga y ejecuta el script:**
   ```bash
   curl -o aplicar_correccion.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/APLICAR_CORRECCION_LOADHOTELSTABLE_SERVIDOR.sh
   chmod +x aplicar_correccion.sh
   ./aplicar_correccion.sh
   ```

---

### Opción 2: Aplicar Manualmente

1. **Conecta al servidor por SSH:**
   ```bash
   ssh root@tu_servidor
   ```

2. **Encuentra el contenedor:**
   ```bash
   docker ps | grep dashboard
   ```
   Anota el ID del contenedor (primera columna).

3. **Haz backup:**
   ```bash
   CONTAINER_ID=$(docker ps | grep dashboard | awk '{print $1}' | head -1)
   docker exec $CONTAINER_ID cp /app/dashboard.html /app/dashboard.html.backup
   ```

4. **Descarga el archivo corregido:**
   ```bash
   curl -o /tmp/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
   ```

5. **Copia al contenedor:**
   ```bash
   docker cp /tmp/dashboard.html $CONTAINER_ID:/app/dashboard.html
   ```

6. **Reinicia el contenedor:**
   ```bash
   docker restart $CONTAINER_ID
   ```

7. **Espera 15 segundos y prueba:**
   ```bash
   sleep 15
   curl -I https://dashboard.checkin24hs.com
   ```

---

### Opción 3: Forzar Redeploy desde EasyPanel

1. **Ve a EasyPanel:**
   - Servicio "dashboard"
   - Haz clic en "Redeploy" o "Redesplegar"
   - Espera 2-3 minutos

2. **Verifica:**
   - Abre `https://dashboard.checkin24hs.com`
   - Presiona Ctrl+F5
   - Abre la consola (F12)
   - Verifica que NO aparece el error

---

## ✅ Verificación

Después de aplicar la corrección:

1. **Abre el dashboard:** `https://dashboard.checkin24hs.com`
2. **Presiona Ctrl+F5** (limpiar caché)
3. **Abre la consola (F12)**
4. **Verifica:**
   - ❌ NO debe aparecer: `Identifier 'loadHotelsTable' has already been declared`
   - ✅ Debe aparecer: `✅ Cliente de Supabase inicializado correctamente`
   - ✅ Debe aparecer: `✅ Conexión con Supabase verificada correctamente`

---

## 🔍 Si el Error Persiste

Si después de aplicar la corrección el error sigue apareciendo:

1. **Verifica que el archivo se actualizó:**
   ```bash
   docker exec $CONTAINER_ID grep -c "async function loadHotelsTable" /app/dashboard.html
   ```
   Debe mostrar `1` (solo una declaración).

2. **Verifica la caché del navegador:**
   - Presiona Ctrl+Shift+Delete
   - Selecciona "Caché" y "Imágenes"
   - Haz clic en "Borrar datos"
   - Recarga la página

3. **Verifica que el contenedor se reinició:**
   ```bash
   docker logs $CONTAINER_ID --tail 30
   ```
   Debe mostrar que el servidor se inició recientemente.

---

## 📋 Nota Importante

El código en GitHub ya está corregido. El problema es que el servidor tiene una versión antigua. Una vez que apliques la corrección, el error debería desaparecer.

