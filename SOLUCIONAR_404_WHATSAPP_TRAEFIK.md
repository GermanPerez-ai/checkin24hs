# Solucionar 404 en https://whatsapp.checkin24hs.com/qr

El error **404** en `https://whatsapp.checkin24hs.com/qr` (y a veces también en `/api/qr`) suele deberse a que **Traefik no está enviando el tráfico al servicio WhatsApp**: falta configuración de dominio o labels incorrectas.

---

## 1. Probar primero /api/qr

Mientras ajustas Traefik, probá esta URL (mismo contenido que `/qr`):

```
https://whatsapp.checkin24hs.com/api/qr
```

Si **también** da 404, Traefik no está enrutando nada al servicio WhatsApp → seguí los pasos siguientes.

---

## 2. Configurar Traefik desde EasyPanel (recomendado)

1. Entrá a **EasyPanel** → proyecto **checkin24hs** → servicio **whatsapp**.
2. Abrí la pestaña **Dominios** (o **Domains**).
3. Agregá el dominio **`whatsapp.checkin24hs.com`**.
4. Asegurate de que:
   - **HTTPS** esté habilitado (Let's Encrypt).
   - El **puerto interno** del servicio sea **3001** (en la sección Deploy/Source del servicio WhatsApp suele verse el puerto; si no, en **Recursos** o **Variables**).
5. Guardá y esperá 1–2 minutos.

Si EasyPanel no permite elegir el puerto 3001 al agregar el dominio, Traefik puede estar usando otro puerto (por ejemplo 80). En ese caso hay que **agregar las labels a mano** (paso 3).

---

## 3. Configurar Traefik por SSH (labels manuales)

Si el dominio ya está en EasyPanel y sigue el 404, o si EasyPanel no configura bien el puerto, aplicá las labels de Traefik al servicio WhatsApp.

**Nombre típico del servicio en Docker:** `checkin24hs_whatsapp` (proyecto + servicio en EasyPanel).

En el servidor (SSH):

```bash
# Ver el nombre exacto del servicio
docker service ls | grep -i whatsapp
```

Luego, con ese nombre (ej. `checkin24hs_whatsapp`), ejecutá:

```bash
SERVICE_NAME="checkin24hs_whatsapp"

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  "$SERVICE_NAME"
```

Importante: **`traefik.http.services.whatsapp.loadbalancer.server.port=3001`** tiene que ser **3001** (puerto donde escucha el servidor WhatsApp).

Si el servicio está en otra red y Traefik no lo ve:

```bash
docker service update --network-add easypanel "$SERVICE_NAME"
```

Esperá 15–30 segundos y probá:

- https://whatsapp.checkin24hs.com/api/health  
- https://whatsapp.checkin24hs.com/api/qr  
- https://whatsapp.checkin24hs.com/qr  

---

## 4. Verificar que las labels quedaron bien

```bash
docker service inspect checkin24hs_whatsapp --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
```

Deberías ver algo como:

- `traefik.enable=true`
- `traefik.http.routers.whatsapp.rule=Host(`whatsapp.checkin24hs.com`)`
- `traefik.http.routers.whatsapp.entrypoints=websecure`
- `traefik.http.routers.whatsapp.service=whatsapp`
- `traefik.http.services.whatsapp.loadbalancer.server.port=3001`

---

## 5. DNS

Para que el dominio funcione, en el DNS de **checkin24hs.com** tiene que existir:

- **Tipo:** A  
- **Nombre:** whatsapp (o `whatsapp.checkin24hs.com` según tu proveedor)  
- **Valor:** IP del servidor donde corre EasyPanel/Traefik  

Comprobación:

```bash
nslookup whatsapp.checkin24hs.com
```

---

## Resumen

| Causa típica del 404 | Qué hacer |
|----------------------|-----------|
| Dominio no configurado en Traefik | EasyPanel → whatsapp → Dominios → agregar `whatsapp.checkin24hs.com` y puerto 3001. |
| Labels faltantes o incorrectas | Ejecutar el `docker service update` anterior con el nombre correcto del servicio. |
| Puerto equivocado | Asegurar `traefik.http.services.whatsapp.loadbalancer.server.port=3001`. |
| Servicio fuera de la red de Traefik | `docker service update --network-add easypanel checkin24hs_whatsapp`. |

Cuando Traefik esté bien configurado, tanto **/qr** como **/api/qr** deberían responder correctamente.
