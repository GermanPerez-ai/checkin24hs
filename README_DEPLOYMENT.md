# 📦 Guía Rápida de Deployment

## ⚡ Actualización Rápida del Dashboard

### Paso 1: Hacer Cambios
Edita `dashboard.html` localmente

### Paso 2: Commit (Build se incrementa automáticamente)
```powershell
git add dashboard.html
git commit -m "Tus cambios"
git push origin main
```

### Paso 3: Actualizar Servidor
```bash
# En servidor SSH
curl -L -o /root/checkin24hs/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
docker service update --force checkin24hs_dashboard
```

## 📁 Archivos Importantes

- **Script de actualización:** `scripts/deploy/actualizar-dashboard.sh`
- **Documentación completa:** `docs/deployment/DEPLOY_DASHBOARD.md`

## 🔄 Flujo Visual

```
Local → GitHub → Servidor
  ↓        ↓        ↓
dashboard.html → Build Auto → /root/checkin24hs/dashboard.html
```

## ⚠️ Recordatorio

El archivo que se actualiza en el servidor es:
```bash
/root/checkin24hs/dashboard.html
```
