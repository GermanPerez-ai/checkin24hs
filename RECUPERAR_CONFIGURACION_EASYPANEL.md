# 🆘 Recuperar Configuración de EasyPanel

## 🚨 Problema

Se eliminó todo de EasyPanel. Necesitamos recuperar la configuración.

## ✅ Verificaciones

### 1. ¿Qué se Eliminó Exactamente?

- ¿Se eliminó solo el servicio `checkin24hs-dashboard`?
- ¿Se eliminó todo el proyecto `checkin24hs`?
- ¿Se eliminaron otros servicios también?

### 2. Verificar si el Proyecto Existe

1. **En EasyPanel**, busca el proyecto `checkin24hs`
2. **¿Existe el proyecto?**
   - Si existe, podemos recrear el servicio
   - Si no existe, necesitamos recrear el proyecto primero

### 3. Verificar Servicios Existentes

1. **En el menú lateral**, busca "SERVICIOS"
2. **¿Qué servicios ves?**
   - ¿Sigue existiendo `dashboard` (el viejo)?
   - ¿Hay otros servicios?

## 🔄 Solución: Recrear el Servicio

Si el proyecto `checkin24hs` todavía existe:

### Paso 1: Crear el Servicio de Nuevo

1. **Haz clic en "+ Servicio"** o **"Agregar Servicio"**
2. **Nombre del servicio**: `checkin24hs-dashboard` (con guión)
3. **Tipo**: Aplicación o App

### Paso 2: Configurar la Fuente

1. **Ve a "Fuente"**
2. **Configura**:
   - Tipo: **GitHub**
   - Propietario: `GermanPerez-ai`
   - Repositorio: `checkin24hs`
   - Rama: `working-version`
   - Ruta de compilación: `/checkin24hs-admin`
3. **Guarda**

### Paso 3: Configurar Compilación

1. **Ve a "Compilación"** o busca la sección de compilación
2. **Selecciona**: **Nixpacks** (o Dockerfile si prefieres)
3. **Guarda**

### Paso 4: Configurar Puertos

1. **Ve a "Puertos"**
2. **Agrega puerto**:
   - Protocolo: `TCP`
   - Publicado: `30002`
   - Destino: `3000`
3. **Guarda**

### Paso 5: Implementar

1. **Haz clic en "Implementar"**
2. **Espera** a que termine

### Paso 6: Configurar Dominio

1. **Ve a "Dominios"**
2. **Crea o edita** el dominio `dashboard.checkin24hs.com`
3. **Configura**:
   - Host: `dashboard.checkin24hs.com`
   - Protocolo: `HTTP`
   - Puerto: `3000`
   - Target Service: `checkin24hs-dashboard` (con guión)
4. **Guarda**

---

**Primero dime: ¿el proyecto `checkin24hs` todavía existe en EasyPanel? ¿Qué servicios ves en la lista?**

