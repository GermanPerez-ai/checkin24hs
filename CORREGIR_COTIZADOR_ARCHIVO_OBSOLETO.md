# 🔧 Corregir Cotizador - Archivo Obsoleto

## 🎯 Problema Identificado

El dominio `cotizar.checkin24hs.com` está mostrando la página obsoleta `index.html` (con "TUS RESERVAS TIENEN BENEFICIOS" y "TRYP by Wyndham Aruba") en lugar del formulario de cotización `cotizador-cliente.html`.

## 🔍 Causa Probable

El servicio del cotizador está sirviendo el archivo incorrecto. Esto puede deberse a:

1. **Bind mount apuntando al directorio incorrecto** - El servicio puede estar montando un directorio que contiene `index.html` obsoleto
2. **Contenedor no reconstruido** - El contenedor puede tener una versión antigua del archivo
3. **Configuración de nginx incorrecta** - Nginx puede estar sirviendo `index.html` en lugar del archivo correcto

## ✅ Solución

### Paso 1: Verificar el Servicio en EasyPanel

1. **Accede a EasyPanel:**
   - Ve a: `http://72.61.58.240:3000`
   - Inicia sesión

2. **Ve al servicio del cotizador:**
   - Busca el servicio llamado `cotizador` o similar
   - Haz clic en él

3. **Verifica la configuración:**
   - Ve a la pestaña **"Fuente"** o **"Source"**
   - Verifica que esté usando **`Dockerfile.cotizador`**
   - Verifica que el **Build Path** sea correcto

### Paso 2: Verificar el Dockerfile

El `Dockerfile.cotizador` debe copiar `cotizador-cliente.html` como `index.html`:

```dockerfile
FROM nginx:alpine

# Copiar el archivo HTML principal
COPY cotizador-cliente.html /usr/share/nginx/html/index.html

# Copiar archivos de Supabase necesarios
COPY supabase-config.js /usr/share/nginx/html/
COPY supabase-client.js /usr/share/nginx/html/
```

### Paso 3: Reconstruir el Contenedor

1. **En EasyPanel:**
   - Ve al servicio `cotizador`
   - Haz clic en **"Reconstruir"** o **"Rebuild"**
   - Espera a que termine la compilación (2-5 minutos)

2. **O desde SSH:**
   ```bash
   # Conectarse al servidor
   ssh root@72.61.58.240
   
   # Ver el servicio del cotizador
   docker service ls | grep cotizador
   
   # Forzar actualización del servicio
   docker service update --force checkin24hs_cotizador
   ```

### Paso 4: Verificar que el Archivo Correcto Está en el Contenedor

```bash
# En el servidor, ejecuta:
CONTAINER_ID=$(docker ps | grep cotizador | awk '{print $1}' | head -1)

# Verificar qué archivo está en index.html
docker exec $CONTAINER_ID cat /usr/share/nginx/html/index.html | head -20

# Debe mostrar el contenido de cotizador-cliente.html, no index.html obsoleto
```

**Si muestra contenido de `index.html` obsoleto:**
- El contenedor no se reconstruyó correctamente
- Necesitas forzar la reconstrucción

### Paso 5: Verificar Bind Mounts (Si los hay)

Si el servicio tiene bind mounts configurados:

1. **En EasyPanel:**
   - Ve al servicio `cotizador`
   - Ve a la pestaña **"Volúmenes"** o **"Volumes"**
   - Verifica si hay bind mounts configurados
   - Si hay un bind mount que apunta a un directorio con `index.html`, **elimínalo o cámbialo**

2. **O desde SSH:**
   ```bash
   # Ver configuración del servicio
   docker service inspect checkin24hs_cotizador | grep -A 10 Mounts
   ```

### Paso 6: Limpiar Caché del Navegador

Después de corregir el servicio:

1. **Abre el navegador en modo incógnito** o
2. **Limpia la caché:**
   - Presiona `Ctrl + Shift + Delete` (Windows/Linux) o `Cmd + Shift + Delete` (Mac)
   - Selecciona "Caché" o "Cached images and files"
   - Haz clic en "Limpiar"

3. **O fuerza recarga:**
   - Presiona `Ctrl + Shift + R` (Windows/Linux) o `Cmd + Shift + R` (Mac)

## 🔍 Verificación Final

1. **Accede a:** `https://cotizar.checkin24hs.com/`
2. **Debe mostrar:**
   - ✅ Título: "📋 Solicitar Cotización"
   - ✅ Formulario con campos: Nombre, Teléfono, Hotel, Check-in, etc.
   - ✅ Botón "Ver Promociones"
   - ❌ NO debe mostrar: "TUS RESERVAS TIENEN BENEFICIOS" ni "TRYP by Wyndham Aruba"

## 🆘 Si Sigue Mostrando el Archivo Obsoleto

### Opción 1: Eliminar y Recrear el Servicio

1. **En EasyPanel:**
   - Elimina el servicio `cotizador`
   - Crea un nuevo servicio con el mismo nombre
   - Configura:
     - **Fuente:** GitHub (tu repositorio)
     - **Build Path:** `/` (raíz del repositorio)
     - **Dockerfile:** `Dockerfile.cotizador`
     - **Puerto:** `80`
   - Agrega el dominio: `cotizar.checkin24hs.com`

### Opción 2: Verificar Archivos en el Repositorio

Asegúrate de que `cotizador-cliente.html` esté en el repositorio y no haya un `index.html` en el directorio raíz que se esté copiando:

```bash
# Verificar en el repositorio local
ls -la cotizador-cliente.html
ls -la index.html  # Este NO debe estar en la raíz si se usa para el cotizador
```

## 📝 Resumen

**El problema:** El servicio está sirviendo `index.html` obsoleto en lugar de `cotizador-cliente.html`.

**La solución:** Reconstruir el contenedor asegurándose de que use `Dockerfile.cotizador` que copia el archivo correcto.
