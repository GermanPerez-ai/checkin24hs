# 📥 Descargar Dashboard Completo del Servidor

## 🚀 Método Rápido (Script Automático)

### Paso 1: Ejecutar el Script

**En PowerShell:**
```powershell
cd C:\Users\German\Downloads\Checkin24hs
.\DESCARGAR_DASHBOARD_SERVIDOR.ps1
```

El script hará automáticamente:
1. ✅ Conectarse al servidor
2. ✅ Buscar el contenedor del dashboard
3. ✅ Extraer el archivo `dashboard.html` del contenedor
4. ✅ Descargarlo a tu máquina local
5. ✅ Hacer backup del archivo local actual
6. ✅ Reemplazar el archivo local con el del servidor

---

## 📋 Método Manual (Si el Script Falla)

### Paso 1: Conectarse al Servidor

```bash
ssh root@72.61.58.240
```

### Paso 2: Buscar el Contenedor

```bash
docker ps | grep dashboard
```

Anota el **ID del contenedor** (primera columna) o el **nombre** (última columna).

### Paso 3: Buscar el Archivo en el Contenedor

```bash
CONTAINER_ID="TU_CONTAINER_ID"  # Reemplaza con el ID real
docker exec $CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules
```

Anota la **ruta completa** del archivo (ejemplo: `/app/dashboard.html`).

### Paso 4: Copiar el Archivo a /tmp

```bash
DASHBOARD_PATH="/app/dashboard.html"  # Reemplaza con la ruta real
docker cp $CONTAINER_ID:$DASHBOARD_PATH /tmp/dashboard_servidor.html
```

### Paso 5: Descargar desde tu Máquina Local

**En PowerShell (Windows):**
```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Hacer backup del archivo local
Copy-Item dashboard.html "dashboard.html.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Descargar el archivo del servidor
scp root@72.61.58.240:/tmp/dashboard_servidor.html dashboard.html
```

### Paso 6: Limpiar Archivo Temporal en el Servidor

```bash
rm /tmp/dashboard_servidor.html
```

---

## ✅ Verificación

Después de descargar, verifica que el archivo está completo:

1. **Abrir en el navegador:**
   ```
   file:///C:/Users/German/Downloads/Checkin24hs/dashboard.html?username=German&password=123456
   ```

2. **Verificar Build Number:**
   - Debe mostrar **Build #75** en el sidebar
   - Abre la consola (F12) y escribe: `window.DASHBOARD_BUILD_NUMBER`
   - Debe mostrar: `75`

3. **Verificar Contenido de Flor IA:**
   - Debe tener todas las pestañas: General, WhatsApp, Conocimiento, Respuestas, Políticas, IA
   - Debe tener formularios completos en cada pestaña

---

## 🔧 Solución de Problemas

### Error: "No se encontró contenedor del dashboard"

**Solución:**
```bash
# En el servidor, listar todos los contenedores
docker ps -a | grep -i dashboard

# Si el contenedor está detenido, iniciarlo
docker start NOMBRE_CONTENEDOR
```

### Error: "No se encontró dashboard.html en el contenedor"

**Solución:**
```bash
# Buscar en todas las rutas posibles
docker exec $CONTAINER_ID ls -la /app/
docker exec $CONTAINER_ID ls -la /usr/share/nginx/html/
docker exec $CONTAINER_ID find / -name "*.html" -type f 2>/dev/null | head -10
```

### Error: "No se pudo descargar el archivo"

**Solución:**
- Verifica que tienes acceso SSH al servidor
- Verifica que el archivo se copió correctamente a `/tmp/`
- Intenta descargar manualmente con WinSCP

---

## 📝 Notas

- El script hace **backup automático** del archivo local antes de reemplazarlo
- El archivo descargado tendrá el **Build #75** completo del servidor
- Después de descargar, el login con parámetros de URL seguirá funcionando
