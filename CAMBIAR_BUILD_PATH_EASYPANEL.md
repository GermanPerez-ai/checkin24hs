# 🔧 Cambiar Build Path en EasyPanel (Solución Más Simple)

## 🎯 Problema

El Dockerfile actual usa `COPY . /usr/share/nginx/html/` que funciona cuando el Build Path es `/deploy`, pero actualmente está configurado como `/`.

## ✅ Solución: Cambiar Build Path en EasyPanel

### Paso 1: Ir a EasyPanel

1. Ve al servicio `dashboard`
2. Ve a la pestaña **"Fuente"** o **"Source"**

### Paso 2: Cambiar Ruta de Compilación

1. En el campo **"Ruta de compilación"** o **"Build Path"**:
   - ❌ **Actual**: `/`
   - ✅ **Cambiar a**: `/deploy`

2. En la sección **"Compilación"**, en el campo **"Archivo"**:
   - ❌ **Actual**: `deploy/Dockerfile`
   - ✅ **Cambiar a**: `Dockerfile`

### Paso 3: Guardar y Redeploy

1. Haz clic en **"Guardar"** en ambas secciones
2. Haz clic en **"Implementar"** o **"Deploy"**
3. Espera 2-3 minutos

## 📋 Configuración Final

**Fuente:**
- Ruta de compilación: `/deploy` ✅
- Rama: `main` ✅

**Compilación:**
- Tipo: `Dockerfile` ✅
- Archivo: `Dockerfile` ✅ (sin `deploy/`)

Con esta configuración, el Dockerfile con `COPY . /usr/share/nginx/html/` funcionará correctamente porque el contexto de build será `/deploy`.
