# 🔧 Configurar Incremento Automático de Build Number

## ✅ Hook Pre-Commit Configurado

Se ha configurado un **pre-commit hook** que incrementa automáticamente el build number cada vez que haces commit de `dashboard.html`.

## 🚀 Cómo Funciona

1. **Cuando haces `git add dashboard.html`** y luego `git commit`
2. **El hook se ejecuta automáticamente** antes del commit
3. **Incrementa el build number** (39 → 40 → 41...)
4. **Actualiza el timestamp** automáticamente
5. **Re-agrega el archivo** al staging con el nuevo build
6. **El commit continúa** con el build incrementado

## 📋 Comportamiento

- ✅ **Solo incrementa** si `dashboard.html` está en el staging area
- ✅ **No afecta otros commits** que no incluyan `dashboard.html`
- ✅ **Funciona automáticamente** - no necesitas hacer nada
- ✅ **Compatible** con Windows (PowerShell) y Linux/Mac

## 🧪 Probar el Hook

Para probar que funciona:

```powershell
# Hacer un cambio pequeño en dashboard.html (cualquier línea)
# Luego:
git add dashboard.html
git commit -m "Test: verificar incremento automático"
```

Deberías ver el mensaje:
```
🔢 Incrementando build number automáticamente...
Build: 39 -> 40
✅ Build incrementado a #40
```

## ⚠️ Si el Hook No Funciona

Si en Windows el hook bash no funciona bien, hay una versión alternativa en PowerShell:

1. El hook bash (`.git/hooks/pre-commit`) debería funcionar con Git Bash
2. Si prefieres PowerShell puro, consulta `PRE_COMMIT_HOOK_POWERSHELL.ps1`

## 🔍 Verificar Build Actual

En la consola del navegador:
```javascript
window.DASHBOARD_BUILD_NUMBER  // Muestra el build actual
window.DASHBOARD_BUILD         // Muestra el timestamp
```

## 📝 Notas

- El hook **solo se ejecuta en commits locales**
- No afecta al servidor hasta que hagas `git push`
- Cada commit de `dashboard.html` incrementa el build automáticamente
- **Ya no necesitas ejecutar scripts manualmente** 🎉
