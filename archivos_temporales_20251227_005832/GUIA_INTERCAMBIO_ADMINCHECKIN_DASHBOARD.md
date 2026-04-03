# 🔄 Guía: Intercambiar admincheckin con Dashboard en EasyPanel

## 🎯 Objetivo

Reemplazar el contenido del servicio **"dashboard"** en EasyPanel (proyecto checkin24hs) con el contenido de la carpeta local **"admincheckin"** que funciona correctamente.

---

## 📋 Paso 1: Ubicar la Carpeta admincheckin

Primero, necesitamos saber dónde está exactamente la carpeta `admincheckin`:

### Opción A: Si está en el mismo proyecto
- Ruta: `C:\Users\German\Downloads\Checkin24hs\admincheckin`

### Opción B: Si está en otra ubicación
- Puede estar en: `C:\Users\German\admincheckin` o en otra carpeta

**Verifica la ubicación exacta antes de continuar.**

---

## 📋 Paso 2: Verificar el Contenido de admincheckin

Antes de hacer el intercambio, verifica que la carpeta `admincheckin` contenga:

- ✅ `package.json` (si es una aplicación React/Node.js)
- ✅ `src/` o archivos fuente
- ✅ Archivos de configuración necesarios

---

## 📋 Paso 3: Opciones para el Intercambio

Tienes **3 opciones** para hacer el intercambio:

---

### ✅ Opción 1: Subir admincheckin a GitHub (Recomendado)

Esta es la mejor opción si quieres que EasyPanel se actualice automáticamente desde GitHub.

#### Paso 3.1: Preparar admincheckin

1. **Copia la carpeta `admincheckin`** al proyecto:
   ```powershell
   # Si admincheckin está fuera del proyecto, cópiala aquí
   Copy-Item -Path "C:\ruta\a\admincheckin" -Destination "C:\Users\German\Downloads\Checkin24hs\admincheckin" -Recurse
   ```

2. **Verifica que tenga los archivos necesarios**:
   - `package.json`
   - `src/` o archivos fuente
   - `.gitignore` (opcional pero recomendado)

#### Paso 3.2: Subir a GitHub

1. **Abre Git Bash o PowerShell** en la carpeta del proyecto:
   ```powershell
   cd C:\Users\German\Downloads\Checkin24hs
   ```

2. **Agrega la carpeta admincheckin**:
   ```bash
   git add admincheckin/
   git commit -m "Reemplazar dashboard con admincheckin funcional"
   git push
   ```

3. **Espera** a que GitHub actualice el repositorio (1-2 minutos)

#### Paso 3.3: Configurar EasyPanel

1. **Accede a EasyPanel** → Proyecto **"checkin24hs"** → Servicio **"dashboard"**

2. **Ve a "Fuente" (Source)**:
   - **Ruta de compilación**: Cambia de `/checkin24hs-admin` a `/admincheckin`
   - **Guarda** los cambios

3. **Verifica las demás configuraciones**:
   - **Comando de build**: `npm install && npm run build` (si es React)
   - **Carpeta de salida**: `build` (si es React)
   - **Comando de inicio**: `npx serve -s build -l 3000` (si es React estático)
   - **Puerto interno**: `3000`
   - **Dominio**: `dashboard.checkin24hs.com` (puerto `3000`)

4. **Implementa el servicio**:
   - Haz clic en **"Implementar"** o **"Deploy"**
   - Espera 3-5 minutos mientras construye

---

### ✅ Opción 2: Reemplazar checkin24hs-admin con admincheckin

Si prefieres mantener el nombre `checkin24hs-admin` en GitHub pero usar el contenido de `admincheckin`:

#### Paso 3.1: Hacer Backup (IMPORTANTE)

1. **Copia la carpeta actual** por si acaso:
   ```powershell
   Copy-Item -Path "checkin24hs-admin" -Destination "checkin24hs-admin-backup" -Recurse
   ```

#### Paso 3.2: Reemplazar el Contenido

1. **Elimina el contenido de checkin24hs-admin** (excepto `.git` si existe):
   ```powershell
   Remove-Item -Path "checkin24hs-admin\*" -Recurse -Force -Exclude ".git"
   ```

2. **Copia el contenido de admincheckin** a checkin24hs-admin:
   ```powershell
   Copy-Item -Path "admincheckin\*" -Destination "checkin24hs-admin\" -Recurse
   ```

#### Paso 3.3: Subir a GitHub

1. **Agrega los cambios**:
   ```bash
   git add checkin24hs-admin/
   git commit -m "Reemplazar checkin24hs-admin con admincheckin funcional"
   git push
   ```

#### Paso 3.4: EasyPanel se Actualizará Automáticamente

- Si EasyPanel está configurado con **Auto Deploy**, se actualizará automáticamente
- Si no, ve a EasyPanel y haz clic en **"Implementar"**

---

### ✅ Opción 3: Subir Manualmente a EasyPanel (No Recomendado)

Si no quieres usar GitHub, puedes subir los archivos directamente:

#### Paso 3.1: Crear un ZIP

1. **Comprime la carpeta admincheckin**:
   ```powershell
   Compress-Archive -Path "admincheckin" -DestinationPath "admincheckin.zip"
   ```

#### Paso 3.2: Subir a EasyPanel

1. **Accede a EasyPanel** → Servicio **"dashboard"**
2. **Ve a "Storage" o "Files"**
3. **Sube el ZIP** y extráelo
4. **Reconfigura** la ruta de compilación a `/admincheckin`
5. **Implementa** el servicio

⚠️ **Nota**: Esta opción es más complicada y no se actualiza automáticamente.

---

## 📋 Paso 4: Verificar que Funciona

Después de hacer el intercambio:

1. **Revisa los logs** en EasyPanel:
   - Debe mostrar que está construyendo correctamente
   - No debe haber errores

2. **Accede al dashboard**:
   - URL: `https://dashboard.checkin24hs.com`
   - Debe cargar la nueva versión

3. **Prueba las funcionalidades**:
   - Login
   - Navegación
   - Funciones principales

---

## 🆘 Solución de Problemas

### Problema: EasyPanel no encuentra la carpeta

**Solución**:
- Verifica que la ruta de compilación sea exactamente `/admincheckin` (con la barra inicial)
- Verifica que la carpeta esté en GitHub en la rama `main`

### Problema: Error al construir

**Solución**:
- Revisa los logs en EasyPanel
- Verifica que `admincheckin` tenga un `package.json` válido
- Verifica que todas las dependencias estén en `package.json`

### Problema: El dashboard sigue mostrando la versión antigua

**Solución**:
1. Limpia la caché del navegador (Ctrl+F5)
2. Espera 2-3 minutos después del despliegue
3. Verifica que el servicio esté en verde en EasyPanel

---

## ✅ Checklist Final

Antes de considerar que está listo:

- [ ] La carpeta `admincheckin` está en GitHub (o reemplazó `checkin24hs-admin`)
- [ ] La ruta de compilación en EasyPanel apunta a `/admincheckin`
- [ ] El servicio está en verde (Running) en EasyPanel
- [ ] Los logs muestran que se construyó correctamente
- [ ] Puedes acceder a `dashboard.checkin24hs.com` y ver la nueva versión
- [ ] Las funcionalidades principales funcionan

---

## 💡 Recomendación

**Te recomiendo usar la Opción 1 o 2** (subir a GitHub), porque:
- ✅ Se actualiza automáticamente cuando hagas cambios
- ✅ Tienes control de versiones
- ✅ Es más fácil de mantener
- ✅ EasyPanel puede hacer Auto Deploy

---

## 📝 Resumen Rápido (Opción Recomendada)

1. **Copia** `admincheckin` al proyecto (o reemplaza `checkin24hs-admin`)
2. **Sube** a GitHub: `git add . && git commit -m "..." && git push`
3. **Configura** EasyPanel: Ruta de compilación = `/admincheckin`
4. **Implementa** el servicio en EasyPanel
5. **Verifica** que funcione en `dashboard.checkin24hs.com`

---

¿Necesitas ayuda con algún paso específico? ¡Dime dónde está exactamente tu carpeta `admincheckin` y te ayudo a hacer el intercambio!

