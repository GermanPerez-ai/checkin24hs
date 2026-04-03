# 🔧 Corregir Ruta /qr en Traefik

## ⚠️ Problema
- ✅ `/api/qr` funciona correctamente
- ❌ `/qr` da error 404

## 🔍 Diagnóstico

Ambas rutas están definidas en el código:
```javascript
app.get(['/api/qr', '/qr'], async (req, res) => {
```

Si `/api/qr` funciona pero `/qr` no, el problema está en la configuración de Traefik.

---

## ✅ Soluciones

### Solución 1: Usar siempre `/api/qr` (Recomendado)

La ruta `/api/qr` ya funciona. Simplemente usa esa ruta en lugar de `/qr`:

```
https://whatsapp.checkin24hs.com/api/qr
```

### Solución 2: Agregar Regla de Traefik para `/qr`

Si necesitas que `/qr` funcione también, puedes agregar una regla adicional en Traefik:

```bash
# Agregar regla adicional para /qr
docker service update \
  --label-add "traefik.http.routers.whatsapp-qr.rule=Host(\`whatsapp.checkin24hs.com\`) && PathPrefix(\`/qr\`)" \
  --label-add "traefik.http.routers.whatsapp-qr.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp-qr.tls=true" \
  --label-add "traefik.http.routers.whatsapp-qr.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.whatsapp-qr.service=whatsapp" \
  checkin24hs_whatsapp
```

Pero esto puede causar conflictos. Es mejor usar `/api/qr`.

### Solución 3: Verificar Configuración Actual de Traefik

Verifica las etiquetas actuales:

```bash
docker service inspect checkin24hs_whatsapp --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik"
```

---

## 💡 Recomendación

**Usa `/api/qr` en lugar de `/qr`**. Es más estándar y ya está funcionando correctamente.

Si realmente necesitas que `/qr` funcione, puedes:
1. Agregar un redirect en el código de `/qr` a `/api/qr`
2. O configurar Traefik con reglas adicionales (más complejo)

---

## 🔧 Agregar Redirect de /qr a /api/qr (Opcional)

Si quieres que `/qr` redirija automáticamente a `/api/qr`, puedo agregar esa funcionalidad al código.
