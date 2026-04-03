# Cómo dejar el dashboard no público y no encontrable en la web

## 1. No aparecer en buscadores (ya aplicado)

En `dashboard.html` y `deploy/dashboard.html` se agregó en el `<head>`:

```html
<meta name="robots" content="noindex, nofollow">
<meta name="googlebot" content="noindex, nofollow">
```

Con eso Google y otros buscadores **no indexan** la página: no saldrá en resultados de búsqueda. La URL sigue siendo accesible si alguien la conoce.

---

## 2. Restringir acceso (solo quien vos definas)

La pantalla de login del dashboard ya pide usuario/contraseña, pero **cualquiera puede abrir** `https://dashboard.checkin24hs.com` y ver esa pantalla. Para que ni siquiera se vea sin una capa extra de control:

### Opción A: Restricción por IP (recomendada)

Solo permitir acceso desde IPs que vos indiques (ej. oficina, tu casa). Quien no esté en esa IP verá 403 o no podrá cargar el sitio.

**Con Traefik (EasyPanel suele usar Traefik):** crear un middleware de “IP whitelist” y aplicarlo al servicio/ruta del dashboard.

Ejemplo de labels en el **servicio del dashboard** en Docker/EasyPanel:

```yaml
# Ejemplo: solo permitir tu IP (reemplazá por tu IP real)
- "traefik.http.routers.dashboard.middlewares=dashboard-ipwhitelist"
- "traefik.http.middlewares.dashboard-ipwhitelist.ipallowlist.sourcerange=TU_IP/32"
```

Para varias IPs (oficina + casa):

```yaml
- "traefik.http.middlewares.dashboard-ipwhitelist.ipallowlist.sourcerange=IP1/32,IP2/32"
```

Cómo aplicar esto en EasyPanel depende de tu versión: en el servicio del dashboard suele haber una sección de “Labels” o “Traefik” donde se agregan estas etiquetas. Si el dashboard está en un stack/compose, las labels van en ese servicio.

### Opción B: Autenticación básica (usuario/contraseña antes del dashboard)

Una capa extra: al entrar a `https://dashboard.checkin24hs.com` el navegador pide usuario y contraseña (HTTP Basic Auth). Solo después se ve la pantalla de login del dashboard.

En Traefik se hace con un middleware `basicAuth`. Necesitás generar un hash de la contraseña (por ejemplo con `htpasswd`) y configurar el middleware en las labels del servicio del dashboard. En EasyPanel, si hay opción “Basic Auth” o “Protección por contraseña” para el dominio/ruta del dashboard, usala con un usuario/contraseña fuertes.

### Opción C: VPN o acceso solo desde red interna

Poner el dashboard detrás de una VPN o que solo sea accesible desde una red interna (por ejemplo, que Traefik escuche solo en una IP interna o que el dashboard no tenga regla pública y entres por túnel/SSH). Es la opción más restrictiva y requiere más configuración de red.

---

## Resumen

| Objetivo                         | Qué hacer                                                                 |
|----------------------------------|---------------------------------------------------------------------------|
| No aparecer en Google/buscadores | Ya está: `<meta name="robots" content="noindex, nofollow">` en el HTML.   |
| Que solo ciertas IPs entren      | Opción A: middleware IP whitelist en Traefik (labels del servicio).       |
| Capa extra usuario/contraseña    | Opción B: Basic Auth en Traefik o en EasyPanel si lo ofrece.              |

Después de cambiar labels o Basic Auth, reiniciá el servicio del dashboard (o el stack) para que Traefik aplique los cambios.
