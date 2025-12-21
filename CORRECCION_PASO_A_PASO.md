# 🔧 Corrección Paso a Paso: saveHotelChanges

## 📋 Instrucciones Detalladas

### Paso 1: Conectarte al Servidor

```bash
# Abre tu terminal (PowerShell en Windows, Terminal en Mac/Linux)
# Conéctate al servidor usando SSH
ssh usuario@tu-servidor

# Si no sabes el usuario o la IP, pregunta a tu proveedor de hosting
# Ejemplo: ssh root@72.61.58.240
```

**¿Qué hacer si no tienes SSH?**
- Si usas EasyPanel, puedes usar el terminal web de EasyPanel
- O usa un cliente SSH como PuTTY (Windows) o Terminal (Mac/Linux)

---

### Paso 2: Verificar que el Contenedor Existe

```bash
# Ver todos los contenedores corriendo
docker ps

# Buscar el contenedor del dashboard
docker ps | grep dashboard

# O buscar contenedores con "checkin24hs"
docker ps | grep checkin24hs
```

**Ejemplo de salida:**
```
CONTAINER ID   IMAGE                    STATUS         NAMES
abc123def456   nginx:latest             Up 2 hours     checkin24hs-dashboard-1
```

**Anota el nombre del contenedor** (en este ejemplo: `checkin24hs-dashboard-1`)

---

### Paso 3: Crear un Backup del Archivo Actual

```bash
# Reemplaza "checkin24hs-dashboard-1" con el nombre de TU contenedor
CONTAINER_NAME="checkin24hs-dashboard-1"
DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"

# Crear backup
docker exec $CONTAINER_NAME cp $DASHBOARD_PATH /tmp/dashboard_backup_$(date +%Y%m%d_%H%M%S).html

# Verificar que se creó
docker exec $CONTAINER_NAME ls -lh /tmp/dashboard_backup_*.html
```

**Si funciona:** Verás algo como:
```
-rw-r--r-- 1 root root 2.1M Dec 20 10:30 /tmp/dashboard_backup_20241220_103045.html
```

---

### Paso 4: Descargar el Archivo Corregido desde GitHub

```bash
# Crear un archivo temporal
TEMP_FILE="/tmp/dashboard_corregido.html"

# Descargar desde GitHub
curl -o $TEMP_FILE https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# Si curl no funciona, prueba con wget:
# wget -O $TEMP_FILE https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# Verificar que se descargó (debe tener más de 1MB)
ls -lh $TEMP_FILE
```

**Si funciona:** Verás algo como:
```
-rw-r--r-- 1 root root 2.1M Dec 20 10:35 /tmp/dashboard_corregido.html
```

**Si no funciona:**
- Verifica que tengas conexión a internet
- Verifica que curl o wget estén instalados: `which curl` o `which wget`

---

### Paso 5: Verificar que el Archivo Tiene la Corrección

```bash
# Buscar la corrección en el archivo descargado
grep -n "if (!window.saveHotelChanges)" $TEMP_FILE

# Si encuentra algo, verás una línea como:
# 6457:        if (!window.saveHotelChanges) {
```

**Si NO encuentra nada:**
- El archivo puede no haberse descargado correctamente
- Intenta descargarlo de nuevo: `curl -o $TEMP_FILE https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html`

---

### Paso 6: Copiar el Archivo al Contenedor

```bash
# Reemplaza "checkin24hs-dashboard-1" con el nombre de TU contenedor
CONTAINER_NAME="checkin24hs-dashboard-1"
DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"
TEMP_FILE="/tmp/dashboard_corregido.html"

# Copiar el archivo
docker cp $TEMP_FILE $CONTAINER_NAME:$DASHBOARD_PATH

# Verificar que se copió
docker exec $CONTAINER_NAME ls -lh $DASHBOARD_PATH
```

**Si funciona:** Verás algo como:
```
-rw-r--r-- 1 root root 2.1M Dec 20 10:35 /usr/share/nginx/html/dashboard.html
```

---

### Paso 7: Verificar que la Corrección Está en el Contenedor

```bash
# Buscar la corrección en el archivo del contenedor
docker exec $CONTAINER_NAME grep -n "if (!window.saveHotelChanges)" $DASHBOARD_PATH

# Si encuentra algo, verás:
# 6457:        if (!window.saveHotelChanges) {
```

**Si NO encuentra nada:**
- El archivo puede no haberse copiado correctamente
- Intenta copiarlo de nuevo: `docker cp $TEMP_FILE $CONTAINER_NAME:$DASHBOARD_PATH`

---

### Paso 8: Verificar que NO Hay Declaraciones Duplicadas

```bash
# Buscar todas las declaraciones de saveHotelChanges
docker exec $CONTAINER_NAME grep -n "function saveHotelChanges\|async function saveHotelChanges" $DASHBOARD_PATH

# Si encuentra algo, verás líneas como:
# 6457:        if (!window.saveHotelChanges) {
# 6458:            window.saveHotelChanges = async function(event, hotelId) {
```

**Si encuentra `function saveHotelChanges` o `async function saveHotelChanges` (sin el `if (!window.saveHotelChanges)`):**
- Hay una declaración duplicada problemática
- Necesitamos eliminarla manualmente (ver Paso 9)

---

### Paso 9 (Solo si hay duplicados): Eliminar Declaraciones Duplicadas

```bash
# Ver todas las líneas con saveHotelChanges
docker exec $CONTAINER_NAME grep -n "saveHotelChanges" $DASHBOARD_PATH | head -20

# Si ves algo como:
# 1234:        async function saveHotelChanges(event, hotelId) {
# (sin el "if (!window.saveHotelChanges)" antes)
# Entonces hay una declaración duplicada

# Para eliminarla, necesitas editar el archivo dentro del contenedor
# Opción 1: Usar sed para comentar la línea problemática
docker exec $CONTAINER_NAME sed -i 's/^\([[:space:]]*\)async function saveHotelChanges/\1\/\/ async function saveHotelChanges (DUPLICADA - ELIMINADA)/' $DASHBOARD_PATH

# Opción 2: Editar manualmente con nano/vi
docker exec -it $CONTAINER_NAME nano $DASHBOARD_PATH
# Busca la línea problemática (Ctrl+W, escribe "async function saveHotelChanges")
# Comenta la línea agregando // al inicio
# Guarda (Ctrl+O, Enter, Ctrl+X)
```

---

### Paso 10: Reiniciar el Contenedor

```bash
# Reiniciar el contenedor
docker restart $CONTAINER_NAME

# Esperar 5 segundos
sleep 5

# Verificar que está corriendo
docker ps | grep $CONTAINER_NAME
```

**Si funciona:** Verás el contenedor en la lista con estado "Up"

**Si NO funciona:**
- Verifica los logs: `docker logs $CONTAINER_NAME --tail 50`
- Puede haber un error de sintaxis en el archivo

---

### Paso 11: Limpiar Archivos Temporales

```bash
# Eliminar el archivo temporal
rm -f /tmp/dashboard_corregido.html

# Verificar que se eliminó
ls -lh /tmp/dashboard_corregido.html
# Debe decir: "No such file or directory"
```

---

### Paso 12: Verificar en el Navegador

1. **Abre el dashboard:**
   - Ve a `https://dashboard.checkin24hs.com`

2. **Limpia el caché:**
   - Presiona **Ctrl+F5** (Windows/Linux) o **Cmd+Shift+R** (Mac)
   - O abre en modo incógnito

3. **Abre la consola:**
   - Presiona **F12**
   - Ve a la pestaña "Console"

4. **Verifica que NO hay errores:**
   - NO debe aparecer: `Identifier 'saveHotelChanges' has already been declared`
   - Debe aparecer: `✅ Cliente de Supabase inicializado correctamente`

5. **Verifica que la función existe:**
   - En la consola, escribe: `typeof window.saveHotelChanges`
   - Debe retornar: `"function"`

---

## 🆘 Solución de Problemas

### Problema: "docker: command not found"
**Solución:**
- Docker no está instalado o no está en el PATH
- Verifica: `which docker`
- Si no está, instálalo o usa el terminal de EasyPanel

### Problema: "Cannot connect to the Docker daemon"
**Solución:**
- Docker no está corriendo o no tienes permisos
- Intenta: `sudo docker ps`
- O verifica que Docker esté corriendo: `systemctl status docker`

### Problema: "Container not found"
**Solución:**
- El nombre del contenedor es diferente
- Lista todos los contenedores: `docker ps -a`
- Busca el que tenga "dashboard" o "checkin24hs" en el nombre
- Usa ese nombre en lugar de "checkin24hs-dashboard-1"

### Problema: "Permission denied"
**Solución:**
- No tienes permisos para ejecutar docker
- Intenta con sudo: `sudo docker ...`
- O agrega tu usuario al grupo docker: `sudo usermod -aG docker $USER`

### Problema: "curl: command not found"
**Solución:**
- curl no está instalado
- Instálalo: `sudo apt-get install curl` (Ubuntu/Debian) o `sudo yum install curl` (CentOS/RHEL)
- O usa wget: `wget -O /tmp/dashboard_corregido.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html`

### Problema: El error persiste después de aplicar
**Solución:**
1. Verifica que el archivo se copió correctamente:
   ```bash
   docker exec $CONTAINER_NAME head -100 $DASHBOARD_PATH | grep -A 5 "saveHotelChanges"
   ```

2. Verifica que el contenedor se reinició:
   ```bash
   docker ps | grep $CONTAINER_NAME
   ```

3. Limpia el caché del navegador completamente:
   - Chrome: Ctrl+Shift+Delete → "Cached images and files" → "All time"
   - Firefox: Ctrl+Shift+Delete → "Cache" → "Everything"

4. Prueba en modo incógnito

---

## ✅ Checklist Final

- [ ] Me conecté al servidor
- [ ] Encontré el contenedor del dashboard
- [ ] Creé un backup del archivo actual
- [ ] Descargué el archivo corregido desde GitHub
- [ ] Verifiqué que tiene la corrección (`if (!window.saveHotelChanges)`)
- [ ] Copié el archivo al contenedor
- [ ] Verifiqué que la corrección está en el contenedor
- [ ] Verifiqué que NO hay declaraciones duplicadas
- [ ] Reinicié el contenedor
- [ ] Limpié archivos temporales
- [ ] Verifiqué en el navegador (Ctrl+F5)
- [ ] Verifiqué la consola (F12) - NO hay errores
- [ ] Verifiqué que `typeof window.saveHotelChanges` retorna `"function"`

---

## 💡 Notas Importantes

- **Siempre crea un backup** antes de modificar archivos
- **Verifica cada paso** antes de continuar al siguiente
- **Si algo falla**, detente y revisa el error
- **El nombre del contenedor puede ser diferente** - verifica con `docker ps`
- **La ruta del archivo puede ser diferente** - verifica con `docker exec $CONTAINER_NAME find / -name "dashboard.html" 2>/dev/null`

---

## 📞 Si Necesitas Ayuda

Si tienes problemas en algún paso específico:
1. Copia el comando exacto que ejecutaste
2. Copia el error completo que recibiste
3. Indica en qué paso estás
4. Te ayudo a resolverlo

