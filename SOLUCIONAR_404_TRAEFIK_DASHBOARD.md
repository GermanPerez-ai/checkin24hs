# 🔧 Solucionar Error 404 - Traefik y Dashboard

## ⚠️ Importante: Reiniciar Traefik NO Cambia el Código

**Reiniciar Traefik NO afecta la versión del código del dashboard.**

- **Traefik** = Proxy reverso que enruta el tráfico (NO contiene código del dashboard)
- **Dashboard** = Servicio/contenedor con el código (la versión está aquí)

Cuando reinicias Traefik, solo se reinicia el proxy. El código del dashboard queda igual.

---

## 🔍 Problema: Error 404

El error 404 significa que Traefik no puede enrutar el tráfico al servicio del dashboard. Esto suele pasar porque **el servicio del dashboard no tiene las etiquetas de Traefik necesarias**.

---

## ✅ Solución: Agregar Etiquetas de Traefik al Servicio

**Ejecuta estos comandos en el servidor (por SSH):**

```bash
# 1. Verificar el servicio del dashboard
docker service ls | grep dashboard

# 2. Verificar si tiene etiquetas de Traefik
SERVICE="checkin24hs_dashboard"
docker service inspect $SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

# 3. Si NO muestra nada (o muestra "traefik.enable" diferente de "true"), agregar etiquetas:
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  $SERVICE

# 4. Esperar 30-60 segundos
sleep 30

# 5. Verificar que se agregaron
docker service inspect $SERVICE --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

# 6. Probar acceso
curl -I https://dashboard.checkin24hs.com
```

---

## 🔄 Opción Alternativa: Desde EasyPanel

Si prefieres hacerlo desde EasyPanel:

1. Ve a EasyPanel: `http://72.61.58.240:3000`
2. Busca el servicio **"dashboard"**
3. Ve a la pestaña **"Dominios"** (o "Domains")
4. **Elimina** el dominio `dashboard.checkin24hs.com` si existe
5. **Agrega** el dominio de nuevo:
   - Dominio: `dashboard.checkin24hs.com`
   - Puerto destino: `3000`
   - Ruta: `/`
6. **Guarda** los cambios
7. Espera 1-2 minutos

EasyPanel debería agregar automáticamente las etiquetas de Traefik.

---

## ✅ Verificación Final

Después de agregar las etiquetas:

1. **Espera 1-2 minutos** para que Traefik detecte los cambios
2. **Abre**: `https://dashboard.checkin24hs.com`
3. **Presiona `Ctrl + Shift + R`** (limpiar caché)
4. **Debería cargar correctamente**

---

## 📋 Resumen

- ✅ **Reiniciar Traefik** = Solo reinicia el proxy (NO cambia el código)
- ✅ **Versión del código** = Está en el servicio/contenedor del dashboard
- ✅ **Error 404** = Traefik no tiene las etiquetas correctas del servicio
- ✅ **Solución** = Agregar etiquetas de Traefik al servicio dashboard

---

## 🆘 Si Sigue Sin Funcionar

Si después de agregar las etiquetas sigue dando 404:

1. **Verifica que el servicio esté corriendo:**
   ```bash
   docker service ps checkin24hs_dashboard
   ```

2. **Verifica los logs de Traefik:**
   ```bash
   docker service logs traefik --tail 50 | grep -i dashboard
   ```

3. **Verifica que el servicio esté en la red correcta:**
   ```bash
   docker service inspect checkin24hs_dashboard | grep -A 10 Networks
   ```
