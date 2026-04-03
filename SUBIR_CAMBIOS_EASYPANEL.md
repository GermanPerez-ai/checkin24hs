# 🚀 Guía: Subir Cambios del Dashboard a EasyPanel

## 📋 Resumen

Esta guía te ayudará a subir los cambios de `dashboard.html` (con versión y correcciones) a EasyPanel usando GitHub.

---

## ✅ Paso 1: Subir los Cambios a GitHub

### 1.1 Abre PowerShell en tu computadora

1. Presiona `Windows + X`
2. Selecciona **"Windows PowerShell"** o **"Terminal"**

### 1.2 Ve a la carpeta del proyecto

```powershell
cd C:\Users\German\Downloads\Checkin24hs
```

### 1.3 Verifica los cambios

```powershell
git status
```

Deberías ver `dashboard.html` como modificado.

### 1.4 Agrega los archivos modificados

```powershell
git add dashboard.html
git add deploy/dashboard.html
```

### 1.5 Confirma los cambios

```powershell
git commit -m "Agregar versión 2.1.0 y correcciones de cotizaciones/gastos"
```

### 1.6 Sube los cambios a GitHub

```powershell
git push
```

**⏱️ Espera unos segundos** mientras se suben los cambios.

---

## 🔄 Paso 2: Hacer Deploy desde EasyPanel

### 2.1 Accede a EasyPanel

1. Abre tu navegador
2. Ve a: `http://72.61.58.240:3000`
3. Inicia sesión con tus credenciales

### 2.2 Encuentra el servicio del Dashboard

1. Busca el proyecto **"checkin24hs"** (o el nombre que tengas)
2. Haz clic en el proyecto
3. Busca el servicio llamado **"dashboard"** (o **"checkin24hs-dashboard"**)
4. Haz clic en el servicio

### 2.3 Haz Deploy

1. Busca el botón **"Deploy"** o **"Desplegar"** (generalmente está arriba, verde)
2. Haz clic en **"Deploy"**
3. Espera 2-5 minutos mientras se despliega

**💡 Tip:** Puedes ver el progreso en la sección "Logs" o "Deployments"

---

## ✅ Paso 3: Verificar que Funciona

### 3.1 Limpia la caché del navegador

1. Abre: `https://dashboard.checkin24hs.com`
2. Presiona `Ctrl + Shift + R` (Windows) o `Cmd + Shift + R` (Mac)
   - Esto fuerza una recarga sin caché

### 3.2 Verifica la versión en la consola

1. Presiona `F12` para abrir la consola
2. Escribe: `window.DASHBOARD_VERSION`
3. Presiona Enter
4. **Debería mostrar:** `"2.1.0"`

Si ves `"2.1.0"`, ¡los cambios están aplicados correctamente! 🎉

### 3.3 Verifica que funciona

1. Navega a la sección **"Cotizaciones"**
2. Navega a la sección **"Gastos"**
3. Verifica que el contenido se muestra correctamente

---

## 🔍 Si No Funciona

### Problema 1: No veo el botón "Deploy"

**Solución:**
- Busca el botón **"Redeploy"** o **"Redesplegar"**
- O busca **"Rebuild"** o **"Reconstruir"**

### Problema 2: El deploy falla

**Solución:**
1. Ve a la sección **"Logs"** en EasyPanel
2. Lee los errores
3. Verifica que el repositorio GitHub está configurado correctamente

### Problema 3: Sigue mostrando la versión antigua

**Solución:**
1. Espera 2-3 minutos más (a veces tarda en propagarse)
2. Cierra completamente el navegador y ábrelo de nuevo
3. Abre en modo incógnito (Ctrl+Shift+N)
4. Verifica en la consola si hay errores (F12)

### Problema 4: No puedo subir a GitHub

**Solución alternativa:**
Si no puedes usar GitHub, puedes subir el archivo directamente al servidor usando WinSCP o SCP:

```powershell
# Desde PowerShell
scp dashboard.html root@72.61.58.240:/tmp/dashboard.html
```

Luego conecta al servidor por SSH y copia el archivo manualmente.

---

## 📝 Notas Importantes

- ✅ Los cambios incluyen:
  - Variable de versión `window.DASHBOARD_VERSION = '2.1.0'`
  - Log de versión en la consola
  - Correcciones de carga de cotizaciones y gastos
  - Versión actualizada de `supabase-client.js` (v=3.1.1)

- ⏱️ El deploy puede tardar 2-5 minutos
- 🔄 Siempre limpia la caché del navegador después del deploy (Ctrl+Shift+R)
- ✅ Verifica la versión escribiendo `window.DASHBOARD_VERSION` en la consola

---

## 🎉 ¡Listo!

Una vez que veas `"2.1.0"` en la consola, los cambios están aplicados correctamente.

Si tienes algún problema, revisa los logs de EasyPanel o verifica la configuración del servicio.