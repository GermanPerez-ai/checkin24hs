# WhatsApp + Traefik en EasyPanel: 404 / Bad Gateway

Guía para que **whatsapp.checkin24hs.com** (y `/qr`) funcione correctamente detrás de Traefik en Docker Swarm con EasyPanel.

---

## Pasos necesarios en orden

Seguir **en este orden** para dejar WhatsApp accesible por https://whatsapp.checkin24hs.com sin 404 ni Bad Gateway.

### En EasyPanel (navegador)

| Paso | Dónde | Acción |
|------|--------|--------|
| 1 | EasyPanel → Proyecto checkin24hs → Servicio **WhatsApp** | Si el dominio ya existe: ir a **Dominios** y **quitar temporalmente** whatsapp.checkin24hs.com. Guardar. (Así EasyPanel deja de publicar el puerto.) |
| 2 | Misma pestaña **Puertos** | Comprobar que no haya ninguna regla (Publicado/Destino). Si hay, eliminarla y guardar. |

### En el servidor (SSH)

| Paso | Comando o acción |
|------|------------------|
| 3 | Comprobar si hay puerto publicado: `docker service inspect checkin24hs_whatsapp --format '{{json .Spec.EndpointSpec}}'` |
| 4 | Si aparece `"Ports":[...]`: quitar por puerto **destino** (3001): `docker service update --publish-rm 3001 checkin24hs_whatsapp` |
| 5 | Esperar a que el servicio converja (mensaje "Service ... converged"). |
| 6 | Verificar que ya no haya puertos: `docker service inspect checkin24hs_whatsapp --format '{{json .Spec.EndpointSpec}}'` → debe ser `{"Mode":"vip"}` sin `"Ports"`. |
| 7 | Activar modo dnsrr: `docker service update --endpoint-mode dnsrr checkin24hs_whatsapp` |
| 8 | Esperar a que converja. Verificar: `docker service inspect checkin24hs_whatsapp --format '{{json .Spec.EndpointSpec}}'` → debe ser `{"Mode":"dnsrr"}`. |
| 9 | (Opcional) Si el servicio no está en la red del proyecto: `docker service update --network-add name=easypanel-checkin24hs,alias=checkin24hs_whatsapp,alias=checkin24hs-whatsapp checkin24hs_whatsapp` |
| 10 | Añadir labels de Traefik (solo si da 404 y el dominio en EasyPanel no enruta): ver sección "Labels de Traefik" más abajo. |
| 11 | Reiniciar Traefik: `docker service update --force traefik` |
| 12 | Esperar 1–2 minutos. |

### De nuevo en EasyPanel

| Paso | Dónde | Acción |
|------|--------|--------|
| 13 | Servicio WhatsApp → **Dominios** | **Agregar dominio**: Host `whatsapp.checkin24hs.com`, Puerto destino `3001`, Ruta `/`, HTTPS activado. Guardar. |
| 14 | Pestaña **Puertos** | Confirmar que **no** se haya creado una nueva publicación. Si aparece, quitarla y guardar. |

### Comprobar

| Paso | Acción |
|------|--------|
| 15 | En el navegador: https://whatsapp.checkin24hs.com y https://whatsapp.checkin24hs.com/qr . Debe cargar la página (Conectado / QR). |

---

## Síntomas

- **404**: Traefik no tiene ruta para el dominio (faltan labels o el dominio no está en EasyPanel).
- **Bad Gateway**: Traefik recibe la petición pero no puede conectar con el backend (VIP del servicio inalcanzable).

---

## Causa del Bad Gateway

En Swarm, el nombre del servicio (`checkin24hs_whatsapp`) resuelve por defecto a una **VIP** (Virtual IP). En algunos entornos esa VIP no es alcanzable desde el contenedor de Traefik, por eso da Bad Gateway aunque el task del servicio esté en marcha.

La solución es usar **endpoint-mode dnsrr**: el nombre del servicio pasa a resolver a la **IP del task**, a la que sí se puede conectar Traefik.

---

## Requisitos previos

- Servicio: `checkin24hs_whatsapp` (puerto interno **3001**).
- Dominio en EasyPanel: **whatsapp.checkin24hs.com** (pestaña Dominios, Puerto destino 3001).
- El servicio debe estar en la red **easypanel-checkin24hs** (la de Traefik).

---

## Pasos para corregir (SSH en el servidor)

### 1. Labels de Traefik (si da 404)

Si el dominio no enruta, asegurar labels en el servicio:

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  checkin24hs_whatsapp
```

En muchos casos EasyPanel configura el dominio desde la pestaña **Dominios** y no usa estas labels; si el dominio ya está en el panel, este paso puede no ser necesario.

---

### 2. Quitar el puerto publicado (obligatorio para dnsrr)

EasyPanel suele publicar un puerto (ej. 3010→3001) en el servicio. Con ese puerto publicado **no** se puede usar `dnsrr`.

**Opción A – Desde EasyPanel**

1. Servicio WhatsApp → pestaña **Dominios**.
2. **Quitar temporalmente** el dominio whatsapp.checkin24hs.com y guardar.
3. En el servidor (ver Opción B) quitar el puerto y poner dnsrr.
4. Volver a EasyPanel y **agregar de nuevo** el dominio (Host, Puerto 3001, etc.). Revisar que en **Puertos** no se cree de nuevo una publicación.

**Opción B – Por CLI (quitar por puerto destino)**

Comprobar si hay puerto publicado:

```bash
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.EndpointSpec}}'
```

Si aparece `"Ports":[{"TargetPort":3001,"PublishedPort":3010,...}]`, quitarlo por **target port** (no por el publicado):

```bash
docker service update --publish-rm 3001 checkin24hs_whatsapp
```

Verificar que ya no haya puertos:

```bash
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.EndpointSpec}}'
# Debe mostrar: {"Mode":"vip"}  (sin "Ports")
```

---

### 3. Activar endpoint-mode dnsrr

Solo cuando **no** quede ningún puerto publicado:

```bash
docker service update --endpoint-mode dnsrr checkin24hs_whatsapp
```

Comprobar:

```bash
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.EndpointSpec}}'
# Debe mostrar: {"Mode":"dnsrr"}
```

---

### 4. Red y aliases (opcional)

Si el servicio no está en la red del proyecto:

```bash
docker service update \
  --network-add name=easypanel-checkin24hs,alias=checkin24hs_whatsapp,alias=checkin24hs-whatsapp \
  checkin24hs_whatsapp
```

---

### 5. Reiniciar Traefik

Para que Traefik deje de usar una IP antigua (VIP) y resuelva de nuevo el nombre del servicio:

```bash
docker service ls | grep -i traefik
docker service update --force traefik
```

Esperar 1–2 minutos y probar en el navegador:

- https://whatsapp.checkin24hs.com  
- https://whatsapp.checkin24hs.com/qr  

---

## Si EasyPanel vuelve a publicar el puerto

Al volver a agregar o editar el dominio, EasyPanel puede volver a publicar un puerto (ej. 3010). Entonces:

1. En **EasyPanel** → servicio WhatsApp → **Puertos**: si aparece una regla, quitarla y guardar.
2. Por CLI, si hace falta:
   ```bash
   docker service update --publish-rm 3001 checkin24hs_whatsapp
   ```
3. Comprobar que el modo siga siendo dnsrr:
   ```bash
   docker service inspect checkin24hs_whatsapp --format '{{json .Spec.EndpointSpec}}'
   ```
   Debe ser `{"Mode":"dnsrr"}` sin `"Ports"`. Si volvió a aparecer un puerto, repetir el `--publish-rm 3001`.

---

## Comandos útiles de diagnóstico

```bash
# Estado del servicio
docker service ps checkin24hs_whatsapp --no-trunc

# Puertos y modo del servicio
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.EndpointSpec}}'

# Probar si el backend responde desde la red de Traefik
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -sI --connect-timeout 5 http://checkin24hs_whatsapp:3001/
```

Si el `curl` devuelve `HTTP/1.1 200` y el navegador sigue con Bad Gateway, suele bastar con reiniciar Traefik (`docker service update --force traefik`).

---

## Resumen rápido (ya configurado dominio en EasyPanel)

```bash
# 1. Quitar puerto (por target 3001)
docker service update --publish-rm 3001 checkin24hs_whatsapp

# 2. Cuando Spec.EndpointSpec no tenga Ports: activar dnsrr
docker service update --endpoint-mode dnsrr checkin24hs_whatsapp

# 3. Reiniciar Traefik
docker service update --force traefik
```

Luego probar https://whatsapp.checkin24hs.com y https://whatsapp.checkin24hs.com/qr.
