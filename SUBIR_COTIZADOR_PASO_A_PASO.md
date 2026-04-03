# 📤 Guía Paso a Paso para Subir Archivos del Cotizador

## 📋 Archivos a subir:

1. ✅ `cotizador-cliente.html` (ya actualizado con logging mejorado)
2. ✅ `supabase-config.js` 
3. ✅ `supabase-client.js`

## 🚀 Opción 1: Usando GitHub (MÁS FÁCIL)

### Paso 1: Subir archivos a GitHub

```bash
# En tu máquina local (en la carpeta del proyecto)
cd c:\Users\German\Downloads\Checkin24hs

# Verificar que los archivos estén listos
git status

# Agregar los archivos
git add cotizador-cliente.html supabase-config.js supabase-client.js

# Hacer commit
git commit -m "Actualizar cotizador-cliente con logging mejorado para Supabase"

# Subir a GitHub
git push
```

### Paso 2: En el servidor, descargar desde GitHub

```bash
# Conectarte al servidor
ssh root@TU_SERVIDOR

# Ir a la carpeta donde están los archivos del cotizador
cd /ruta/del/cotizador  # (necesitas encontrar esta ruta)

# Descargar los archivos actualizados
curl -L -o cotizador-cliente.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html
curl -L -o supabase-config.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-config.js
curl -L -o supabase-client.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js

# Verificar que se descargaron
ls -la cotizador-cliente.html supabase-config.js supabase-client.js
```

### Paso 3: Copiar al contenedor Docker

```bash
# Buscar el contenedor del cotizador
docker ps | grep cotizador

# Si encuentras el contenedor, copiar los archivos
docker cp cotizador-cliente.html CONTAINER_ID:/usr/share/nginx/html/
docker cp supabase-config.js CONTAINER_ID:/usr/share/nginx/html/
docker cp supabase-client.js CONTAINER_ID:/usr/share/nginx/html/

# O si es un servicio Docker Swarm, encontrar el volumen montado
docker service inspect cotizador | grep -A 10 Mounts
```

---

## 🚀 Opción 2: Usando SCP (desde Windows)

### Paso 1: Preparar los archivos

Asegúrate de tener los 3 archivos en:
```
c:\Users\German\Downloads\Checkin24hs\
```

### Paso 2: Usar PowerShell o WinSCP

**Con PowerShell:**
```powershell
# Conectarte y copiar archivos
scp cotizador-cliente.html root@TU_SERVIDOR:/tmp/
scp supabase-config.js root@TU_SERVIDOR:/tmp/
scp supabase-client.js root@TU_SERVIDOR:/tmp/
```

**O usar WinSCP:**
1. Abre WinSCP
2. Conéctate a tu servidor
3. Navega a `/tmp/` en el servidor
4. Arrastra los 3 archivos desde tu carpeta local

### Paso 3: En el servidor, copiar al contenedor

```bash
# Conectarte al servidor
ssh root@TU_SERVIDOR

# Buscar el contenedor
docker ps | grep cotizador

# Copiar desde /tmp/ al contenedor
docker cp /tmp/cotizador-cliente.html CONTAINER_ID:/usr/share/nginx/html/
docker cp /tmp/supabase-config.js CONTAINER_ID:/usr/share/nginx/html/
docker cp /tmp/supabase-client.js CONTAINER_ID:/usr/share/nginx/html/
```

---

## 🚀 Opción 3: Script Automático (si tienes acceso SSH)

### Paso 1: Copiar el script al servidor

```bash
# Desde tu máquina local
scp SUBIR_COTIZADOR_DIRECTO.sh root@TU_SERVIDOR:/root/
scp cotizador-cliente.html root@TU_SERVIDOR:/root/
scp supabase-config.js root@TU_SERVIDOR:/root/
scp supabase-client.js root@TU_SERVIDOR:/root/
```

### Paso 2: Ejecutar el script en el servidor

```bash
# Conectarte al servidor
ssh root@TU_SERVIDOR

# Dar permisos de ejecución
chmod +x /root/SUBIR_COTIZADOR_DIRECTO.sh

# Ejecutar el script
cd /root
./SUBIR_COTIZADOR_DIRECTO.sh
```

---

## 🔍 Cómo encontrar la información necesaria:

### Encontrar el contenedor del cotizador:

```bash
# En el servidor
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}" | grep -i cotiz
```

### Encontrar el servicio Docker Swarm:

```bash
docker service ls | grep -i cotiz
```

### Ver la configuración de un servicio:

```bash
docker service inspect SERVICIO_NOMBRE | grep -A 20 Mounts
```

### Ver dónde están los archivos en un contenedor:

```bash
docker exec CONTAINER_ID ls -la /usr/share/nginx/html/
# O probar otras rutas comunes
docker exec CONTAINER_ID find / -name "cotizador-cliente.html" 2>/dev/null
```

---

## ✅ Verificar que funcionó:

1. **Abrir en el navegador:**
   ```
   https://cotizar.checkin24hs.com/
   ```

2. **Abrir la consola del navegador (F12)**

3. **Enviar una cotización de prueba**

4. **Verificar en la consola que aparezcan estos logs:**
   - `📋 Iniciando envío de cotización...`
   - `🔑 Código generado: ...`
   - `🔍 🔍 🔍 VERIFICANDO SUPABASE...`
   - `☁️ ☁️ ☁️ INTENTANDO GUARDAR EN SUPABASE...`
   - `✅ ✅ ✅ ✅ ✅ ÉXITO TOTAL: Cotización guardada en Supabase`

5. **Verificar en el dashboard:**
   - Abre tu dashboard
   - Ve a la sección "Cotizaciones"
   - Deberías ver la nueva cotización aparecer automáticamente

---

## 🆘 Si algo no funciona:

1. **Verificar que los archivos se copiaron:**
   ```bash
   docker exec CONTAINER_ID ls -la /usr/share/nginx/html/cotizador-cliente.html
   ```

2. **Verificar permisos:**
   ```bash
   docker exec CONTAINER_ID chmod 644 /usr/share/nginx/html/cotizador-cliente.html
   ```

3. **Reiniciar el contenedor:**
   ```bash
   docker restart CONTAINER_ID
   # O si es un servicio
   docker service update --force SERVICIO_NOMBRE
   ```

4. **Limpiar caché del navegador:**
   - Presiona `Ctrl + Shift + R` para recargar sin caché
   - O abre en modo incógnito

5. **Ver logs del contenedor:**
   ```bash
   docker logs CONTAINER_ID --tail 50
   ```

---

## 📝 Notas importantes:

- ⚠️ **Siempre haz backup** antes de reemplazar archivos
- 🔄 Puede tomar unos minutos para que los cambios se reflejen
- 🌐 Si usas CDN o caché, puede ser necesario limpiarlo
- 📱 Prueba desde diferentes dispositivos para asegurarte
