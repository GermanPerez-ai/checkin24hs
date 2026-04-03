# 📋 Sistema de Versionado del Dashboard

## ✅ Implementación Completada

Se ha implementado un sistema completo de versionado que:

1. ✅ **Incrementa automáticamente el build number** con cada deploy
2. ✅ **Muestra la versión en el sidebar** debajo de "Checkin24hs Admin"
3. ✅ **Incluye timestamp** de cada build
4. ✅ **Se actualiza automáticamente** cuando se carga la página

## 🔧 Cómo Funciona

### Variables de Versión

El dashboard ahora incluye tres variables de versión:

```javascript
window.DASHBOARD_VERSION = '2.1.0';           // Versión principal
window.DASHBOARD_VERSION_DATE = '2025-01-27'; // Fecha de la versión
window.DASHBOARD_BUILD = '2026-01-14T12:47:02Z'; // Timestamp del build
window.DASHBOARD_BUILD_NUMBER = 4;            // Número de build (se incrementa)
```

### Display en la UI

La versión se muestra en el sidebar, debajo de "Checkin24hs Admin":

```
Checkin24hs Admin
v2.1.0
Build #4
```

## 🚀 Cómo Usar

### Para Actualizar Versión y Subir a GitHub:

**En PowerShell (Windows):**
```powershell
.\ACTUALIZAR_VERSION_Y_SUBIR.ps1
```

Este script:
1. Incrementa automáticamente el build number
2. Actualiza el timestamp
3. Hace commit con el mensaje apropiado
4. Sube los cambios a GitHub

### Para Solo Incrementar Versión (sin subir):

```powershell
.\INCREMENTAR_VERSION.ps1
```

### Para Verificar Versión en el Servidor:

**En el servidor (SSH):**
```bash
cd ~/checkin24hs
bash VERIFICAR_VERSION_SERVIDOR_COMPLETA.sh
```

## 📋 Flujo de Trabajo Recomendado

1. **Hacer correcciones** en `deploy/dashboard.html`
2. **Incrementar versión y subir:**
   ```powershell
   .\ACTUALIZAR_VERSION_Y_SUBIR.ps1
   ```
3. **En EasyPanel:**
   - Ir al servicio `dashboard`
   - Hacer clic en "Deploy" o "Redeploy"
   - Esperar 2-5 minutos
4. **Verificar:**
   - Recargar la página con Ctrl+F5
   - Verificar que la versión se muestre en el sidebar
   - Ejecutar el script de verificación en el servidor

## ✅ Estado Actual

- ✅ Sistema de versionado implementado
- ✅ Display en UI agregado
- ✅ Scripts de automatización creados
- ✅ Build #4 subido a GitHub
- ⏳ Pendiente: Deploy en EasyPanel

## 📝 Notas

- El build number se incrementa automáticamente cada vez que ejecutas `ACTUALIZAR_VERSION_Y_SUBIR.ps1`
- El timestamp se actualiza a la hora UTC actual
- La versión se muestra automáticamente en el sidebar cuando se carga la página
- Puedes verificar la versión en la consola del navegador: `window.DASHBOARD_VERSION` y `window.DASHBOARD_BUILD_NUMBER`
