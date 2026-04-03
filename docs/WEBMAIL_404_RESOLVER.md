# Resolver 404 en webmail.checkin24hs.com

Cuando ves **404 page not found** (y en consola `favicon.ico` / `(index)` 404), suele ser que Traefik no está enrutando el dominio al contenedor de Roundcube o que el servicio no está corriendo.

## 1. Comprobar en el servidor (SSH)

Ejecutá el diagnóstico:

```bash
bash DIAGNOSTICAR_404_WEBMAIL.sh
```

O manualmente:

```bash
# ¿Existe y está corriendo el servicio?
docker service ls | grep webmail

# ¿Hay tarea activa?
docker service ps checkin24hs_webmail --no-trunc

# ¿Labels de Traefik en el servicio?
docker service inspect checkin24hs_webmail --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
```

- Si **no aparece** `checkin24hs_webmail`: el webmail no está desplegado. Seguí con el paso 2.
- Si **aparece** pero no hay labels `traefik.http.routers.webmail.*`: Traefik no tiene ruta para webmail. Seguí con el paso 2.

## 2. Desplegar / actualizar el webmail

El `docker-compose.easypanel.yml` ya incluye el servicio **webmail** (Roundcube) con las labels de Traefik para `webmail.checkin24hs.com`.

**Opción A – EasyPanel**

1. En EasyPanel, abrí la app que usa este compose (Checkin24hs).
2. Asegurate de que el servicio **webmail** esté en la lista y con estado **Running**.
3. Si no está, hacé **Deploy / Redeploy from Compose** (apuntando a `docker-compose.easypanel.yml` del repo).
4. Si está pero da 404, probá **Redeploy** del servicio webmail o **Update** para que Traefik vuelva a leer las labels.

**Opción B – Línea de comandos (servidor)**

```bash
cd /ruta/al/repo/Checkin24hs   # o donde tengas el repo

# Crear red si no existe
docker network create easypanel 2>/dev/null || true

# Levantar solo el servicio webmail (o todo el stack)
docker stack deploy -c docker-compose.easypanel.yml checkin24hs

# O, si ya usás otro nombre de stack, usá el mismo.
```

Después de desplegar, esperá 30–60 segundos y probá de nuevo:  
https://webmail.checkin24hs.com/

## 3. Red de Traefik

El webmail debe estar en la misma red que Traefik (por ejemplo `easypanel`):

```bash
docker service update --network-add easypanel checkin24hs_webmail
```

## 4. Forzar actualización del servicio

Si el servicio existe pero sigue dando 404:

```bash
docker service update --force checkin24hs_webmail
```

Esperá ~30 s y probá de nuevo la URL.

## 5. DNS

Comprobá que **webmail.checkin24hs.com** apunte al mismo servidor donde corren Traefik y el stack:

```bash
# En tu PC o en el servidor
nslookup webmail.checkin24hs.com
```

La IP debe ser la del servidor donde está EasyPanel/Traefik.

---

## Resumen

| Síntoma | Acción |
|--------|--------|
| No existe `checkin24hs_webmail` | Deploy/Redeploy from Compose (incluye webmail). |
| Servicio existe, 404 sigue | `docker service update --force checkin24hs_webmail` y comprobar labels + red. |
| Labels sin `webmail.checkin24hs.com` | Redeploy desde el compose actualizado (labels ya están en el repo). |
| 404 en favicon/index | Normal si la página principal da 404; al corregir la ruta de webmail suelen desaparecer. |

Guía detallada: **SOLUCION_404_WEBMAIL_TRAEFIK.md** en la raíz del repo.
