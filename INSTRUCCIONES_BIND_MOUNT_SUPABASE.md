# 📋 Instrucciones: Agregar Bind Mount para supabase-client.js

## 🎯 Objetivo

Configurar un bind mount para `supabase-client.js` en EasyPanel, similar a como está configurado `dashboard.html`, para que los cambios en el archivo del servidor se reflejen automáticamente en el contenedor.

---

## 📝 Pasos en EasyPanel

### 1. Preparar el Archivo en el Servidor

Primero, ejecuta este script en el servidor para preparar el archivo:

```bash
# Descargar y ejecutar script de configuración
curl -s -L "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/CONFIGURAR_BIND_MOUNT_SUPABASE.sh" -o /tmp/CONFIGURAR_BIND_MOUNT.sh
chmod +x /tmp/CONFIGURAR_BIND_MOUNT.sh
/tmp/CONFIGURAR_BIND_MOUNT.sh
```

Este script:
- Descarga la versión más reciente de `supabase-client.js` desde GitHub
- La guarda en `/root/checkin24hs/supabase-client.js`
- Verifica que tenga la corrección aplicada
- Configura los permisos correctos

---

### 2. Acceder al Servicio en EasyPanel

1. **Inicia sesión en EasyPanel**
2. **Navega al servicio `checkin24hs_dashboard`** (o `dashboard`)
3. **Haz clic en "Editar" o "Settings"** (o el botón de configuración)

---

### 3. Agregar Bind Mount

1. **Busca la sección "Mounts" o "Volumes" o "Puntos de montaje"**
   - Puede estar en diferentes lugares según la versión de EasyPanel:
     - Pestaña "Volumes"
     - "Advanced Settings"
     - "Environment & Storage"
     - "Configuration"

2. **Haz clic en "Agregar montaje de archivo"**
   - ⚠️ **IMPORTANTE**: Debe ser "montaje de archivo" (file mount), NO "montaje de enlace" (link mount) ni "volumen" (volume)

3. **Configura el bind mount con estos valores:**

   - **Type/Tipo:** `Bind Mount` o `Host Path` o `File Mount`
   
   - **Source/Host Path (Ruta del host):**
     ```
     /root/checkin24hs/supabase-client.js
     ```
   
   - **Destination/Container Path (Ruta del contenedor):**
     ```
     /app/supabase-client.js
     ```
   
   - **Read Only (Solo lectura):**
     - ❌ **Desactivado** (déjalo desactivado para permitir escritura si es necesario)

4. **Guarda los cambios**

---

### 4. Actualizar el Servicio

Después de guardar, EasyPanel debería:
- **Actualizar automáticamente el servicio** de Docker Swarm
- **Recrear el contenedor** con el nuevo mount

Si no se actualiza automáticamente:
- Busca un botón **"Deploy"**, **"Update"** o **"Apply"**
- O **guarda** nuevamente para forzar la actualización

---

### 5. Verificar que Funciona

Después de que el servicio se actualice (puede tardar 30-60 segundos), verifica en el servidor:

```bash
# En SSH
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' | grep supabase
```

Deberías ver algo como:
```
bind /root/checkin24hs/supabase-client.js -> /app/supabase-client.js
```

También puedes verificar que el archivo en el contenedor tiene la corrección:

```bash
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
docker exec "$CONTAINER" grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" /app/supabase-client.js && echo "✅ Corrección presente" || echo "❌ Corrección NO presente"
```

---

## ✅ Después de Configurar

Una vez configurado el bind mount:

1. **El archivo `/root/checkin24hs/supabase-client.js` en el servidor será el que use el contenedor**
2. **Los cambios en ese archivo se reflejarán automáticamente** en el contenedor
3. **Ya no necesitarás copiar el archivo manualmente** al contenedor
4. **Para actualizar el archivo**, simplemente ejecuta:

   ```bash
   # Actualizar supabase-client.js desde GitHub
   curl -s -L "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js" -o /root/checkin24hs/supabase-client.js
   
   # Verificar que tiene la corrección
   grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" /root/checkin24hs/supabase-client.js && echo "✅ Actualizado correctamente"
   ```

---

## 📋 Resumen de Archivos con Bind Mount

Después de configurar, tendrás estos archivos montados:

| Archivo | Ruta en Servidor | Ruta en Contenedor |
|---------|------------------|-------------------|
| `dashboard.html` | `/root/checkin24hs/dashboard.html` | `/app/dashboard.html` |
| `server.js` | `/root/checkin24hs/server.js` | `/app/server.js` |
| `supabase-client.js` | `/root/checkin24hs/supabase-client.js` | `/app/supabase-client.js` |

---

## 🔄 Actualizar Archivos en el Futuro

Para actualizar cualquiera de estos archivos:

1. **Descarga desde GitHub:**
   ```bash
   curl -s -L "https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/[ARCHIVO]" -o /root/checkin24hs/[ARCHIVO]
   ```

2. **Los cambios se aplicarán automáticamente** en el contenedor (no necesitas reiniciar)

3. **Recarga la página del dashboard** (F5) para ver los cambios

---

## ❓ Problemas Comunes

### El archivo no se actualiza en el contenedor

- Verifica que el bind mount esté configurado correctamente
- Verifica que la ruta del host sea correcta: `/root/checkin24hs/supabase-client.js`
- Verifica que el archivo existe en el servidor: `ls -lh /root/checkin24hs/supabase-client.js`

### El servicio no se actualiza después de guardar

- Busca un botón "Deploy" o "Update" en EasyPanel
- O reinicia el servicio manualmente desde SSH:
  ```bash
  docker service update --force checkin24hs_dashboard
  ```

### El contenedor no encuentra el archivo

- Verifica que la ruta del contenedor sea correcta: `/app/supabase-client.js`
- Verifica que el servicio se haya actualizado correctamente
- Revisa los logs del servicio para ver si hay errores
