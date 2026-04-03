# 📤 Subir Cambios del Dashboard al Servidor

## 🔍 Problema Actual

Los cambios que hicimos en `dashboard.html` (versión 2.1.0 y `supabase-client.js?v=3.1.1`) **NO están en el servidor**.

**Evidencia:**
- El navegador carga `supabase-client.js?v=3.1.0` (versión antigua)
- No aparecen los logs de versión en la consola
- No se puede verificar la versión con `window.DASHBOARD_VERSION`

---

## ✅ Solución: Subir Cambios a GitHub y Hacer Deploy en EasyPanel

### Paso 1: Subir a GitHub (desde tu computadora)

Abre **PowerShell** en Windows y ejecuta:

```powershell
# 1. Ir a la carpeta del proyecto
cd C:\Users\German\Downloads\Checkin24hs

# 2. Ver qué archivos cambiaron
git status

# 3. Agregar los archivos modificados
git add dashboard.html
git add deploy/dashboard.html

# 4. Guardar los cambios
git commit -m "Agregar versión 2.1.0 y actualizar supabase-client.js a v3.1.1"

# 5. Subir a GitHub
git push
```

### Paso 2: Hacer Deploy en EasyPanel

1. **Abre EasyPanel**: `http://72.61.58.240:3000`
2. **Busca el proyecto**: `checkin24hs`
3. **Abre el servicio**: `dashboard`
4. **Haz clic en "Deploy"** o **"Redeploy"**
5. **Espera 2-5 minutos** mientras se despliega

### Paso 3: Verificar que Funcionó

1. **Abre**: `https://dashboard.checkin24hs.com`
2. **Presiona `Ctrl + Shift + R`** (limpiar caché)
3. **Abre la consola** (F12)
4. **Deberías ver**:
   - Un mensaje grande: `📊 CHECKIN24HS DASHBOARD`
   - Versión: `2.1.0 (2025-01-27)`
   - `supabase-client.js?v=3.1.1` (no `v=3.1.0`)
5. **Escribe en la consola**: `window.DASHBOARD_VERSION`
   - Debería mostrar: `"2.1.0"`

---

## 🆘 Si No Tienes Acceso a Git

Si no puedes usar Git/GitHub, puedes copiar el archivo directamente al servidor:

### Opción Alternativa: Copiar Archivo Directamente al Servidor

**Conéctate al servidor por SSH:**

```bash
# 1. Conectarse al servidor
ssh root@72.61.58.240

# 2. Encontrar el contenedor del dashboard
docker ps | grep dashboard

# 3. Ver dónde está el archivo dashboard.html
docker exec <CONTAINER_ID> ls -la /app/
# O
docker exec <CONTAINER_ID> ls -la /usr/share/nginx/html/

# 4. Desde tu computadora (PowerShell), copiar el archivo
scp C:\Users\German\Downloads\Checkin24hs\dashboard.html root@72.61.58.240:/tmp/dashboard.html

# 5. En el servidor, copiar al contenedor
docker cp /tmp/dashboard.html <CONTAINER_ID>:/app/dashboard.html
# O
docker cp /tmp/dashboard.html <CONTAINER_ID>:/usr/share/nginx/html/dashboard.html

# 6. Reiniciar el contenedor
docker restart <CONTAINER_ID>
```

**⚠️ NOTA:** Esta opción es temporal. Si EasyPanel hace un nuevo deploy, se perderán los cambios. Es mejor usar Git + EasyPanel.

---

## 🔄 Verificación Rápida en el Navegador

Después de subir los cambios, abre la consola del navegador (F12) y ejecuta:

```javascript
// 1. Verificar versión
console.log('Versión:', window.DASHBOARD_VERSION);

// 2. Verificar supabase-client.js
console.log('Scripts cargados:', 
    Array.from(document.querySelectorAll('script[src*="supabase"]'))
        .map(s => s.src)
);

// 3. Verificar logs de versión
// Deberías ver mensajes como:
// "📊 CHECKIN24HS DASHBOARD"
// "Versión: 2.1.0 (2025-01-27)"
```

---

## 📋 Checklist

- [ ] Cambios guardados en `dashboard.html` localmente
- [ ] Cambios subidos a GitHub (`git push`)
- [ ] Deploy hecho en EasyPanel
- [ ] Esperado 2-5 minutos después del deploy
- [ ] Caché del navegador limpiada (Ctrl+Shift+R)
- [ ] Versión visible en consola: `window.DASHBOARD_VERSION = "2.1.0"`
- [ ] `supabase-client.js?v=3.1.1` en lugar de `v=3.1.0`
