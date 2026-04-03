# 📥 Descargar Dashboard del Servidor - Instrucciones Completas

## 🚀 Método Recomendado: Script PowerShell

### Paso 1: Ejecutar el Script

**Abre PowerShell y ejecuta:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs
.\DESCARGAR_DASHBOARD_POWERSHELL.ps1
```

### Paso 2: Ingresar Contraseña SSH

El script te pedirá la contraseña SSH **dos veces**:
1. Primera vez: Para ejecutar comandos en el servidor
2. Segunda vez: Para descargar el archivo

**Ingresa la misma contraseña en ambas ocasiones.**

---

## 📋 Qué Hace el Script

El script automáticamente:

1. ✅ Se conecta al servidor por SSH
2. ✅ Busca el contenedor del dashboard
3. ✅ Encuentra el archivo `dashboard.html` en el contenedor
4. ✅ Lo copia a `/tmp/dashboard_servidor.html` en el servidor
5. ✅ Lo descarga a tu máquina local
6. ✅ Hace backup del archivo local actual
7. ✅ Reemplaza el archivo local con el del servidor
8. ✅ Limpia archivos temporales

---

## ✅ Verificación Después de Descargar

### 1. Verificar Build Number

**Abre el archivo en el navegador:**
```
file:///C:/Users/German/Downloads/Checkin24hs/dashboard.html?username=German&password=123456
```

**Debe mostrar:**
- Build #75 en el sidebar (no #74)
- Login automático funcionando

### 2. Verificar Contenido de Flor IA

1. Haz clic en "Flor IA" en el menú lateral
2. Debe tener todas las pestañas:
   - ⚙️ General
   - 📱 WhatsApp
   - 📚 Conocimiento
   - 💬 Respuestas
   - 📋 Políticas
   - 🤖 IA

3. Cada pestaña debe tener formularios completos

---

## 🔧 Solución de Problemas

### Error: "Permission denied"

**Causa:** Contraseña SSH incorrecta

**Solución:**
- Verifica que estás ingresando la contraseña correcta
- Asegúrate de que no hay espacios antes o después de la contraseña
- Si tienes problemas, intenta conectarte manualmente primero:
  ```powershell
  ssh root@72.61.58.240
  ```

### Error: "No se encontró contenedor"

**Causa:** El contenedor del dashboard no está corriendo

**Solución:**
Conéctate manualmente al servidor y verifica:
```bash
ssh root@72.61.58.240
docker ps | grep dashboard
```

Si no hay contenedores, contacta al administrador del servidor.

### Error: "No se encontró dashboard.html"

**Causa:** El archivo no existe en el contenedor o está en otra ruta

**Solución:**
El script intentará buscar en todas las rutas posibles. Si falla, ejecuta manualmente:
```bash
ssh root@72.61.58.240
CONTAINER_ID=$(docker ps | grep dashboard | awk '{print $1}' | head -1)
docker exec $CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null
```

### Error: "No se pudo descargar el archivo"

**Causa:** Problemas de conexión o el archivo no se copió correctamente

**Solución:**
1. Verifica tu conexión a internet
2. Intenta ejecutar el script nuevamente
3. Si persiste, usa el método manual (ver abajo)

---

## 📝 Método Manual (Si el Script Falla)

Si el script no funciona, puedes hacerlo manualmente:

### Paso 1: Conectarse al Servidor

```powershell
ssh root@72.61.58.240
```

### Paso 2: En el Servidor, Ejecutar

```bash
CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
DASHBOARD_PATH=$(docker exec $CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null | grep -v node_modules | head -1)
docker cp $CONTAINER_ID:$DASHBOARD_PATH /tmp/dashboard_servidor.html
ls -lh /tmp/dashboard_servidor.html
```

### Paso 3: En PowerShell (Nueva Ventana)

```powershell
cd C:\Users\German\Downloads\Checkin24hs
Copy-Item dashboard.html "dashboard.html.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
scp root@72.61.58.240:/tmp/dashboard_servidor.html dashboard.html
```

### Paso 4: Limpiar (Volver a SSH)

```bash
rm /tmp/dashboard_servidor.html
```

---

## 💡 Consejos

- **Guarda tu contraseña SSH** en un lugar seguro para no tener que buscarla cada vez
- **El script hace backup automático** del archivo local antes de reemplazarlo
- **Si algo falla**, siempre puedes restaurar desde el backup: `dashboard.html.backup.YYYYMMDD_HHMMSS`

---

## ✅ Resultado Esperado

Después de descargar exitosamente:

- ✅ Archivo local actualizado con Build #75
- ✅ Contenido completo de Flor IA
- ✅ Login con parámetros de URL funcionando
- ✅ Backup del archivo anterior guardado
