# 📥 Descargar Dashboard del Servidor - Método Manual

## 🚀 Pasos Rápidos

### Paso 1: Conectarse al Servidor

**En PowerShell:**
```powershell
ssh root@72.61.58.240
```

Ingresa tu contraseña cuando te la pida.

---

### Paso 2: Buscar el Contenedor y Extraer el Archivo

**Una vez conectado al servidor, ejecuta estos comandos:**

```bash
# 1. Buscar el contenedor del dashboard
docker ps | grep dashboard

# 2. Anotar el ID o nombre del contenedor (primera o última columna)
# Ejemplo: CONTAINER_ID="abc123def456" o NOMBRE="checkin24hs_dashboard.1.xyz"

# 3. Buscar el archivo dashboard.html en el contenedor
CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
echo "Contenedor: $CONTAINER_ID"

# 4. Buscar la ruta del archivo
DASHBOARD_PATH=$(docker exec $CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
echo "Ruta del archivo: $DASHBOARD_PATH"

# 5. Copiar el archivo a /tmp
docker cp $CONTAINER_ID:$DASHBOARD_PATH /tmp/dashboard_servidor.html

# 6. Verificar que se copió
ls -lh /tmp/dashboard_servidor.html
```

---

### Paso 3: Descargar desde tu Máquina Local

**Abre una NUEVA ventana de PowerShell** (deja la SSH abierta) y ejecuta:

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Hacer backup del archivo local actual
Copy-Item dashboard.html "dashboard.html.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Descargar el archivo del servidor
scp root@72.61.58.240:/tmp/dashboard_servidor.html dashboard.html
```

Ingresa tu contraseña cuando te la pida.

---

### Paso 4: Limpiar Archivo Temporal

**Vuelve a la ventana SSH y ejecuta:**

```bash
rm /tmp/dashboard_servidor.html
```

---

## ✅ Verificación

1. **Abrir el archivo en el navegador:**
   ```
   file:///C:/Users/German/Downloads/Checkin24hs/dashboard.html?username=German&password=123456
   ```

2. **Verificar Build Number:**
   - Debe mostrar **Build #75** en el sidebar
   - Abre la consola (F12) y escribe: `window.DASHBOARD_BUILD_NUMBER`
   - Debe mostrar: `75`

3. **Verificar Contenido de Flor IA:**
   - Ve a la sección "Flor IA" en el menú
   - Debe tener todas las pestañas: General, WhatsApp, Conocimiento, Respuestas, Políticas, IA
   - Debe tener formularios completos en cada pestaña

---

## 🔧 Si Tienes Problemas

### Error: "No se encontró contenedor"

```bash
# Listar todos los contenedores
docker ps -a | grep -i dashboard

# Si está detenido, iniciarlo
docker start NOMBRE_CONTENEDOR
```

### Error: "No se encontró dashboard.html"

```bash
# Buscar en rutas comunes
docker exec $CONTAINER_ID ls -la /app/
docker exec $CONTAINER_ID ls -la /usr/share/nginx/html/
docker exec $CONTAINER_ID find / -name "*.html" 2>/dev/null | head -10
```

### Error al Descargar con SCP

**Alternativa: Usar WinSCP**

1. Descarga WinSCP: https://winscp.net/
2. Conecta a:
   - Host: `72.61.58.240`
   - Usuario: `root`
   - Protocolo: SFTP
3. Navega a `/tmp/`
4. Descarga `dashboard_servidor.html`
5. Renómbralo a `dashboard.html` y reemplaza el archivo local
