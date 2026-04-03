# ✅ Incremento Automático de Build Number - CONFIGURADO

## 🎉 ¡Ya está funcionando!

El contador de versión/build ahora se incrementa **AUTOMÁTICAMENTE** cada vez que haces commit de `dashboard.html`.

## 🔧 Cómo Funciona

Cuando haces:
```powershell
git add dashboard.html
git commit -m "Mis cambios"
```

**El hook automáticamente:**
1. ✅ Detecta que `dashboard.html` está en el commit
2. ✅ Incrementa el build number (39 → 40 → 41...)
3. ✅ Actualiza el timestamp
4. ✅ Re-agrega el archivo con el nuevo build
5. ✅ Continúa con el commit normalmente

**No necesitas hacer nada más** - es completamente automático.

## 📊 Ejemplo de Uso

**Antes:**
```javascript
window.DASHBOARD_BUILD_NUMBER = 39;
```

**Haces commit:**
```powershell
git add dashboard.html
git commit -m "Nueva funcionalidad"
```

**Después del commit (automático):**
```javascript
window.DASHBOARD_BUILD_NUMBER = 40;  // ← Incrementado automáticamente
```

## 🔍 Ver Mensajes del Hook

Cuando hagas commit, verás:
```
🔢 Incrementando build number automáticamente...
Build: 39 -> 40
✅ Build incrementado a #40
[main abc123] Nueva funcionalidad
 1 file changed, 2 insertions(+), 1 deletion(-)
```

## ⚙️ Configuración

El hook está en: `.git/hooks/pre-commit`

- ✅ Ya configurado y activo
- ✅ Solo afecta commits que incluyan `dashboard.html`
- ✅ No afecta otros archivos

## 🧪 Probar Ahora

Para verificar que funciona:

```powershell
# Hacer un cambio pequeño (agregar un espacio, comentario, etc.)
# Luego:
git add dashboard.html
git commit -m "Test: verificar incremento automático"
```

Deberías ver el incremento automático en los mensajes.

## ❓ Preguntas Frecuentes

### ¿Necesito ejecutar algo manualmente?
**No.** El hook se ejecuta automáticamente.

### ¿Funciona con `git commit --no-verify`?
Si usas `--no-verify`, el hook **no se ejecuta**. Usa el flag solo cuando realmente necesites saltarlo.

### ¿Se incrementa solo en commits de dashboard.html?
**Sí.** Solo se activa cuando `dashboard.html` está en el staging area.

### ¿Funciona en todos los sistemas?
**Sí.** Funciona en Windows (Git Bash), Linux y Mac.

## 🎯 Resultado

**Antes:** Tenías que recordar incrementar manualmente el build number  
**Ahora:** Se incrementa automáticamente en cada commit ✅

¡Ya está todo listo! Solo haz commits normalmente y el build se incrementará solo.
