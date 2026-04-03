# 🔧 Verificar y Corregir Traefik para Rutas /api/*

## 🔍 Problema

El endpoint `/api/supabase/test` devuelve 404 cuando se accede a través del navegador (Traefik), pero funciona directamente en el contenedor. Esto significa que **Traefik no está pasando las rutas `/api/*` al servicio**.

---

## ✅ Solución: Verificar y Corregir Etiquetas de Traefik

### Paso 1: Verificar las etiquetas actuales de Traefik

```bash
# Ver las etiquetas de Traefik del servicio
docker service inspect checkin24hs_dashboard \
  --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik
```

### Paso 2: Verificar la regla de routing

```bash
# Ver la regla de routing actual
docker service inspect checkin24hs_dashboard \
  --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{if eq $key "traefik.http.routers.dashboard-checkin24hs.rule"}}{{$value}}{{end}}{{end}}'
```

### Paso 3: Asegurarse de que Traefik pasa todas las rutas

Si la regla es solo `Host(...)`, debería pasar todas las rutas. El problema puede ser:

1. **Falta el puerto del servicio**
2. **Hay un middleware que está limitando las rutas**
3. **Traefik necesita reiniciarse**

**Comando para verificar el puerto:**
```bash
docker service inspect checkin24hs_dashboard \
  --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{if eq $key "traefik.http.services.*.loadbalancer.server.port"}}{{$key}}={{$value}}{{end}}{{end}}'
```

---

## 🔧 Corrección (Si es necesario)

### Opción 1: Desde EasyPanel (Recomendado)

1. Ve a EasyPanel
2. Edita el servicio `checkin24hs_dashboard`
3. Ve a la pestaña **"Dominios"**
4. Verifica/Configura el dominio:
   - Dominio: `dashboard.checkin24hs.com` (o el que uses)
   - Puerto destino: `3000`
   - **Ruta:** Debe estar en `/` o vacía (para pasar todas las rutas)
5. Guarda y espera 1-2 minutos

### Opción 2: Desde línea de comandos

Si necesitas agregar/actualizar las etiquetas manualmente:

```bash
# Agregar/Actualizar etiquetas de Traefik
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard-checkin24hs.tls=true" \
  --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=3000" \
  checkin24hs_dashboard

# Esperar para que Traefik detecte los cambios
sleep 30
```

**⚠️ IMPORTANTE:** Reemplaza `dashboard.checkin24hs.com` con tu dominio real si es diferente.

---

## ✅ Verificación Final

### 1. Verificar que las etiquetas se agregaron

```bash
docker service inspect checkin24hs_dashboard \
  --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep traefik
```

### 2. Probar el endpoint desde el navegador

Abre en tu navegador:
```
https://tu-dominio.com/api/supabase/test
```

Deberías recibir JSON:
```json
{
  "success": true,
  "configured": true,
  "connected": true,
  "message": "Conexión exitosa con Supabase"
}
```

### 3. Ver logs de Traefik si persiste el 404

```bash
# Ver logs de Traefik relacionados con el dashboard
docker service logs traefik --tail 100 | grep -iE "dashboard|api|404" | tail -20
```

---

## 🆘 Si el problema persiste

Si después de configurar las etiquetas sigue dando 404:

1. **Verifica el dominio correcto:**
   ```bash
   # Ver qué dominio está configurado
   docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{if eq $key "traefik.http.routers.*.rule"}}{{$value}}{{end}}{{end}}'
   ```

2. **Revisa los logs de Traefik:**
   ```bash
   docker service logs traefik --tail 50
   ```

3. **Verifica que el servicio esté corriendo:**
   ```bash
   docker service ps checkin24hs_dashboard
   ```

4. **Prueba accediendo directamente al contenedor (bypass Traefik):**
   ```bash
   # Esto debería funcionar siempre
   docker exec $(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1) node -e "const http=require('http');http.get('http://localhost:3000/api/supabase/test',(r)=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>console.log(d))})"
   ```

---

**Ejecuta primero el Paso 1 para ver qué etiquetas tiene actualmente el servicio.**
