# 🔄 Sincronizar Servidor con Local

## Estado Actual
- ✅ **Local:** Build #39
- ✅ **Servidor:** Build #39

Ambos están sincronizados.

## Para Mantener Sincronizados

### Opción 1: Servidor → Local (Descargar desde servidor)

Si haces cambios en el servidor y quieres traerlos localmente:

```bash
# En el servidor SSH
cat /root/checkin24hs/dashboard.html > dashboard_servidor.html

# Luego descarga ese archivo localmente
# O copia el contenido y pega en dashboard.html local
```

### Opción 2: Local → Servidor (Actual, recomendado)

**Flujo normal:**
1. Editas `dashboard.html` localmente
2. Commit y push a GitHub
3. En servidor: `curl` desde GitHub a `/root/checkin24hs/dashboard.html`

**Script para automatizar:**

```bash
# En servidor, crear: /usr/local/bin/actualizar-dashboard.sh
#!/bin/bash
echo "🔄 Actualizando dashboard desde GitHub..."
curl -L -o /root/checkin24hs/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
docker service update --force checkin24hs_dashboard
echo "✅ Dashboard actualizado"
```

### Opción 3: Verificar Diferencias

Para ver si hay diferencias entre local y servidor:

```bash
# En servidor SSH
grep -n "DASHBOARD_BUILD_NUMBER" /root/checkin24hs/dashboard.html

# Comparar con local
grep -n "DASHBOARD_BUILD_NUMBER" dashboard.html
```

## ⚠️ Importante

- **Local** = `c:\Users\German\Downloads\Checkin24hs\dashboard.html`
- **Servidor** = `/root/checkin24hs/dashboard.html` (montado en contenedor)
- **NO usar** = `/etc/easypanel/projects/checkin24hs/dashboard/code/dashboard.html` (no está montado)

## 📋 Flujo Recomendado

1. **Hacer cambios localmente** en `dashboard.html`
2. **Commit y push** a GitHub (el hook incrementará el build automáticamente)
3. **En servidor:** Ejecutar script de actualización

¿Quieres que cree el script de actualización automática en el servidor?
