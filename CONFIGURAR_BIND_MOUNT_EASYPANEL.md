# 📋 Configurar Bind Mount en EasyPanel

## 🎯 Objetivo

Montar el archivo `dashboard.html` desde el host (`/root/checkin24hs/dashboard.html`) al contenedor (`/app/dashboard.html`) para que los cambios en el archivo del host se reflejen automáticamente en el contenedor.

---

## 📝 Pasos en EasyPanel

### 1. Acceder al Servicio

1. **Inicia sesión en EasyPanel**
2. **Navega al servicio `checkin24hs_dashboard`** (o `dashboard`)
3. **Haz clic en "Editar" o "Settings"** (o el botón de configuración)

---

### 2. Agregar Bind Mount

1. **Busca la sección "Volumes" o "Mounts"** (puede estar en diferentes lugares según la versión de EasyPanel):
   - Puede estar en la pestaña "Volumes"
   - O en "Advanced Settings"
   - O en "Environment & Storage"
   - O en "Configuration"

2. **Haz clic en "Add Volume" o "Add Mount"**

3. **Configura el bind mount:**
   - **Type:** `Bind Mount` o `Host Path`
   - **Source/Host Path:** `/root/checkin24hs/dashboard.html`
   - **Destination/Container Path:** `/app/dashboard.html`
   - **Read Only:** Desactivado (para poder escribir si es necesario)

4. **Guarda los cambios**

---

### 3. Actualizar el Servicio

Después de guardar, EasyPanel debería:
- **Actualizar automáticamente el servicio** de Docker Swarm
- **Recrear el contenedor** con el nuevo mount

Si no se actualiza automáticamente:
- Busca un botón **"Deploy"**, **"Update"** o **"Apply"**
- O **guarda** nuevamente para forzar la actualización

---

### 4. Verificar que Funciona

Después de que el servicio se actualice:

```bash
# En el servidor (SSH)
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)

# Verificar que tiene el mount
docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'

# Verificar estructura del header
docker exec "$CONTAINER" grep -A 8 'class="header"' /app/dashboard.html 2>/dev/null | head -9
```

Deberías ver:
- ✅ El bind mount en los mounts del contenedor
- ✅ La estructura correcta con `header-left` en el archivo

---

## ✅ Después de Configurar

Una vez configurado el bind mount:

1. **El archivo `/root/checkin24hs/dashboard.html` en el servidor será el que use el contenedor**
2. **Cualquier cambio en ese archivo se reflejará automáticamente** (aunque puede necesitar reiniciar el servicio)
3. **Ya no necesitarás copiar el archivo manualmente al contenedor**

---

## 💡 Notas

- **Ubicación del archivo:** Asegúrate de que el archivo existe en `/root/checkin24hs/dashboard.html` en el servidor
- **Permisos:** El archivo debe ser legible por el usuario del contenedor
- **Reinicio:** Si haces cambios al archivo, es posible que necesites reiniciar el servicio desde EasyPanel

---

## 🔍 Si No Encuentras la Opción de Volumes

Algunas versiones de EasyPanel pueden tener la opción en diferentes lugares:

- **En "Docker Compose" o "Dockerfile":** Si EasyPanel permite editar el docker-compose.yml, puedes agregar manualmente:
  ```yaml
  volumes:
    - /root/checkin24hs/dashboard.html:/app/dashboard.html
  ```

- **En "Environment Variables":** A veces los mounts están en variables de entorno

- **Contactar soporte:** Si no encuentras la opción, puede ser que tu versión de EasyPanel no permita bind mounts, y necesitarías actualizar la imagen Docker en su lugar
