# Fragmento docker-compose para Hostinger / EasyPanel (labels Traefik)

Para que Hostinger te indique **dónde colocar los labels** en EasyPanel y que se mantengan en cada redeploy, podés enviarles este fragmento.

---

## 1. Servicio Dashboard (labels Traefik)

```yaml
services:
  dashboard:
    build:
      context: .
      dockerfile: deploy/dashboard-html/Dockerfile
    image: easypanel/checkin24hs/dashboard:latest
    networks:
      - easypanel
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=easypanel"
      - "traefik.http.routers.dashboard.rule=Host(`dashboard.checkin24hs.com`)"
      - "traefik.http.routers.dashboard.entrypoints=websecure"
      - "traefik.http.routers.dashboard.service=dashboard"
      - "traefik.http.routers.dashboard.tls=true"
      - "traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
      - "traefik.http.services.dashboard.loadbalancer.server.port=3000"
```

---

## 2. Servicio WhatsApp (labels Traefik)

```yaml
  whatsapp:
    build:
      context: ./whatsapp-server
      dockerfile: Dockerfile
    image: easypanel/checkin24hs/whatsapp:latest
    networks:
      - easypanel
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=easypanel"
      - "traefik.http.routers.whatsapp.rule=Host(`whatsapp.checkin24hs.com`)"
      - "traefik.http.routers.whatsapp.entrypoints=websecure"
      - "traefik.http.routers.whatsapp.service=whatsapp"
      - "traefik.http.routers.whatsapp.tls=true"
      - "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt"
      - "traefik.http.services.whatsapp.loadbalancer.server.port=3001"
```

---

## 3. Red (al final del compose)

```yaml
networks:
  easypanel:
    external: true
```

---

## Mensaje sugerido para Hostinger

Podés copiar y pegar algo así:

> Hola, estoy usando EasyPanel y necesito que los labels de Traefik se mantengan en cada redeploy. No encuentro en la interfaz la sección de etiquetas / labels / Traefik / dominios.
>
> Adjunto el fragmento de mi docker-compose con los labels que uso para el dashboard (y WhatsApp). ¿Me podrían indicar exactamente dónde configurar estos labels en EasyPanel para que se usen en cada redeploy sin tener que tocarlos a mano?
>
> [pegar aquí el bloque de "labels" del Dashboard o el compose completo]

El archivo completo está en el repo: **`docker-compose.easypanel.yml`** (raíz del proyecto).
