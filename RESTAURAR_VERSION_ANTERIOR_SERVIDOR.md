# 🔄 Restaurar Versión Anterior del Dockerfile en el Servidor

## 🎯 Objetivo

Restaurar el Dockerfile a la versión anterior (`COPY . /usr/share/nginx/html/`) directamente en el servidor, sin pasar por GitHub y EasyPanel.

## ✅ Opción 1: Editar Dockerfile en el Servidor (Recomendado)

### Paso 1: Conectarse al Servidor

```bash
# Conectarse por SSH al servidor
ssh root@72.61.58.240
# O la IP de tu servidor
```

### Paso 2: Encontrar el Contenedor del Dashboard

```bash
# Ver contenedores corriendo
docker ps | grep dashboard

# O ver todos los contenedores
docker ps -a | grep dashboard
```

### Paso 3: Editar el Dockerfile en el Servidor

```bash
# Ir al directorio donde está el código clonado
cd /root/checkin24hs  # O donde esté clonado el repositorio

# Editar el Dockerfile
nano deploy/Dockerfile
# O
vi deploy/Dockerfile
```

### Paso 4: Cambiar la Línea 9

**Cambiar de:**
```dockerfile
COPY deploy/ /usr/share/nginx/html/
```

**A:**
```dockerfile
COPY . /usr/share/nginx/html/
```

### Paso 5: Guardar y Salir

- En `nano`: `Ctrl + X`, luego `Y`, luego `Enter`
- En `vi`: `Esc`, luego `:wq`, luego `Enter`

### Paso 6: Reconstruir el Contenedor

```bash
# Detener el contenedor actual
docker stop <container_id>

# Reconstruir la imagen
cd /root/checkin24hs
docker build -f deploy/Dockerfile -t dashboard:latest .

# O si EasyPanel tiene un script de build
# Buscar el comando que usa EasyPanel para construir
```

---

## ✅ Opción 2: Cambiar Build Path en EasyPanel (Más Simple)

En lugar de editar el Dockerfile, puedes cambiar la configuración en EasyPanel:

1. **Ve a EasyPanel** → Servicio `dashboard` → Pestaña "Fuente"
2. **Cambia "Ruta de compilación"** de `/` a `/deploy`
3. **En "Compilación"**, cambia "Archivo" de `deploy/Dockerfile` a `Dockerfile`
4. **Guarda** y haz **redeploy**

Esto hará que el contexto de build sea `/deploy`, y entonces `COPY .` funcionará correctamente.

---

## ✅ Opción 3: Editar Dockerfile Directamente en el Contenedor (Temporal)

Si solo quieres probar rápidamente:

```bash
# Conectarse al contenedor
docker exec -it <container_id> sh

# Editar el Dockerfile (si está montado)
# Pero esto no funcionará porque el Dockerfile no está en el contenedor final
```

**Nota**: Esta opción no funcionará porque el Dockerfile no está en el contenedor final, solo los archivos copiados.

---

## ✅ Opción 4: Restaurar desde Backup Local

Si tienes una copia local del Dockerfile anterior:

```bash
# En tu máquina local
scp deploy/Dockerfile.backup root@72.61.58.240:/root/checkin24hs/deploy/Dockerfile

# Luego en el servidor, reconstruir
ssh root@72.61.58.240
cd /root/checkin24hs
docker build -f deploy/Dockerfile -t dashboard:latest .
```

---

## 🔍 Verificar Versión Actual en el Servidor

```bash
# Ver el contenido del Dockerfile en el servidor
cat /root/checkin24hs/deploy/Dockerfile | grep COPY
```

---

## ⚠️ Importante

Si cambias el Dockerfile en el servidor:
- Los cambios se perderán en el próximo deploy desde EasyPanel
- EasyPanel reconstruirá desde GitHub en el próximo deploy
- Para hacer el cambio permanente, también debes actualizar GitHub

---

## 🎯 Recomendación

**La mejor opción es la Opción 2**: Cambiar el Build Path en EasyPanel de `/` a `/deploy`. Esto es más simple y no requiere acceso SSH al servidor.
