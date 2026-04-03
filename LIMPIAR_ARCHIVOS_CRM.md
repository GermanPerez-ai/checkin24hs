# 🧹 Limpiar Archivos de CRM del Repositorio

## 📋 Archivos de CRM que Quedan en el Repositorio

Estos archivos están en GitHub pero ya no se usan:

- `deploy/crm.html`
- `deploy/crm.js`
- `deploy-crm/Dockerfile`
- `deploy-crm/nginx.conf`
- `crear-zip-crm.ps1`
- `crm-deploy.zip` (si está en el repo)

## ⚠️ ¿Afectan al WhatsApp Server?

**NO**, estos archivos **NO afectan** al despliegue de `whatsapp-server` porque:
- EasyPanel está configurado para usar la ruta `/whatsapp-server`
- Solo descarga esa carpeta específica
- Los archivos de CRM están en otras carpetas (`deploy/`, `deploy-crm/`)

## 🧹 Si Quieres Limpiarlos (Opcional)

### Opción 1: Eliminar Solo los Archivos de CRM

```bash
# Eliminar archivos de CRM
git rm deploy/crm.html
git rm deploy/crm.js
git rm -r deploy-crm/
git rm crear-zip-crm.ps1

# Si crm-deploy.zip está en el repo
git rm crm-deploy.zip

# Hacer commit
git commit -m "Eliminar archivos de CRM obsoletos"

# Subir cambios
git push
```

### Opción 2: Dejarlos (No Afectan)

Puedes dejarlos en el repositorio. No causan problemas porque:
- No se usan en el despliegue de WhatsApp
- EasyPanel solo descarga `/whatsapp-server`
- No interfieren con nada

## 🎯 Recomendación

**Por ahora, déjalos**. El problema del servicio en amarillo/rojo **NO es por los archivos de CRM**.

El problema real es que el servicio no está iniciando. Necesitamos:
1. Ver los logs del servicio después de implementar
2. Verificar que el servicio se inicie automáticamente
3. Revisar si hay errores al ejecutar `node whatsapp-server.js`

## 🔍 Próximo Paso Real

En lugar de limpiar archivos, necesitamos:

1. **Implementar el servicio** (botón verde "Implementar")
2. **Ver los logs** de la implementación
3. **Ver los logs del servicio** (no de la implementación)
4. **Identificar el error** específico

¿Qué ves en los logs cuando implementas? Eso es lo que necesitamos para solucionar el problema.

