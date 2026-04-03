# 🔧 Solución Error 404 en EasyPanel

## 🎯 Problema

Después de hacer redeploy en EasyPanel, obtienes:
```
GET https://dashboard.checkin24hs.com/ 404 (Not Found)
```

## ✅ Solución: Verificar Configuración de EasyPanel

### Paso 1: Verificar Build Path

1. **En EasyPanel**, ve al servicio `dashboard`
2. Ve a la pestaña **"Source"** o **"Fuente"**
3. Verifica el **"Build Path"** o **"Ruta de compilación"**:
   - ✅ **Correcto**: `/deploy` (porque el Dockerfile está en `deploy/`)
   - ❌ **Incorrecto**: `/` (si el Dockerfile está en `deploy/`)

### Paso 2: Verificar Tipo de Servicio

1. En la misma pestaña **"Source"**, verifica el **"Build Type"** o **"Tipo de compilación"**:
   - ✅ **Correcto**: `Dockerfile`
   - ❌ **Incorrecto**: `Nixpacks` o `Static Site` (si estás usando Dockerfile)

### Paso 3: Verificar Ubicación del Dockerfile

1. En **"Source"**, verifica el campo **"Dockerfile Path"** o **"Ruta del Dockerfile"**:
   - ✅ **Correcto**: `Dockerfile` (si Build Path es `/deploy`)
   - ✅ **O**: `deploy/Dockerfile` (si Build Path es `/`)

### Paso 4: Verificar que el Archivo Exista

El Dockerfile debe copiar `dashboard.html` desde el directorio correcto:

**Si Build Path es `/deploy`:**
- El Dockerfile debe tener: `COPY . /usr/share/nginx/html/`
- Esto copiará `dashboard.html` desde `deploy/dashboard.html`

**Si Build Path es `/`:**
- El Dockerfile debe tener: `COPY deploy/ /usr/share/nginx/html/`
- O el Dockerfile debe estar en la raíz y copiar desde `deploy/`

## 🔍 Verificación Rápida

### Opción A: Build Path = `/deploy` (Recomendado)

**Configuración en EasyPanel:**
- **Build Path**: `/deploy`
- **Build Type**: `Dockerfile`
- **Dockerfile Path**: `Dockerfile`

**Dockerfile debe estar en `deploy/Dockerfile` y tener:**
```dockerfile
FROM nginx:alpine

# Eliminar configuración por defecto
RUN rm -rf /usr/share/nginx/html/*
RUN rm /etc/nginx/conf.d/default.conf

# Copiar archivos del dashboard (desde deploy/)
COPY . /usr/share/nginx/html/

# Crear configuración de nginx
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index dashboard.html index.html;\n\
    \n\
    location / {\n\
        try_files $uri $uri/ /dashboard.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Opción B: Build Path = `/` (Alternativa)

**Configuración en EasyPanel:**
- **Build Path**: `/`
- **Build Type**: `Dockerfile`
- **Dockerfile Path**: `deploy/Dockerfile`

**Dockerfile debe estar en `deploy/Dockerfile` y tener:**
```dockerfile
FROM nginx:alpine

# Eliminar configuración por defecto
RUN rm -rf /usr/share/nginx/html/*
RUN rm /etc/nginx/conf.d/default.conf

# Copiar archivos del dashboard (desde deploy/)
COPY deploy/ /usr/share/nginx/html/

# Crear configuración de nginx
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index dashboard.html index.html;\n\
    \n\
    location / {\n\
        try_files $uri $uri/ /dashboard.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

## 🚀 Pasos para Corregir

### 1. Verificar Configuración Actual

1. En EasyPanel, ve al servicio `dashboard`
2. Anota la configuración actual:
   - Build Path: `?`
   - Build Type: `?`
   - Dockerfile Path: `?`

### 2. Ajustar Configuración

**Si Build Path es `/deploy`:**
- ✅ Asegúrate de que el Dockerfile esté en `deploy/Dockerfile`
- ✅ Asegúrate de que `dashboard.html` esté en `deploy/dashboard.html`
- ✅ Dockerfile Path debe ser: `Dockerfile`

**Si Build Path es `/`:**
- ✅ Asegúrate de que el Dockerfile esté en `deploy/Dockerfile`
- ✅ Dockerfile Path debe ser: `deploy/Dockerfile`
- ✅ El Dockerfile debe copiar desde `deploy/`

### 3. Guardar y Redeploy

1. **Guarda** los cambios en EasyPanel
2. Haz clic en **"Deploy"** o **"Redeploy"**
3. Espera 2-3 minutos a que termine la construcción

### 4. Verificar Logs

1. En EasyPanel, ve a la pestaña **"Logs"** del servicio
2. Verifica que no haya errores durante el build
3. Busca mensajes como:
   - ✅ `COPY . /usr/share/nginx/html/`
   - ✅ `nginx: configuration file /etc/nginx/nginx.conf test is successful`
   - ❌ `COPY failed: file not found`

## 🔍 Verificación en el Contenedor

Si tienes acceso SSH al servidor, puedes verificar:

```bash
# Verificar que el contenedor esté corriendo
docker ps | grep dashboard

# Verificar que el archivo exista en el contenedor
docker exec <container_id> ls -la /usr/share/nginx/html/

# Verificar que dashboard.html exista
docker exec <container_id> test -f /usr/share/nginx/html/dashboard.html && echo "✅ Existe" || echo "❌ No existe"

# Verificar configuración de nginx
docker exec <container_id> cat /etc/nginx/conf.d/default.conf
```

## 📋 Resumen de Configuración Correcta

**Recomendación: Build Path = `/deploy`**

```
Build Path: /deploy
Build Type: Dockerfile
Dockerfile Path: Dockerfile
```

**Archivos necesarios:**
- ✅ `deploy/Dockerfile` (existe)
- ✅ `deploy/dashboard.html` (existe)
- ✅ `deploy/nginx.conf` (opcional, el Dockerfile crea su propia config)

## ⚠️ Si Sigue Sin Funcionar

1. **Verifica que el archivo esté en GitHub:**
   ```bash
   # Verificar que dashboard.html esté en deploy/
   curl -s https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/deploy/dashboard.html | head -5
   ```

2. **Verifica que el Dockerfile esté en GitHub:**
   ```bash
   # Verificar que Dockerfile esté en deploy/
   curl -s https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/deploy/Dockerfile
   ```

3. **Forzar rebuild sin caché:**
   - En EasyPanel, busca opción "Rebuild without cache"
   - O modifica el Dockerfile para invalidar caché

---

**Fecha**: 2025-01-27
**Estado**: Guía de solución para error 404
