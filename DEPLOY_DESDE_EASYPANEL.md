# 🚀 Deploy desde EasyPanel - Paso a Paso

## ✅ Opción Recomendada: Deploy desde EasyPanel

### Paso 1: Subir el código a GitHub

Ejecuta estos comandos en PowerShell:

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Verificar cambios
git status

# Agregar archivo corregido
git add deploy/dashboard.html

# Commit
git commit -m "Fix: Agregar funciones globales en head - window.showSection, window.searchUsers, window.handleLogin"

# Push
git push
```

### Paso 2: Hacer Deploy desde EasyPanel

1. **Abre EasyPanel** en tu navegador
2. **Ve al proyecto** `checkin24hs`
3. **Abre el servicio** `dashboard`
4. **Haz clic en el botón "Deploy"** (verde) o **"Desplegar"**
5. **Espera** a que termine el build (2-5 minutos)
6. **Verifica** que el deploy fue exitoso

### Paso 3: Verificar

1. Abre el dashboard en modo incógnito (Ctrl+Shift+N)
2. Presiona Ctrl+Shift+R para hard refresh
3. Verifica que no haya errores en la consola

---

## ⚡ Opción Rápida: Aplicar Directamente a Contenedores

Si necesitas una solución inmediata sin esperar el deploy:

```powershell
.\APLICAR_MULETO_LIMPIO.ps1
```

**⚠️ IMPORTANTE:** Esta opción es temporal. Si EasyPanel hace un deploy después, podría sobrescribir los cambios.

---

## 🔍 ¿Cuál usar?

- **Usa EasyPanel** si está configurado para GitHub (recomendado)
- **Usa script directo** si necesitas una solución inmediata o EasyPanel no está configurado correctamente

