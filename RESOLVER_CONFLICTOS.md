# 🔧 Resolver Conflictos de Merge

## 📋 Ejecuta estos comandos en el servidor:

```bash
cd ~/checkin24hs

# 1. Aceptar nuestra versión local para todos los archivos en conflicto
git checkout --ours ACTUALIZAR_ARCHIVO_SERVIDOR.sh
git checkout --ours PROCESO_DEPLOY_COMPLETO.sh
git checkout --ours REAPLICAR_TRAEFIK_LABELS.sh
git checkout --ours VERIFICAR_POST_DEPLOY_COMPLETO.sh

# 2. Agregar los archivos resueltos al staging
git add ACTUALIZAR_ARCHIVO_SERVIDOR.sh
git add PROCESO_DEPLOY_COMPLETO.sh
git add REAPLICAR_TRAEFIK_LABELS.sh
git add VERIFICAR_POST_DEPLOY_COMPLETO.sh

# 3. Agregar también los archivos importantes
git add .gitignore dashboard.html

# 4. Hacer commit de la resolución de conflictos
git commit -m "fix: Resolver conflictos de merge y limpiar archivos de sesión WhatsApp

- Mantener versión local de ACTUALIZAR_ARCHIVO_SERVIDOR.sh
- Remover archivos de sesión del tracking de Git
- Actualizar .gitignore para prevenir futuros commits de sesiones
- Actualizar dashboard.html con Build #38"

# 5. Hacer push
git push origin main
```

## ⚡ Comandos Rápidos (Todo en uno):

```bash
cd ~/checkin24hs && \
git checkout --ours ACTUALIZAR_ARCHIVO_SERVIDOR.sh && \
git checkout --ours PROCESO_DEPLOY_COMPLETO.sh && \
git checkout --ours REAPLICAR_TRAEFIK_LABELS.sh && \
git checkout --ours VERIFICAR_POST_DEPLOY_COMPLETO.sh && \
git add ACTUALIZAR_ARCHIVO_SERVIDOR.sh PROCESO_DEPLOY_COMPLETO.sh REAPLICAR_TRAEFIK_LABELS.sh VERIFICAR_POST_DEPLOY_COMPLETO.sh .gitignore dashboard.html && \
git commit -m "fix: Resolver conflictos de merge y limpiar archivos de sesión WhatsApp" && \
git push origin main
```
