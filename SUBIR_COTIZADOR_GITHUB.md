# 📤 Subir Cotizador a GitHub y Actualizar desde EasyPanel

## 📋 Paso 1: Subir archivos a GitHub

### Desde tu máquina local (Windows):

```powershell
# Abrir PowerShell en la carpeta del proyecto
cd c:\Users\German\Downloads\Checkin24hs

# Verificar estado de Git
git status

# Agregar los archivos actualizados
git add cotizador-cliente.html supabase-config.js supabase-client.js

# Verificar qué se va a subir
git status

# Hacer commit
git commit -m "Actualizar cotizador-cliente con logging mejorado para Supabase"

# Subir a GitHub
git push
```

### Verificar que se subieron:

1. Ve a tu repositorio en GitHub: `https://github.com/GermanPerez-ai/checkin24hs`
2. Verifica que los archivos estén actualizados
3. Puedes ver el contenido directamente en:
   - `https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html`
   - `https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-config.js`
   - `https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js`

---

## 📋 Paso 2: Actualizar desde EasyPanel

### Opción A: Usando el script automático (Recomendado)

1. **Conectarte al servidor por SSH:**
   ```bash
   ssh root@TU_SERVIDOR
   ```

2. **Copiar el script al servidor:**
   ```bash
   # Desde tu máquina local (PowerShell)
   scp ACTUALIZAR_COTIZADOR_DESDE_GITHUB.sh root@TU_SERVIDOR:/root/
   ```

3. **Ejecutar el script en el servidor:**
   ```bash
   # En el servidor
   chmod +x /root/ACTUALIZAR_COTIZADOR_DESDE_GITHUB.sh
   /root/ACTUALIZAR_COTIZADOR_DESDE_GITHUB.sh
   ```

El script:
- ✅ Descarga los archivos desde GitHub
- ✅ Busca automáticamente el contenedor/servicio del cotizador
- ✅ Copia los archivos al lugar correcto
- ✅ Reinicia el servicio si es necesario

### Opción B: Desde EasyPanel (Interfaz Web)

1. **Accede a EasyPanel:**
   - Ve a tu panel de EasyPanel
   - Busca el servicio del cotizador

2. **Usar Terminal/SSH desde EasyPanel:**
   - Si EasyPanel tiene una terminal integrada, úsala
   - O conecta por SSH desde fuera

3. **Ejecutar comandos manuales:**
   ```bash
   # Buscar el contenedor
   docker ps | grep cotizador
   
   # Descargar archivos desde GitHub
   curl -L -o /tmp/cotizador-cliente.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html
   curl -L -o /tmp/supabase-config.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-config.js
   curl -L -o /tmp/supabase-client.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js
   
   # Copiar al contenedor (reemplaza CONTAINER_ID)
   docker cp /tmp/cotizador-cliente.html CONTAINER_ID:/usr/share/nginx/html/
   docker cp /tmp/supabase-config.js CONTAINER_ID:/usr/share/nginx/html/
   docker cp /tmp/supabase-client.js CONTAINER_ID:/usr/share/nginx/html/
   
   # Reiniciar el contenedor
   docker restart CONTAINER_ID
   ```

### Opción C: Si el cotizador usa un volumen montado

1. **Encontrar el volumen montado:**
   ```bash
   # Si es un servicio Docker Swarm
   docker service inspect SERVICIO_COTIZADOR | grep -A 10 Mounts
   
   # O buscar en EasyPanel la configuración de volúmenes
   ```

2. **Descargar directamente al volumen:**
   ```bash
   # Reemplaza /ruta/del/volumen con la ruta real
   cd /ruta/del/volumen
   
   curl -L -o cotizador-cliente.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html
   curl -L -o supabase-config.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-config.js
   curl -L -o supabase-client.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js
   
   # Reiniciar el servicio
   docker service update --force SERVICIO_COTIZADOR
   ```

---

## ✅ Verificar que funcionó

1. **Abrir en el navegador:**
   ```
   https://cotizar.checkin24hs.com/
   ```

2. **Abrir la consola del navegador (F12)**

3. **Enviar una cotización de prueba**

4. **Verificar en la consola que aparezcan estos logs:**
   - `📋 Iniciando envío de cotización...`
   - `🔑 Código generado: ... (5 caracteres)`
   - `🔍 🔍 🔍 VERIFICANDO SUPABASE...`
   - `☁️ ☁️ ☁️ INTENTANDO GUARDAR EN SUPABASE...`
   - `✅ ✅ ✅ ✅ ✅ ÉXITO TOTAL: Cotización guardada en Supabase`

5. **Verificar en el dashboard:**
   - Abre tu dashboard
   - Ve a la sección "Cotizaciones"
   - Deberías ver la nueva cotización aparecer automáticamente con una notificación verde

---

## 🔄 Proceso completo resumido

```bash
# 1. En tu máquina local (PowerShell)
cd c:\Users\German\Downloads\Checkin24hs
git add cotizador-cliente.html supabase-config.js supabase-client.js
git commit -m "Actualizar cotizador-cliente"
git push

# 2. En el servidor (SSH)
ssh root@TU_SERVIDOR
/root/ACTUALIZAR_COTIZADOR_DESDE_GITHUB.sh

# 3. Verificar
# Abre https://cotizar.checkin24hs.com/ y prueba enviar una cotización
```

---

## 🆘 Solución de problemas

### Si los archivos no se actualizan:

1. **Verificar que se subieron a GitHub:**
   - Ve a: `https://github.com/GermanPerez-ai/checkin24hs/tree/main`
   - Verifica que los archivos tengan la fecha/hora reciente

2. **Verificar que se descargaron en el servidor:**
   ```bash
   # Verificar tamaño de archivos descargados
   ls -lh /tmp/cotizador-cliente.html
   ```

3. **Verificar que se copiaron al contenedor:**
   ```bash
   docker exec CONTAINER_ID ls -la /usr/share/nginx/html/cotizador-cliente.html
   ```

4. **Limpiar caché del navegador:**
   - Presiona `Ctrl + Shift + R` para recargar sin caché
   - O abre en modo incógnito

5. **Reiniciar el contenedor/servicio:**
   ```bash
   docker restart CONTAINER_ID
   # O
   docker service update --force SERVICIO_NOMBRE
   ```

---

## 📝 Notas importantes

- ⚠️ **Siempre verifica** que los archivos se subieron correctamente a GitHub antes de actualizar en el servidor
- 🔄 Puede tomar unos minutos para que los cambios se reflejen
- 🌐 Si usas CDN o caché, puede ser necesario limpiarlo
- 📱 Prueba desde diferentes dispositivos para asegurarte
