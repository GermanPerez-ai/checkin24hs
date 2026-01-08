# 🔧 CORREGIR EASYPANEL - Paso a Paso

## 🎯 Objetivo

Corregir la configuración de EasyPanel para que despliegue automáticamente los cambios desde GitHub.

---

## 📋 Paso 1: Acceder a EasyPanel

1. Abre tu navegador y ve a tu panel de EasyPanel
2. Inicia sesión con tus credenciales
3. Navega al proyecto `checkin24hs`
4. Haz clic en el servicio `dashboard`

---

## 📋 Paso 2: Verificar Configuración de Source

1. En el menú lateral, busca la sección **"Source"** o **"Origen"**
2. Verifica que el tipo sea **"GitHub"** (NO "Upload" o "File Upload")
3. Si dice "Upload", necesitas cambiarlo a "GitHub"

### Si el Source NO es GitHub:

1. Haz clic en **"Edit"** o **"Configurar"** en la sección Source
2. Selecciona **"GitHub"** como tipo de origen
3. Configura:
   - **Repositorio:** `GermanPerez-ai/checkin24hs`
   - **Rama:** `main`
   - **Build Path:** `deploy`
4. Guarda los cambios

---

## 📋 Paso 3: Verificar Configuración Actual

Verifica que estos valores estén correctos:

- ✅ **Tipo:** GitHub
- ✅ **Repositorio:** `GermanPerez-ai/checkin24hs`
- ✅ **Rama:** `main` ⚠️ **CRÍTICO**
- ✅ **Build Path:** `deploy` ⚠️ **CRÍTICO**

---

## 📋 Paso 4: Forzar Re-Deploy

Si la configuración ya está correcta pero no se despliegan los cambios:

### Opción A: Cambiar Rama (Recomendado)

1. En la sección Source, cambia la **Rama** de `main` a `working-version`
2. Haz clic en **"Save"** o **"Guardar"**
3. Espera 30 segundos
4. Cambia la **Rama** de vuelta a `main`
5. Haz clic en **"Save"** o **"Guardar"**
6. Haz clic en el botón **"Deploy"** (verde) o **"Desplegar"**
7. Espera a que termine el build (puede tardar 2-5 minutos)

### Opción B: Re-Deploy Directo

1. Haz clic en el botón **"Deploy"** (verde) o **"Desplegar"**
2. Espera a que termine el build
3. Si no funciona, usa la Opción A

---

## 📋 Paso 5: Verificar el Deploy

1. Espera a que el build termine (verás un mensaje de éxito)
2. Abre `https://dashboard.checkin24hs.com`
3. Presiona **Ctrl+F5** para forzar recarga (limpiar caché)
4. Verifica que:
   - ✅ "Panel de Administración" es **AZUL** (no gris)
   - ✅ Los modales funcionan correctamente
   - ✅ No hay errores en la consola (F12)

---

## 📋 Paso 6: Verificar Logs del Build

Si el deploy no funciona, revisa los logs:

1. En EasyPanel, busca la sección **"Logs"** o **"Build Logs"**
2. Verifica que muestre:
   - ✅ "Cloning from GitHub"
   - ✅ "Using build path: deploy"
   - ✅ "Building from GitHub repository"
3. Si hay errores, cópialos y revisa la sección de solución de problemas

---

## 🔍 Solución de Problemas

### Problema: "Build Path not found"

**Solución:** Verifica que el Build Path sea exactamente `deploy` (sin barra al final)

### Problema: "Repository not found"

**Solución:** Verifica que el repositorio sea `GermanPerez-ai/checkin24hs` (con mayúsculas/minúsculas exactas)

### Problema: "Branch not found"

**Solución:** Verifica que la rama sea `main` (no `master` ni `working-version`)

### Problema: El deploy termina pero no se ven cambios

**Solución:**
1. Limpia la caché del navegador (Ctrl+Shift+Delete)
2. Recarga con Ctrl+F5
3. Verifica que el archivo `deploy/dashboard.html` existe en GitHub
4. Verifica que el archivo tiene el cambio azul (línea 171)

---

## ✅ Checklist Final

- [ ] Source configurado como "GitHub"
- [ ] Repositorio: `GermanPerez-ai/checkin24hs`
- [ ] Rama: `main`
- [ ] Build Path: `deploy`
- [ ] Deploy completado exitosamente
- [ ] "Panel de Administración" es AZUL
- [ ] Modales funcionan correctamente
- [ ] No hay errores en consola

---

## 📞 Si Nada Funciona

Si después de seguir todos los pasos el problema persiste:

1. **Eliminar y recrear el servicio:**
   - En EasyPanel, elimina el servicio `dashboard`
   - Crea un nuevo servicio desde GitHub
   - Configura: rama `main`, Build Path `deploy`

2. **Verificar que el archivo existe en GitHub:**
   - Ve a: https://github.com/GermanPerez-ai/checkin24hs/tree/main/deploy
   - Verifica que `dashboard.html` existe
   - Abre el archivo y verifica que la línea 171 tiene `color: #1976d2;`

---

**¡Listo! Después de seguir estos pasos, EasyPanel debería desplegar automáticamente los cambios desde GitHub.**

