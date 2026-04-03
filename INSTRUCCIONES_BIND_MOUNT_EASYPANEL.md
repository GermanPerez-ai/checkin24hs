# 📋 Instrucciones: Agregar Bind Mount en EasyPanel

## 🎯 Basado en la Pantalla que Estás Viendo

Veo que estás en la sección **"Puntos de montaje"** (Mount points) en EasyPanel.

---

## 📝 Pasos a Seguir

### 1. Haz Clic en "Agregar montaje de archivo"

De las tres opciones que ves:
- ❌ "Agregar montaje de enlace" (para directorios completos)
- ❌ "Agregar montaje de volumen" (para volúmenes Docker)
- ✅ **"Agregar montaje de archivo"** (para archivos individuales) ← **USA ESTA**

Haz clic en **"Agregar montaje de archivo"**.

---

### 2. Configura el Montaje

Después de hacer clic, deberías ver un formulario. Completa los campos:

- **Ruta del host (Source/Host Path):**
  ```
  /root/checkin24hs/dashboard.html
  ```

- **Ruta del contenedor (Destination/Container Path):**
  ```
  /app/dashboard.html
  ```

- **Solo lectura (Read Only):**
  - ✅ Desactivado (déjalo desactivado para permitir escritura si es necesario)

---

### 3. Guarda los Cambios

1. **Haz clic en "Guardar"** o "Aplicar" (el botón puede estar en diferentes lugares)
2. **Espera** a que EasyPanel actualice el servicio de Docker Swarm
3. El servicio se **recreará automáticamente** con el nuevo montaje

---

### 4. Verifica que Funcionó

Después de que el servicio se actualice (puede tardar 30-60 segundos), verifica en el servidor:

```bash
# En SSH
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
docker inspect "$CONTAINER" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
```

Deberías ver algo como:
```
bind /root/checkin24hs/dashboard.html -> /app/dashboard.html
```

---

## ✅ Después de Configurar

Una vez configurado el bind mount:

1. **El archivo `/root/checkin24hs/dashboard.html` en el servidor será el que use el contenedor**
2. **Los cambios en ese archivo se reflejarán automáticamente** en el contenedor
3. **El header debería mostrarse horizontal** y los emojis correctamente
4. **Ya no necesitarás copiar el archivo manualmente** al contenedor

---

## 💡 Nota Importante

El archivo `/root/checkin24hs/dashboard.html` en el servidor **ya tiene la estructura correcta** con `header-left`, así que después de configurar el bind mount, el header debería funcionar correctamente.

---

## 🔍 Si No Funciona

Si después de configurar el bind mount el archivo sigue sin funcionar:

1. **Verifica que el archivo existe:**
   ```bash
   ls -lh /root/checkin24hs/dashboard.html
   ```

2. **Verifica que tiene la estructura correcta:**
   ```bash
   grep -A 8 'class="header"' /root/checkin24hs/dashboard.html | head -9
   ```

3. **Reinicia el servicio desde EasyPanel** (botón de reinicio/refresh)
