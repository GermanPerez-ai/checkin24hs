# 🔢 Cómo Actualizar el Build Number del Dashboard

## 📋 Problema

El build number en `dashboard.html` **NO se actualiza automáticamente**. Necesitas ejecutarlo manualmente antes de hacer commit.

---

## ✅ Solución: Script Automático

### Opción 1: Script Completo (RECOMENDADO)

Ejecuta el script que actualiza el build number, hace commit y push:

```powershell
# En PowerShell, desde la carpeta del proyecto
cd c:\Users\German\Downloads\Checkin24hs
.\ACTUALIZAR_DASHBOARD_AUTOMATICO.ps1
```

Este script:
- ✅ Incrementa automáticamente el build number (64 → 65 → 66...)
- ✅ Actualiza el timestamp
- ✅ Hace commit con mensaje descriptivo
- ✅ Opcionalmente hace push a GitHub

### Opción 2: Solo Actualizar Build Number

Si solo quieres actualizar el build number sin hacer commit:

```powershell
.\actualizar_build_dashboard.ps1
```

Luego manualmente:
```powershell
git add dashboard.html
git commit -m "Build #65: Actualizar dashboard"
git push origin main
```

---

## 🔄 Proceso Recomendado

### Antes de cada commit del dashboard:

1. **Ejecutar script automático:**
   ```powershell
   .\ACTUALIZAR_DASHBOARD_AUTOMATICO.ps1
   ```

2. **O manualmente:**
   ```powershell
   # 1. Actualizar build number
   .\actualizar_build_dashboard.ps1
   
   # 2. Agregar otros cambios si los hay
   git add dashboard.html
   git add otros_archivos.js
   
   # 3. Commit
   git commit -m "feat: Descripción de los cambios (Build #65)"
   
   # 4. Push
   git push origin main
   ```

---

## 📊 Verificar Build Number Actual

### En el código:
```javascript
// En dashboard.html, línea ~12
window.DASHBOARD_BUILD_NUMBER = 65; // Este es el número actual
```

### En la consola del navegador:
```javascript
// Abre la consola (F12) y escribe:
window.DASHBOARD_BUILD_NUMBER
// Debe mostrar el número actual
```

### En la UI:
- El build number se muestra en el sidebar del dashboard
- Busca "Build #65" (o el número actual)

---

## 🎯 Hacerlo Automático (Opcional)

### Opción A: Git Hook (Pre-commit)

Si quieres que se actualice automáticamente antes de cada commit:

1. **El hook ya está creado en:** `.git/hooks/pre-commit`
2. **Pero puede no funcionar bien en Windows**

### Opción B: Recordatorio Manual

Cada vez que vayas a hacer commit del dashboard, recuerda:
1. Ejecutar `.\actualizar_build_dashboard.ps1` primero
2. Luego hacer commit

---

## 📝 Notas Importantes

- ⚠️ **El build number NO se actualiza automáticamente** - debes ejecutarlo manualmente
- 🔢 El build number actual es: **65** (actualizado el 2026-01-23)
- 📅 El timestamp se actualiza automáticamente cuando ejecutas el script
- 🔄 Cada vez que hagas cambios importantes, incrementa el build number

---

## 🆘 Si olvidaste actualizar el build number

Si ya hiciste commit sin actualizar el build number:

1. **Ejecutar el script:**
   ```powershell
   .\actualizar_build_dashboard.ps1
   ```

2. **Hacer un nuevo commit:**
   ```powershell
   git add dashboard.html
   git commit -m "Build #66: Actualizar build number"
   git push origin main
   ```

---

**Última actualización:** 2026-01-23
