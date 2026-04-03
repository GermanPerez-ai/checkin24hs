# 🚀 Actualizar Dashboard Admin desde el Servidor

## 🎯 Opción: Actualizar desde el Servidor (Sin EasyPanel)

Si prefieres actualizar el dashboard directamente desde el servidor sin usar EasyPanel:

### Paso 1: Conectarse al Servidor

```bash
ssh root@72.61.58.240
```

### Paso 2: Ejecutar el Script

```bash
cd /root/checkin24hs
chmod +x ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh
./ACTUALIZAR_DASHBOARD_ADMIN_DESDE_GITHUB.sh
```

El script:
1. ✅ Descarga el código actualizado de GitHub
2. ✅ Encuentra el contenedor del dashboard
3. ✅ Copia `checkin24hs-admin/server.js` actualizado
4. ✅ Verifica que tiene la ruta `/og-cotizar.jpg`
5. ✅ Reinicia el servicio para aplicar cambios

### Paso 3: Verificar

Después de 1-2 minutos:
```bash
# Verificar que el servicio está corriendo
docker service ps checkin24hs-dashboard

# Probar la ruta
curl -I https://dashboard.checkin24hs.com/og-cotizar.jpg
```

---

## 🔄 Opción Alternativa: Deploy desde EasyPanel

Si prefieres usar EasyPanel (como está configurado normalmente):

1. **Ve a EasyPanel**: `http://72.61.58.240:3000`
2. **Abre el servicio**: `checkin24hs-dashboard` (o `dashboard`)
3. **Haz clic en "Implementar"** o **"Redeploy"**
4. **Espera 2-5 minutos**

EasyPanel descargará automáticamente desde GitHub y reconstruirá el servicio.

---

## 📋 ¿Cuál Usar?

- **Script desde servidor**: Más rápido, no reconstruye la imagen Docker
- **EasyPanel**: Más completo, reconstruye todo desde cero (recomendado para cambios importantes)

Para este cambio (solo `server.js`), **ambos métodos funcionan**. El script desde servidor es más rápido.
