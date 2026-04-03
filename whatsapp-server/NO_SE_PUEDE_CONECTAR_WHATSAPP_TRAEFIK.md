# No se puede conectar WhatsApp – Revisar Traefik

Si **no podés conectar WhatsApp** (por ejemplo no carga el QR en `https://whatsapp.checkin24hs.com` o da 404), suele ser porque **Traefik no está enrutando** ese dominio al servicio WhatsApp. Hay que revisar y, si falta, aplicar las etiquetas de Traefik.

---

## 1. Verificar y corregir en el servidor (SSH)

En el servidor donde corre EasyPanel/Docker:

```bash
cd ~/checkin24hs/whatsapp-server
bash VERIFICAR_Y_CORREGIR_TRAEFIK_WHATSAPP.sh
```

El script:

- Busca el servicio WhatsApp (p. ej. `checkin24hs_whatsapp`).
- Muestra las **etiquetas Traefik** actuales.
- Muestra **red** y **estado** del servicio.
- Si faltan etiquetas, **pregunta si querés aplicarlas** y las agrega.

Si preferís **aplicar sin preguntar**:

```bash
echo s | bash VERIFICAR_Y_CORREGIR_TRAEFIK_WHATSAPP.sh
```

---

## 2. Comandos manuales (si conocés el nombre del servicio)

Ver el nombre del servicio:

```bash
docker service ls | grep -i whatsapp
```

Ver etiquetas Traefik del servicio (reemplazá `checkin24hs_whatsapp` si es otro):

```bash
docker service inspect checkin24hs_whatsapp --format '{{range $k,$v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik
```

Si **no hay** etiquetas o falta el router de `whatsapp.checkin24hs.com`, agregar:

```bash
SERVICE_NAME="checkin24hs_whatsapp"   # o el nombre que te dio docker service ls

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

Importante: el **puerto interno** del servidor WhatsApp es **3001**. Traefik debe usar ese puerto.

Si el servicio no está en la red de Traefik:

```bash
docker service update --network-add easypanel checkin24hs_whatsapp
```

Esperá 30–60 segundos y probá:

- https://whatsapp.checkin24hs.com/api/health  
- https://whatsapp.checkin24hs.com/api/qr  

---

## 3. Desde EasyPanel

1. Entrá a **EasyPanel** → proyecto → servicio **WhatsApp**.
2. En **Dominios**, agregá **`whatsapp.checkin24hs.com`**.
3. Asegurate de que el **puerto interno** del servicio sea **3001** (en la configuración del servicio).
4. Si EasyPanel no deja poner 3001 para el dominio, las etiquetas hay que agregarlas por SSH (paso 2).

---

## 4. DNS

Para que el dominio funcione, en el DNS de **checkin24hs.com** debe existir:

- **Tipo:** A  
- **Nombre:** `whatsapp` (o `whatsapp.checkin24hs.com` según el panel)  
- **Valor:** IP del servidor (donde está EasyPanel/Traefik)

Comprobar:

```bash
nslookup whatsapp.checkin24hs.com
```

---

## Resumen

| Síntoma              | Revisar / Hacer                                      |
|----------------------|------------------------------------------------------|
| 404 en whatsapp.checkin24hs.com | Etiquetas Traefik (script o `docker service update`). |
| Servicio no en red   | `docker service update --network-add easypanel <servicio_whatsapp>`. |
| Puerto incorrecto    | Que exista `traefik.http.services.whatsapp.loadbalancer.server.port=3001`. |
| Sigue sin conectar   | DNS de `whatsapp.checkin24hs.com` y reinicio de Traefik. |

Cuando Traefik esté bien configurado, `/api/health`, `/api/qr` y `/qr` deberían responder y poder usar el QR para conectar WhatsApp.
