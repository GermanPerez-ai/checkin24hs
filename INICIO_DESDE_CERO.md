# 🚀 Corrección desde CERO - Guía Simple

## 📋 Paso 1: Conectarte al Servidor

### Opción A: Si tienes acceso SSH

1. **Abre tu terminal:**
   - Windows: PowerShell o CMD
   - Mac: Terminal
   - Linux: Terminal

2. **Conéctate al servidor:**
   ```bash
   ssh root@72.61.58.240
   ```
   O si tu usuario es diferente:
   ```bash
   ssh tu-usuario@72.61.58.240
   ```

3. **Si te pide contraseña, escríbela** (no verás lo que escribes, es normal)

### Opción B: Si usas EasyPanel

1. **Entra a EasyPanel:**
   - Ve a tu panel de EasyPanel
   - Busca el servicio "dashboard" o "checkin24hs"

2. **Abre el terminal web:**
   - Busca un botón que diga "Terminal", "Console", "SSH" o "Shell"
   - Haz clic ahí

### Opción C: Si no sabes cómo conectarte

**Pregúntame:**
- ¿Tienes acceso a EasyPanel?
- ¿Tienes la IP del servidor?
- ¿Tienes usuario y contraseña?

---

## ✅ Verificación del Paso 1

Cuando estés conectado, deberías ver algo como:
```
root@servidor:~# 
```
O
```
[usuario@servidor ~]$
```

**Si ves esto, ¡estás listo para el siguiente paso!**

---

## 📋 Paso 2: Verificar que Docker está Instalado

Escribe este comando:
```bash
docker --version
```

**Si funciona:** Verás algo como `Docker version 20.10.x`

**Si NO funciona:** 
- Escribe: `which docker`
- Si no muestra nada, Docker no está instalado o no está en el PATH
- Dime qué mensaje ves y te ayudo

---

## 📋 Paso 3: Encontrar el Contenedor del Dashboard

Escribe este comando:
```bash
docker ps
```

**Deberías ver una tabla con contenedores.** Busca uno que tenga "dashboard" o "checkin24hs" en el nombre.

**Ejemplo de lo que podrías ver:**
```
CONTAINER ID   IMAGE                    STATUS         NAMES
abc123def456   nginx:latest             Up 2 hours     checkin24hs-dashboard-1
```

**Anota el nombre del contenedor** (en este ejemplo: `checkin24hs-dashboard-1`)

**Si NO ves ningún contenedor:**
- Escribe: `docker ps -a` (muestra todos, incluso los detenidos)
- O escribe: `docker ps | grep dashboard`
- Dime qué ves y te ayudo

---

## 📋 Paso 4: Crear un Backup (IMPORTANTE)

**Reemplaza `checkin24hs-dashboard-1` con el nombre de TU contenedor:**

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"
docker exec $CONTAINER_NAME cp /usr/share/nginx/html/dashboard.html /tmp/dashboard_backup.html
```

**Verifica que se creó:**
```bash
docker exec $CONTAINER_NAME ls -lh /tmp/dashboard_backup.html
```

**Si funciona:** Verás algo como:
```
-rw-r--r-- 1 root root 2.1M Dec 20 10:30 /tmp/dashboard_backup.html
```

**Si NO funciona:**
- Verifica que el nombre del contenedor sea correcto
- Prueba primero: `docker exec $CONTAINER_NAME ls /usr/share/nginx/html/`
- Dime qué error ves

---

## 📋 Paso 5: Descargar el Archivo Corregido

```bash
curl -o /tmp/dashboard_corregido.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
```

**Verifica que se descargó:**
```bash
ls -lh /tmp/dashboard_corregido.html
```

**Si funciona:** Verás algo como:
```
-rw-r--r-- 1 root root 2.1M Dec 20 10:35 /tmp/dashboard_corregido.html
```

**Si NO funciona:**
- Prueba con wget: `wget -O /tmp/dashboard_corregido.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html`
- O verifica tu conexión a internet: `ping google.com`
- Dime qué error ves

---

## 📋 Paso 6: Verificar que Tiene la Corrección

```bash
grep "if (!window.saveHotelChanges)" /tmp/dashboard_corregido.html
```

**Si funciona:** Verás una línea como:
```
6457:        if (!window.saveHotelChanges) {
```

**Si NO funciona:**
- El archivo puede no haberse descargado correctamente
- Intenta descargarlo de nuevo (Paso 5)
- Dime qué ves

---

## 📋 Paso 7: Copiar el Archivo al Contenedor

**Reemplaza `checkin24hs-dashboard-1` con el nombre de TU contenedor:**

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"
docker cp /tmp/dashboard_corregido.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html
```

**Si funciona:** No verás ningún mensaje (eso es bueno)

**Si NO funciona:**
- Verifica que el nombre del contenedor sea correcto
- Verifica que el archivo existe: `ls -lh /tmp/dashboard_corregido.html`
- Dime qué error ves

---

## 📋 Paso 8: Verificar que se Copió Correctamente

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"
docker exec $CONTAINER_NAME grep "if (!window.saveHotelChanges)" /usr/share/nginx/html/dashboard.html
```

**Si funciona:** Verás una línea como:
```
6457:        if (!window.saveHotelChanges) {
```

**Si NO funciona:**
- El archivo puede no haberse copiado correctamente
- Intenta copiarlo de nuevo (Paso 7)
- Dime qué ves

---

## 📋 Paso 9: Reiniciar el Contenedor

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"
docker restart $CONTAINER_NAME
```

**Espera 5 segundos:**
```bash
sleep 5
```

**Verifica que está corriendo:**
```bash
docker ps | grep $CONTAINER_NAME
```

**Si funciona:** Verás el contenedor en la lista

**Si NO funciona:**
- Verifica los logs: `docker logs $CONTAINER_NAME --tail 20`
- Dime qué ves

---

## 📋 Paso 10: Limpiar Archivos Temporales

```bash
rm /tmp/dashboard_corregido.html
```

**Verifica que se eliminó:**
```bash
ls /tmp/dashboard_corregido.html
```

**Si funciona:** Verás: `No such file or directory` (eso es bueno)

---

## 📋 Paso 11: Verificar en el Navegador

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

5. **Verifica que la función existe:**
   - En la consola, escribe: `typeof window.saveHotelChanges`
   - Debe retornar: `"function"`

---

## 🆘 Si Algo Sale Mal

**En cualquier paso, si algo no funciona:**

1. **Copia el comando exacto que ejecutaste**
2. **Copia el error completo que recibiste**
3. **Dime en qué paso estás**
4. **Te ayudo a resolverlo**

---

## ✅ Checklist

- [ ] Paso 1: Conectado al servidor
- [ ] Paso 2: Docker funciona
- [ ] Paso 3: Encontré el contenedor
- [ ] Paso 4: Backup creado
- [ ] Paso 5: Archivo descargado
- [ ] Paso 6: Corrección verificada
- [ ] Paso 7: Archivo copiado al contenedor
- [ ] Paso 8: Corrección verificada en contenedor
- [ ] Paso 9: Contenedor reiniciado
- [ ] Paso 10: Archivos temporales limpiados
- [ ] Paso 11: Verificado en navegador - NO hay errores

---

## 💡 Tips

- **No te saltes pasos** - cada uno es importante
- **Verifica cada paso** antes de continuar
- **Si algo falla, detente** y dime qué pasó
- **El nombre del contenedor puede ser diferente** - verifica con `docker ps`

