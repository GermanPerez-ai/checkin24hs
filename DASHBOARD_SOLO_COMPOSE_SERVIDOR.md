# Dashboard solo con docker-compose.easypanel.yml (en el servidor)

El dashboard **no se configura en la UI de EasyPanel**. Todo está en **docker-compose.easypanel.yml**: el servicio `dashboard`, Traefik (labels), red `easypanel`. Solo hay que **desplegar ese compose en el servidor**.

---

## 1. Cómo está definido

En **docker-compose.easypanel.yml** tenés:

- Servicio **dashboard** (build desde `deploy/dashboard-html/Dockerfile`, puerto **3000**).
- Labels de **Traefik**: `Host(dashboard.checkin24hs.com)`, HTTPS, red **easypanel**.

No hay “dominio” ni “dashboard” que configurar a mano en EasyPanel. Si el stack se despliega con este compose, Traefik lee los labels del contenedor y expone https://dashboard.checkin24hs.com.

---

## 2. Qué hacer en el servidor

Conectate por **SSH** al servidor donde corre Docker (y Traefik/EasyPanel).

### A) Red `easypanel`

Traefik y los contenedores del compose tienen que estar en la misma red:

```bash
docker network ls | grep easypanel
```

Si no existe:

```bash
docker network create easypanel
```

### B) Desplegar (o actualizar) el stack

Desde la **carpeta donde está el repo** (donde está `docker-compose.easypanel.yml`):

```bash
cd /ruta/al/repo/Checkin24hs   # la ruta real en tu servidor

# Opción 1: Docker Compose (recomendado si usás compose en el servidor)
docker compose -f docker-compose.easypanel.yml up -d --build

# Opción 2: Si usás docker-compose (v1)
docker-compose -f docker-compose.easypanel.yml up -d --build
```

`--build` hace que se construya de nuevo la imagen del dashboard (con tu `dashboard.html` actual).

### C) Comprobar que el dashboard está arriba

```bash
docker ps | grep dashboard
```

Deberías ver un contenedor del dashboard en estado **Up**, escuchando en **3000**.

Ver logs por si falló al arrancar:

```bash
docker compose -f docker-compose.easypanel.yml logs dashboard --tail 50
```

### D) Probar dentro del servidor (opcional)

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
```

O, si el contenedor tiene otro nombre:

```bash
docker ps --format "{{.Names}}" | grep dashboard
curl -s -o /dev/null -w "%{http_code}" http://<nombre_contenedor>:3000
```

Si eso devuelve **200**, el dashboard responde; el 404 entonces es de Traefik (no ve el servicio o la red).

---

## 3. Si usás EasyPanel solo para “Deploy from Compose”

- En EasyPanel no tenés que crear servicios ni dominios a mano.
- Solo asegurate de que la **app** que usa **docker-compose.easypanel.yml** (por Git o por archivo en el servidor) haga **Deploy** o **Redeploy**.
- Ese deploy es el que levanta el stack (dashboard, whatsapp, cotizador, webmail) con los labels de Traefik.
- Después de un Redeploy, esperá 1–2 minutos y probá **https://dashboard.checkin24hs.com/**.

---

## 4. Resumen

| Dónde | Qué hacer |
|-------|-----------|
| **EasyPanel UI** | Nada de “dominio” o “dashboard” a mano. Solo Deploy/Redeploy del compose si usás eso. |
| **Servidor** | Red `easypanel`, luego `docker compose -f docker-compose.easypanel.yml up -d --build` desde la carpeta del repo. |
| **404** | Revisar que el contenedor dashboard esté **Up**, que la red sea **easypanel** y que Traefik esté en esa misma red. |

Todo lo del dashboard está en **docker-compose.easypanel.yml**; el resto es desplegar ese archivo en el servidor (o desde EasyPanel “from Compose”) y que Traefik esté en la red `easypanel`.
