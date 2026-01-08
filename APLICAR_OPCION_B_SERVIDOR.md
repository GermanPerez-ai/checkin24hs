# 🚀 Aplicar Opción B en el Servidor - Guía Paso a Paso

## 📋 Objetivo

Aplicar el `dashboard.html` restaurado desde GitHub (rama main) directamente en el servidor.

---

## 🔧 Paso 1: Conectarte al Servidor

### Si tienes acceso SSH:

```bash
ssh root@72.61.58.240
```

O si tu usuario es diferente:

```bash
ssh tu-usuario@72.61.58.240
```

### Si usas EasyPanel:

1. Entra a tu panel de EasyPanel
2. Busca el servicio "dashboard" o "checkin24hs"
3. Busca un botón que diga "Terminal", "Console", "SSH" o "Shell"
4. Haz clic ahí

---

## 🔍 Paso 2: Encontrar el Contenedor

Una vez conectado, escribe:

```bash
docker ps | grep dashboard
```

**Ejemplo de salida:**
```
CONTAINER ID   IMAGE                    STATUS         NAMES
abc123def456   nginx:latest             Up 2 hours     checkin24hs-dashboard-1
```

**Anota el nombre del contenedor** (en este ejemplo: `checkin24hs-dashboard-1`)

**Si NO ves ningún contenedor:**
```bash
# Ver todos los contenedores
docker ps

# O buscar con "checkin24hs"
docker ps | grep checkin24hs
```

---

## 💾 Paso 3: Crear Backup (IMPORTANTE)

**Reemplaza `checkin24hs-dashboard-1` con el nombre de TU contenedor:**

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← CAMBIA ESTO

# Crear backup
docker exec $CONTAINER_NAME cp /usr/share/nginx/html/dashboard.html /tmp/dashboard_backup_servidor_$(date +%Y%m%d_%H%M%S).html

# Verificar que se creó
docker exec $CONTAINER_NAME ls -lh /tmp/dashboard_backup_servidor_*.html
```

**Si funciona:** Verás algo como:
```
-rw-r--r-- 1 root root 2.1M Dec 20 14:30 /tmp/dashboard_backup_servidor_20241220_143045.html
```

---

## 📥 Paso 4: Descargar desde GitHub (Rama main)

```bash
# Descargar el archivo desde GitHub (rama main)
curl -o /tmp/dashboard_restaurado.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# Verificar que se descargó
ls -lh /tmp/dashboard_restaurado.html
```

**Si funciona:** Verás algo como:
```
-rw-r--r-- 1 root root 2.1M Dec 20 14:35 /tmp/dashboard_restaurado.html
```

**Si NO funciona (curl no encontrado):**
```bash
# Probar con wget
wget -O /tmp/dashboard_restaurado.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
```

**Si NO funciona (sin conexión):**
- Verifica tu conexión a internet: `ping google.com`
- O descarga el archivo localmente y súbelo con `scp`

---

## ✅ Paso 5: Verificar que el Archivo es Válido

```bash
# Verificar que es un archivo HTML válido
head -5 /tmp/dashboard_restaurado.html
```

**Si funciona:** Deberías ver:
```
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
```

---

## 📋 Paso 6: Copiar al Contenedor

**Reemplaza `checkin24hs-dashboard-1` con el nombre de TU contenedor:**

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← CAMBIA ESTO

# Copiar el archivo al contenedor
docker cp /tmp/dashboard_restaurado.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html
```

**Si funciona:** No verás ningún mensaje (eso es bueno)

**Si NO funciona:**
- Verifica que el nombre del contenedor sea correcto
- Verifica que el archivo existe: `ls -lh /tmp/dashboard_restaurado.html`
- Verifica que el contenedor está corriendo: `docker ps | grep $CONTAINER_NAME`

---

## 🔍 Paso 7: Verificar que se Copió Correctamente

```bash
# Verificar que el archivo está en el contenedor
docker exec $CONTAINER_NAME ls -lh /usr/share/nginx/html/dashboard.html
```

**Si funciona:** Verás algo como:
```
-rw-r--r-- 1 root root 2.1M Dec 20 14:35 /usr/share/nginx/html/dashboard.html
```

---

## 🔄 Paso 8: Reiniciar el Contenedor

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
- Verifica los logs: `docker logs $CONTAINER_NAME --tail 20`
- Puede haber un error de sintaxis en el archivo

---

## 🧹 Paso 9: Limpiar Archivo Temporal

```bash
# Eliminar el archivo temporal
rm /tmp/dashboard_restaurado.html

# Verificar que se eliminó
ls /tmp/dashboard_restaurado.html
```

**Si funciona:** Verás: `No such file or directory` (eso es bueno)

---

## ✅ Paso 10: Verificar en el Navegador

1. **Abre el dashboard:**
   - Ve a: `https://dashboard.checkin24hs.com`

2. **Limpia el caché:**
   - Presiona **Ctrl+F5** (Windows/Linux)
   - O **Cmd+Shift+R** (Mac)
   - O abre en modo incógnito

3. **Abre la consola:**
   - Presiona **F12**
   - Ve a la pestaña "Console"

4. **Verifica que NO hay errores:**
   - NO debe aparecer: `Identifier 'saveHotelChanges' has already been declared`
   - Debe aparecer: `✅ Cliente de Supabase inicializado correctamente`

5. **Intenta iniciar sesión:**
   - Verifica que el login funciona correctamente

---

## 📋 Comandos Completos (Copia y Pega)

```bash
# Configurar variables (CAMBIAR EL NOMBRE DEL CONTENEDOR)
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← CAMBIA ESTO

# Backup
docker exec $CONTAINER_NAME cp /usr/share/nginx/html/dashboard.html /tmp/dashboard_backup_servidor_$(date +%Y%m%d_%H%M%S).html

# Descargar desde GitHub
curl -o /tmp/dashboard_restaurado.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# Verificar
ls -lh /tmp/dashboard_restaurado.html

# Copiar al contenedor
docker cp /tmp/dashboard_restaurado.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html

# Verificar que se copió
docker exec $CONTAINER_NAME ls -lh /usr/share/nginx/html/dashboard.html

# Reiniciar
docker restart $CONTAINER_NAME
sleep 5

# Verificar que está corriendo
docker ps | grep $CONTAINER_NAME

# Limpiar
rm /tmp/dashboard_restaurado.html
```

---

## 🆘 Solución de Problemas

### Problema: "docker: command not found"
**Solución:**
```bash
# Verificar si docker está instalado
which docker

# Si no está, usar sudo
sudo docker ps
```

### Problema: "Container not found"
**Solución:**
```bash
# Listar todos los contenedores
docker ps -a

# Buscar el que tenga "dashboard" o "checkin24hs"
docker ps -a | grep -i dashboard
docker ps -a | grep -i checkin24hs
```

### Problema: "curl: command not found"
**Solución:**
```bash
# Usar wget en su lugar
wget -O /tmp/dashboard_restaurado.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
```

### Problema: "Permission denied"
**Solución:**
```bash
# Usar sudo
sudo docker cp /tmp/dashboard_restaurado.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html
sudo docker restart $CONTAINER_NAME
```

### Problema: El contenedor no se reinicia
**Solución:**
```bash
# Ver logs del contenedor
docker logs $CONTAINER_NAME --tail 50

# Verificar el estado
docker ps -a | grep $CONTAINER_NAME
```

---

## ✅ Checklist Final

- [ ] Me conecté al servidor
- [ ] Encontré el contenedor del dashboard
- [ ] Creé un backup del archivo actual
- [ ] Descargué el archivo desde GitHub (rama main)
- [ ] Verifiqué que el archivo es válido
- [ ] Copié el archivo al contenedor
- [ ] Verifiqué que se copió correctamente
- [ ] Reinicié el contenedor
- [ ] Verifiqué que está corriendo
- [ ] Limpié archivos temporales
- [ ] Verifiqué en el navegador (Ctrl+F5)
- [ ] Verifiqué la consola (F12) - NO hay errores
- [ ] Intenté iniciar sesión - Funciona

---

## 💡 Tips

- **Siempre crea un backup** antes de modificar archivos
- **Verifica cada paso** antes de continuar al siguiente
- **Si algo falla, detente** y revisa el error
- **El nombre del contenedor puede ser diferente** - verifica con `docker ps`
- **Si no estás seguro, pregunta** antes de continuar

---

## 📞 Si Necesitas Ayuda

Si tienes problemas en algún paso específico:
1. Copia el comando exacto que ejecutaste
2. Copia el error completo que recibiste
3. Indica en qué paso estás
4. Te ayudo a resolverlo

