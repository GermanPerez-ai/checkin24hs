# 🔧 Solución Definitiva: Archivo Obsoleto en Cotizador

## 🎯 Problema

Después de configurar Traefik, el dominio `cotizar.checkin24hs.com` sigue mostrando el archivo obsoleto `index.html` (con "TUS RESERVAS TIENEN BENEFICIOS") en lugar del formulario de cotización `cotizador-cliente.html`.

## 🔍 Diagnóstico

El problema es que **el contenedor tiene el archivo incorrecto**. Necesitamos verificar qué archivo está realmente en el contenedor.

### Paso 1: Verificar qué archivo está sirviendo el contenedor

Ejecuta en el servidor:

```bash
# Buscar el contenedor
CONTAINER_ID=$(docker ps --format "{{.ID}}" --filter "name=checkin24hs_cotizador" | head -1)

# Ver qué archivo está en index.html
docker exec $CONTAINER_ID cat /usr/share/nginx/html/index.html | head -30
```

**Si muestra "TUS RESERVAS TIENEN BENEFICIOS":**
- El contenedor tiene el archivo incorrecto
- Necesitas reconstruir el servicio

**Si muestra "Solicitar Cotización":**
- El contenedor tiene el archivo correcto
- El problema puede ser caché o configuración de nginx

---

## ✅ Solución

### Opción 1: Reconstruir el Servicio en EasyPanel (Recomendado)

1. **Accede a EasyPanel:**
   - Ve a: `http://72.61.58.240:3000`
   - Inicia sesión

2. **Ve al servicio `cotizador`:**
   - Busca el servicio `cotizador` en el proyecto `checkin24hs`
   - Haz clic en él

3. **Verifica la configuración:**
   - Ve a la pestaña **"Fuente"** o **"Source"**
   - Verifica que:
     - **Dockerfile:** `Dockerfile.cotizador`
     - **Build Path:** `/` (raíz del repositorio)
     - **Branch:** `main` (o la rama correcta)

4. **Reconstruir el servicio:**
   - Haz clic en **"Reconstruir"** o **"Rebuild"**
   - Espera 2-5 minutos a que termine la compilación

5. **Después de reconstruir, vuelve a configurar Traefik:**
   ```bash
   docker service update \
     --label-add "traefik.enable=true" \
     --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
     --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
     --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
     --label-add "traefik.http.routers.cotizador.service=cotizador-service" \
     --label-add "traefik.http.services.cotizador-service.loadbalancer.server.port=80" \
     --label-add "traefik.docker.network=easypanel" \
     checkin24hs_cotizador
   ```

---

### Opción 2: Verificar y Corregir el Dockerfile

1. **Verifica que `Dockerfile.cotizador` existe y está correcto:**

   El Dockerfile debe copiar `cotizador-cliente.html` como `index.html`:

   ```dockerfile
   FROM nginx:alpine

   # Copiar el archivo HTML principal
   COPY cotizador-cliente.html /usr/share/nginx/html/index.html

   # Copiar archivos de Supabase necesarios
   COPY supabase-config.js /usr/share/nginx/html/
   COPY supabase-client.js /usr/share/nginx/html/
   ```

2. **Verifica que `cotizador-cliente.html` existe en el repositorio:**
   ```bash
   # En tu computadora local
   ls -la cotizador-cliente.html
   ```

3. **Si el archivo no existe o el Dockerfile está mal, corrígelo y sube los cambios a GitHub**

4. **Luego reconstruye el servicio en EasyPanel**

---

### Opción 3: Forzar Actualización del Contenedor (Temporal)

Si necesitas una solución rápida mientras corriges el Dockerfile:

```bash
# 1. Obtener el contenedor
CONTAINER_ID=$(docker ps --format "{{.ID}}" --filter "name=checkin24hs_cotizador" | head -1)

# 2. Copiar el archivo correcto desde el servidor (si existe)
# Primero verifica si existe en el servidor:
ls -la /root/checkin24hs/cotizador-cliente.html

# 3. Si existe, cópialo al contenedor:
docker cp /root/checkin24hs/cotizador-cliente.html $CONTAINER_ID:/usr/share/nginx/html/index.html

# 4. Reiniciar nginx en el contenedor
docker exec $CONTAINER_ID nginx -s reload
```

**Nota:** Esta solución es temporal. Si el servicio se reinicia, se perderá. Debes corregir el Dockerfile.

---

## 🔍 Verificación Final

Después de reconstruir:

1. **Verifica el archivo en el contenedor:**
   ```bash
   CONTAINER_ID=$(docker ps --format "{{.ID}}" --filter "name=checkin24hs_cotizador" | head -1)
   docker exec $CONTAINER_ID cat /usr/share/nginx/html/index.html | head -30
   ```

   Debe mostrar "Solicitar Cotización", NO "TUS RESERVAS TIENEN BENEFICIOS"

2. **Prueba desde el navegador:**
   - Abre: `https://cotizar.checkin24hs.com/`
   - Debe mostrar el formulario de cotización

---

## 📝 Resumen

**Problema:** El contenedor tiene `index.html` obsoleto en lugar de `cotizador-cliente.html`

**Causa:** El Dockerfile no está copiando el archivo correcto, o el servicio no se reconstruyó después de actualizar el Dockerfile

**Solución:** 
1. Verificar que `Dockerfile.cotizador` copia `cotizador-cliente.html` como `index.html`
2. Reconstruir el servicio en EasyPanel
3. Volver a configurar las etiquetas de Traefik
