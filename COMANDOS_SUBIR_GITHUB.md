# 📤 Comandos para Subir Cambios a GitHub

## ✅ Intercambio Completado

El archivo `muleto.html` ha sido copiado como `dashboard.html` y los archivos de configuración han sido copiados.

## 📋 Pasos para Subir a GitHub

### 1. Verificar los cambios

```bash
git status
```

Deberías ver:
- `dashboard.html` (modificado)
- `supabase-config.js` (nuevo o modificado)
- `supabase-client.js` (nuevo o modificado)
- `logo.png` (nuevo o modificado)
- `deploy/dashboard.html` (modificado, si existe)

### 2. Agregar los archivos

```bash
git add dashboard.html
git add supabase-config.js
git add supabase-client.js
git add logo.png
```

Si existe `deploy/dashboard.html`:
```bash
git add deploy/dashboard.html
```

O agregar todos los cambios de una vez:
```bash
git add .
```

### 3. Confirmar los cambios

```bash
git commit -m "Reemplazar dashboard.html con muleto.html funcional"
```

### 4. Subir a GitHub

```bash
git push
```

## 🔍 Verificar que se Subió Correctamente

1. Ve a tu repositorio en GitHub: `https://github.com/GermanPerez-ai/checkin24hs`
2. Verifica que `dashboard.html` esté actualizado
3. Verifica que los archivos de configuración estén presentes

## 📝 Próximo Paso

Después de subir a GitHub, configura EasyPanel siguiendo la guía:
- `GUIA_CONFIGURAR_EASYPANEL_DASHBOARD_HTML.md`

