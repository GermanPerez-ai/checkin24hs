# 📝 Comandos Git para el Servidor

## ✅ Comandos Correctos (Ejecutar en el Servidor)

```bash
cd ~/checkin24hs

# Solo agregar los archivos que necesitamos
git add dashboard.html ACTUALIZAR_ARCHIVO_SERVIDOR.sh

# Verificar qué se va a commitear
git status

# Hacer commit
git commit -m "feat: Actualizar configuración WhatsApp y script de actualización

- Incrementar build number a #38
- Corregir script ACTUALIZAR_ARCHIVO_SERVIDOR.sh para bind mount
- Optimizar detección de subdominios en URLs de WhatsApp
- Agregar herramientas de verificación"

# Subir a GitHub
git push origin main
```

## ⚠️ Nota sobre Archivos Sin Trackear

Hay muchos archivos sin trackear (scripts temporales, backups, etc.). No es necesario agregarlos ahora. Solo necesitamos:
- ✅ `dashboard.html` (actualizado con Build #38)
- ✅ `ACTUALIZAR_ARCHIVO_SERVIDOR.sh` (script corregido)

## 🔐 Si Pide Credenciales

Si Git pide usuario/contraseña:
- **Username**: `GermanPerez-ai`
- **Password**: Usa un Personal Access Token (no tu contraseña de GitHub)

O configura SSH:
```bash
# Verificar si tienes SSH configurado
ssh -T git@github.com

# Si no funciona, puedes usar HTTPS con token
```
