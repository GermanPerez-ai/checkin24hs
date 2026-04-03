# Configurar Anti-Caché en Traefik (EasyPanel)

Si estás usando **EasyPanel con Traefik**, necesitas configurar los headers anti-caché en Traefik en lugar de nginx.

## Opción 1: Configurar en EasyPanel (Recomendado)

1. **Accede a EasyPanel**
2. **Ve al servicio "dashboard"**
3. **Busca la sección "Labels" o "Headers"**
4. **Agrega estos labels de Traefik:**

```
traefik.http.middlewares.dashboard-headers.headers.customRequestHeaders.X-Cache-Control=no-cache
traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Cache-Control=no-cache, no-store, must-revalidate
traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Pragma=no-cache
traefik.http.middlewares.dashboard-headers.headers.customResponseHeaders.Expires=0
traefik.http.routers.dashboard.middlewares=dashboard-headers
```

5. **Específicamente para archivos HTML:**

Si EasyPanel permite configurar rutas específicas, agrega:

```
traefik.http.middlewares.html-no-cache.headers.customResponseHeaders.Cache-Control=no-cache, no-store, must-revalidate
traefik.http.routers.dashboard.rule=Host(`dashboard.checkin24hs.com`) && PathPrefix(`/`)
traefik.http.routers.dashboard.middlewares=html-no-cache
```

## Opción 2: Configurar en el Dockerfile o servicio

Si el dashboard usa un servidor web interno (nginx, express, etc.), los cambios en `nginx.conf` y los meta tags en `dashboard.html` ya deberían funcionar.

## Opción 3: Verificar configuración actual

Ejecuta en el servidor SSH:

```bash
# Ver labels actuales del servicio dashboard
docker service inspect checkin24hs_dashboard --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik

# Ver headers que Traefik está enviando
curl -I https://dashboard.checkin24hs.com/
```

## Verificación

Después de aplicar los cambios:

1. **Abre el dashboard en tu teléfono**
2. **Abre las herramientas de desarrollador** (si es posible)
3. **Ve a la pestaña "Network" o "Red"**
4. **Recarga la página**
5. **Verifica los headers de respuesta** de `dashboard.html`:
   - Debe tener: `Cache-Control: no-cache, no-store, must-revalidate`
   - Debe tener: `Pragma: no-cache`
   - Debe tener: `Expires: 0`

## Solución Manual Temporal

Si necesitas una solución inmediata mientras configuras Traefik:

**En tu teléfono:**
1. Abre el dashboard: `https://dashboard.checkin24hs.com/#`
2. Agrega `?v=` seguido de un número aleatorio: `https://dashboard.checkin24hs.com/#?v=12345`
3. Esto fuerza al navegador a ignorar el caché para esa URL específica

**O limpia el caché manualmente:**
- **Chrome/Android**: Configuración → Privacidad → Borrar datos de navegación → Caché
- **Safari/iOS**: Configuración → Safari → Borrar historial y datos del sitio web






