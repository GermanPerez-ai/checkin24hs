# 🔍 Verificar Archivos en el Contenedor

## 🎯 Problema

El dashboard devuelve 404, pero nginx está funcionando. Necesitamos verificar si `dashboard.html` está en el contenedor.

## ✅ Solución: Verificar en el Contenedor

### Opción 1: Desde EasyPanel (Si tiene terminal)

1. Ve a EasyPanel → Servicio `dashboard`
2. Busca una pestaña **"Terminal"** o **"Console"** o **"Shell"**
3. Si existe, ejecuta:
   ```bash
   ls -la /usr/share/nginx/html/
   ls -la /usr/share/nginx/html/dashboard.html
   ```

### Opción 2: Desde SSH al Servidor

Si tienes acceso SSH:

```bash
# Conectarse al servidor
ssh root@72.61.58.240

# Encontrar el contenedor
docker ps | grep dashboard

# Ver archivos en el contenedor
docker exec <container_id> ls -la /usr/share/nginx/html/

# Verificar si dashboard.html existe
docker exec <container_id> test -f /usr/share/nginx/html/dashboard.html && echo "✅ Existe" || echo "❌ No existe"

# Ver contenido del directorio
docker exec <container_id> ls -la /usr/share/nginx/html/ | head -20
```

### Opción 3: Verificar Build Logs

En EasyPanel, revisa los logs del build para ver si hay errores al copiar archivos.

---

## 🔧 Si el Archivo No Existe

Si `dashboard.html` no está en el contenedor, el problema es que no se está copiando correctamente durante el build.

### Verificar Build Path

Asegúrate de que:
- Build Path: `/deploy` ✅
- Archivo: `Dockerfile` ✅
- Dockerfile tiene: `COPY . /usr/share/nginx/html/` ✅

### Verificar que dashboard.html esté en deploy/

```bash
# En tu máquina local
ls -la deploy/dashboard.html
```

Si no existe, cópialo:
```bash
cp dashboard.html deploy/dashboard.html
git add deploy/dashboard.html
git commit -m "Agregar dashboard.html a deploy/"
git push origin main
```

---

## 📋 Verificación Rápida

Ejecuta esto en el contenedor para ver qué archivos hay:

```bash
docker exec <container_id> find /usr/share/nginx/html -name "*.html" -type f
```

Esto mostrará todos los archivos HTML en el contenedor.
