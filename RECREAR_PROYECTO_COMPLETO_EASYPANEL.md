# 🔄 Recrear Proyecto Completo en EasyPanel

## 🎯 Objetivo

Recrear el proyecto `checkin24hs` y el servicio `checkin24hs-dashboard` con la configuración correcta.

## 📋 Paso 1: Crear el Proyecto

1. **En la página principal de EasyPanel** (donde estás ahora)
2. **Haz clic en "+ Nuevo"** o **"Crear proyecto"** (botón grande abajo)
3. **Nombre del proyecto**: `checkin24hs`
4. **Crea el proyecto**

## 📋 Paso 2: Crear el Servicio Dashboard

1. **Dentro del proyecto `checkin24hs`**, haz clic en **"+ Servicio"** o **"Agregar Servicio"**
2. **Nombre del servicio**: `checkin24hs-dashboard` (con guión, NO con guión bajo)
3. **Tipo**: Aplicación o App
4. **Crea el servicio**

## 📋 Paso 3: Configurar la Fuente

1. **Ve a** → **Servicios** → `checkin24hs-dashboard` → **Fuente**
2. **Configura**:
   - Tipo: **GitHub**
   - Propietario: `GermanPerez-ai`
   - Repositorio: `checkin24hs`
   - Rama: `working-version`
   - Ruta de compilación: `/checkin24hs-admin`
3. **Haz clic en "Guardar"**

## 📋 Paso 4: Configurar Compilación

1. **Busca la sección "Compilación"** o ve a esa pestaña
2. **Selecciona**: **Nixpacks**
3. **Guarda** (si hay botón de guardar)

## 📋 Paso 5: Configurar Puertos

1. **Ve a "Puertos"** en el menú lateral
2. **Haz clic en "Agregar puerto"**
3. **Configura**:
   - Protocolo: `TCP`
   - Publicado: `30002`
   - Destino: `3000`
4. **Crea el puerto**

## 📋 Paso 6: Implementar

1. **Haz clic en "Implementar"** (botón verde arriba)
2. **Espera** a que termine la construcción (2-5 minutos)
3. **Verifica** que el servicio esté en verde (Running)

## 📋 Paso 7: Configurar Dominio

1. **Ve a "Dominios"** en el menú lateral
2. **Haz clic en "Agregar dominio"**
3. **Configura**:
   - Host: `dashboard.checkin24hs.com`
   - Ruta: `/`
   - Protocolo: `HTTP`
   - Puerto: `3000`
   - Target Service: Debería aparecer automáticamente `checkin24hs-dashboard`
4. **Crea el dominio**

## 📋 Paso 8: Probar

1. **Espera** a que el servicio esté en verde
2. **Abre una ventana de incógnito** (Ctrl+Shift+N)
3. **Accede a** `https://dashboard.checkin24hs.com`
4. **Debería funcionar** con el código de hace 17 horas

---

**Empieza creando el proyecto `checkin24hs` y luego el servicio. Te guío en cada paso si tienes dudas.**

