# 🔧 Comandos para Limpiar y Hacer Push

## 📋 Ejecuta estos comandos en el servidor:

```bash
cd ~/checkin24hs

# 1. Actualizar .gitignore para ignorar archivos de sesión
cat >> .gitignore << 'EOF'

# WhatsApp session files (no deben estar en el repositorio)
.wwebjs_auth/
.wwebjs_auth_*/
.wwebjs_auth_instance_*/
whatsapp-server/.wwebjs_auth/
whatsapp-server/.wwebjs_auth_*/
whatsapp-server/.wwebjs_auth_instance_*/

# WhatsApp backups y logs
whatsapp-server/*.backup*
whatsapp-server/logs/
whatsapp-server/stats.json
whatsapp-server/package-lock.json

# Dashboard backups
dashboard.html.backup*
*.backup*

# Scripts temporales (mantener solo los importantes)
*.sh
!ACTUALIZAR_ARCHIVO_SERVIDOR.sh
!REAPLICAR_TRAEFIK_LABELS.sh
EOF

# 2. Remover archivos de sesión del tracking de Git
git rm -r --cached whatsapp-server/.wwebjs_auth_instance_* 2>/dev/null || true
git rm -r --cached whatsapp-server/.wwebjs_auth_* 2>/dev/null || true
git rm --cached whatsapp-server/*.backup* 2>/dev/null || true
git rm --cached dashboard.html.backup* 2>/dev/null || true

# 3. Agregar .gitignore actualizado
git add .gitignore

# 4. Hacer commit de la limpieza
git commit -m "fix: Agregar archivos de sesión WhatsApp al .gitignore y remover del tracking"

# 5. Hacer pull para traer cambios remotos
git pull origin main

# 6. Si hay conflictos, resolverlos y luego:
# git add .
# git commit

# 7. Hacer push
git push origin main
```

## ⚠️ Si hay conflictos durante el pull:

```bash
# Ver qué archivos tienen conflictos
git status

# Si dashboard.html tiene conflictos:
# - Abre el archivo
# - Busca las marcas <<<<<<< ======= >>>>>>>
# - Resuelve manualmente o acepta una versión

# Después de resolver:
git add .
git commit -m "Merge: Resolver conflictos con cambios remotos"
git push origin main
```

## 🎯 Resumen Rápido:

```bash
cd ~/checkin24hs
# Actualizar .gitignore (comando de arriba)
# Remover archivos de sesión (comando de arriba)
git add .gitignore
git commit -m "fix: Limpiar archivos de sesión"
git pull origin main
git push origin main
```
