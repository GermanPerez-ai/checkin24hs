# 📤 Guía para Subir Archivos del Cotizador al Servidor

## Archivos que necesitas subir:

1. **cotizador-cliente.html** (actualizado con logging mejorado)
2. **supabase-config.js** (configuración de Supabase)
3. **supabase-client.js** (cliente de Supabase)

## Ubicación de los archivos locales:

```
c:\Users\German\Downloads\Checkin24hs\
├── cotizador-cliente.html
├── supabase-config.js
└── supabase-client.js
```

## Métodos para subir los archivos:

### Método 1: Usando SCP (desde Windows con PowerShell o WSL)

```powershell
# Conectarte al servidor y copiar archivos
scp cotizador-cliente.html root@TU_SERVIDOR:/ruta/del/servidor/
scp supabase-config.js root@TU_SERVIDOR:/ruta/del/servidor/
scp supabase-client.js root@TU_SERVIDOR:/ruta/del/servidor/
```

### Método 2: Usando Docker (si tienes acceso SSH al servidor)

1. **Conectarte al servidor:**
   ```bash
   ssh root@TU_SERVIDOR
   ```

2. **Buscar el contenedor del cotizador:**
   ```bash
   docker ps | grep cotizador
   # O buscar el servicio
   docker service ls | grep cotizador
   ```

3. **Copiar archivos al contenedor:**
   ```bash
   # Si es un contenedor
   docker cp cotizador-cliente.html CONTAINER_ID:/usr/share/nginx/html/
   docker cp supabase-config.js CONTAINER_ID:/usr/share/nginx/html/
   docker cp supabase-client.js CONTAINER_ID:/usr/share/nginx/html/
   
   # Si es un servicio Docker Swarm, necesitas copiar al volumen montado
   # Primero encontrar el volumen:
   docker service inspect SERVICIO_COTIZADOR | grep -A 10 Mounts
   ```

### Método 3: Usando GitHub (recomendado si ya lo usas)

1. **Subir los archivos a GitHub:**
   ```bash
   git add cotizador-cliente.html supabase-config.js supabase-client.js
   git commit -m "Actualizar cotizador-cliente con logging mejorado"
   git push
   ```

2. **En el servidor, descargar desde GitHub:**
   ```bash
   curl -L -o cotizador-cliente.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html
   curl -L -o supabase-config.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-config.js
   curl -L -o supabase-client.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js
   ```

3. **Copiar al contenedor o volumen:**
   ```bash
   # Si tienes un volumen montado
   cp cotizador-cliente.html /ruta/del/volumen/
   cp supabase-config.js /ruta/del/volumen/
   cp supabase-client.js /ruta/del/volumen/
   
   # Reiniciar el servicio si es necesario
   docker service update --force SERVICIO_COTIZADOR
   ```

### Método 4: Usando Panel de Control (cPanel, Plesk, etc.)

1. Accede al panel de control de tu hosting
2. Ve al administrador de archivos
3. Navega a la carpeta donde está el cotizador (probablemente `public_html` o similar)
4. Sube los 3 archivos reemplazando los existentes

## Verificar que se subieron correctamente:

1. **Verificar que los archivos están en el servidor:**
   ```bash
   # En el servidor
   ls -la /ruta/del/servidor/cotizador-cliente.html
   ls -la /ruta/del/servidor/supabase-config.js
   ls -la /ruta/del/servidor/supabase-client.js
   ```

2. **Verificar en el navegador:**
   - Abre `https://cotizar.checkin24hs.com/`
   - Abre la consola del navegador (F12)
   - Deberías ver los nuevos logs cuando envíes una cotización

3. **Probar el guardado:**
   - Completa el formulario en `https://cotizar.checkin24hs.com/`
   - Envía una cotización
   - Verifica en la consola que aparezcan los logs:
     - `📋 Iniciando envío de cotización...`
     - `🔍 🔍 🔍 VERIFICANDO SUPABASE...`
     - `☁️ ☁️ ☁️ INTENTANDO GUARDAR EN SUPABASE...`

## Si necesitas ayuda para encontrar la ruta del servidor:

Ejecuta en el servidor:
```bash
# Buscar contenedores relacionados con cotizador
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}" | grep -i cotiz

# Buscar servicios
docker service ls | grep -i cotiz

# Ver configuración de un servicio
docker service inspect SERVICIO_NOMBRE | grep -A 20 Mounts
```

## Notas importantes:

- ⚠️ **Haz backup** de los archivos actuales antes de reemplazarlos
- 🔄 Puede ser necesario **reiniciar el contenedor/servicio** después de copiar
- 📝 Verifica que los **permisos** de los archivos sean correctos (generalmente 644)
- 🌐 Si usas **caché**, puede ser necesario limpiarlo o esperar unos minutos
