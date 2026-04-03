# Verificación: implementación del servicio WhatsApp

Resumen de cómo está implementado el servicio WhatsApp y cómo actualizarlo sin romper Traefik ni la sesión.

---

## 1. Cómo está definido

| Aspecto | Detalle |
|--------|---------|
| **Código** | `whatsapp-server/whatsapp-server-baileys.js` (entrada: `node whatsapp-server-baileys.js`) |
| **Dockerfile** | `whatsapp-server/Dockerfile` (Node 20-slim, puerto 3001) |
| **Compose** | `docker-compose.easypanel.yml` → servicio `whatsapp` |
| **Imagen (compose)** | `easypanel/checkin24hs/whatsapp:latest` |
| **Servicio Swarm (nombre típico)** | `checkin24hs_whatsapp` |
| **Red** | `easypanel` (necesaria para Traefik) |
| **Puerto interno** | 3001 |
| **Dominio** | `whatsapp.checkin24hs.com` (HTTPS, Traefik) |
| **Sesión Baileys** | Carpeta `auth_info_baileys_1` (o _2, _3 según `INSTANCE_NUMBER`) |

---

## 2. Problemas que suelen pasar

1. **404 en whatsapp.checkin24hs.com**  
   Después de un Redeploy, EasyPanel a veces no mantiene los labels de Traefik.  
   **Solución:** Reaplicar labels por SSH (ver sección 4).

2. **Sesión perdida (volver a escanear QR)**  
   Si no hay volumen para `auth_info_baileys_*`, cada redeploy borra la sesión.  
   **Solución:** Usar volumen persistente para la carpeta de auth (ver sección 5).

3. **Imagen equivocada al actualizar**  
   El compose usa `easypanel/checkin24hs/whatsapp:latest`. Si en el servidor construís con `docker build -t whatsapp-server:latest`, el servicio puede seguir usando la imagen vieja si fue creado con otra etiqueta.  
   **Solución:** Construir con la misma etiqueta que usa el compose o actualizar el servicio apuntando a la imagen que construiste (ver sección 3).

4. **Mensajes que no llegan al teléfono (Argentina)**  
   Números sin el "9" después del 54 (ej. 542944210725 en lugar de 5492944210725).  
   **Solución:** Ya está en código con `normalizarNumeroParaEnvio()` en `/api/send`. Hay que desplegar el servidor para que aplique.

5. **"No se pudo enviar por chat" / CORS: el mensaje no aparece en Chats (Flor IA)**  
   El dashboard llama directo a `whatsapp.checkin24hs.com/api/send`. Si el navegador bloquea por CORS, el mensaje se copia y se ofrece wa.me, pero **no** se envía por la API → no aparece en la sección Chats.  
   **Solución:** Estamos en **EasyPanel con Traefik**. Las cabeceras CORS se configuran en el stack/proxy del lado de `whatsapp.checkin24hs.com` (no en hPanel). La respuesta debe incluir al menos: `Access-Control-Allow-Origin: https://dashboard.checkin24hs.com`, `Access-Control-Allow-Methods: GET, POST, OPTIONS`, `Access-Control-Allow-Headers: Content-Type, Authorization`, `Access-Control-Allow-Credentials: true`, tanto en OPTIONS (preflight) como en POST a `/api/send`.  
   En el servidor ejecutá **`bash scripts/aplicar_cors_whatsapp_servidor.sh`** para aplicar el middleware CORS en Traefik a los routers del servicio WhatsApp. El mismo bloque está en `docker-compose.easypanel.yml`; si hacés Redeploy from Compose, Traefik recarga la config. Después probá "Guardar y Enviar al Cliente" y en DevTools → Network revisá que OPTIONS y POST tengan en Response Headers `Access-Control-Allow-Origin: https://dashboard.checkin24hs.com`.

   **Si CORS sigue fallando:** En el servidor ejecutá **`bash scripts/diagnostico_cors_whatsapp.sh`**. El script hace un `OPTIONS` a `whatsapp.checkin24hs.com/api/send` y muestra si la respuesta incluye `Access-Control-Allow-Origin`.  
   - Si **no** aparece esa cabecera ni siquiera desde el servidor, el preflight no está llegando al backend o el proxy (Traefik/EasyPanel) que sirve ese dominio no está aplicando CORS. En ese caso: comprobá en EasyPanel que el dominio `whatsapp.checkin24hs.com` esté asociado al servicio de este stack (el que tiene los labels de Traefik del compose). Si EasyPanel creó la ruta con otro proxy o con otro servicio, los labels de CORS no se aplican; entonces hay que configurar CORS en la UI de EasyPanel para ese dominio o asegurarse de que el deploy use siempre este `docker-compose.easypanel.yml` para que Traefik use estos labels.

---

## 3. Cómo actualizar el servicio (dos formas)

**CORS / envío por Chats:** El dashboard llama **directo** a `https://whatsapp.checkin24hs.com/api/send`. Para que el mensaje se envíe por la API y aparezca en la **sección Chats** (Flor IA), el servidor WhatsApp debe enviar cabeceras CORS que permitan el origen `https://dashboard.checkin24hs.com`. En el servidor ejecutá: **`bash scripts/aplicar_cors_whatsapp_servidor.sh`** (aplica CORS en Traefik a los routers `whatsapp` y `checkin24hs_whatsapp`). Después probá de nuevo "Guardar y Enviar al Cliente". Si CORS sigue fallando, el dashboard copia el mensaje y ofrece abrir wa.me.

### Opción A: EasyPanel – Deploy desde el compose (recomendado)

1. **En tu PC:** subir cambios a GitHub.
   ```bash
   git add whatsapp-server/whatsapp-server-baileys.js
   git commit -m "WhatsApp: normalización número Argentina, fix X"
   git push origin main
   ```
2. **En EasyPanel:** Proyecto → app que usa este stack → **Deploy / Redeploy from Compose** apuntando a `docker-compose.easypanel.yml` (o al repo que lo tenga).
3. Así se construye `easypanel/checkin24hs/whatsapp:latest` y se actualiza el servicio. Los labels de Traefik están en el compose; si EasyPanel los respeta, no hace falta reaplicarlos.
4. Si después **whatsapp.checkin24hs.com** da 404, ir a la sección 4 (reaplicar labels).

### Opción B: Servidor (SSH) – construir imagen y actualizar servicio

1. **En el servidor:**
   ```bash
   cd /root/checkin24hs
   git pull origin main
   cd whatsapp-server
   docker build -t easypanel/checkin24hs/whatsapp:latest .
   docker service update --force checkin24hs_whatsapp
   ```
2. Usar la misma etiqueta `easypanel/checkin24hs/whatsapp:latest` para que el servicio Swarm use la imagen nueva.
3. Si el servicio fue creado con otra imagen (ej. `whatsapp-server:latest`), entonces:
   ```bash
   docker build -t whatsapp-server:latest .
   docker service update --image whatsapp-server:latest checkin24hs_whatsapp
   ```
4. Si después **whatsapp.checkin24hs.com** da 404, reaplicar labels (sección 4).

---

## 4. Si da 404: reaplicar Traefik (SSH)

Conectate por SSH y ejecutá (ajustá el nombre del servicio si no es `checkin24hs_whatsapp`):

```bash
SERVICE_NAME="checkin24hs_whatsapp"
docker service update --network-add easypanel "$SERVICE_NAME"
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  "$SERVICE_NAME"
```

Comprobar:

```bash
curl -s -o /dev/null -w "%{http_code}" https://whatsapp.checkin24hs.com/api/health
# Debería devolver 200
```

---

## 5. Persistir la sesión WhatsApp (volumen)

Para no tener que escanear el QR en cada redeploy, la carpeta de auth tiene que estar en un volumen. En el servidor, si el servicio se crea/actualiza a mano, podés añadir un volumen. Ejemplo (ajustar ruta según donde quieras guardar):

```bash
# Crear carpeta en el host (una vez)
mkdir -p /root/checkin24hs/whatsapp-auth

# Al crear/actualizar el servicio (si usás docker service y soporta mount)
# En EasyPanel: en el servicio WhatsApp → Volúmenes → montar /root/checkin24hs/whatsapp-auth en /app/auth_info_baileys_1
```

Si usás **solo** el compose (sin EasyPanel añadiendo volúmenes), podés añadir en `docker-compose.easypanel.yml` bajo el servicio `whatsapp`:

```yaml
volumes:
  - whatsapp-auth:/app/auth_info_baileys_1
```
y al final del archivo:
```yaml
volumes:
  whatsapp-auth:
```

Así la sesión sobrevive al redeploy. Si ya tenés el servicio creado en Swarm desde EasyPanel, los volúmenes a veces se configuran desde la UI (EasyPanel → servicio → Volúmenes).

---

## 6. Verificar después de actualizar

```bash
# Logs recientes
docker service logs checkin24hs_whatsapp --tail 50

# Que el servicio esté corriendo
docker service ps checkin24hs_whatsapp --no-trunc | head -5

# Health
curl -s https://whatsapp.checkin24hs.com/api/health
```

---

## 7. Referencia rápida

| Acción | Dónde | Comando / Paso |
|--------|--------|-----------------|
| Subir código | PC | `git add whatsapp-server/` → `commit` → `push` |
| Actualizar (compose) | EasyPanel | Deploy / Redeploy from Compose |
| Actualizar (servidor) | SSH | `git pull` → `cd whatsapp-server` → `docker build -t easypanel/checkin24hs/whatsapp:latest .` → `docker service update --force checkin24hs_whatsapp` |
| 404 después de deploy | SSH | Reaplicar labels (sección 4) |
| Sesión persistente | Compose o EasyPanel | Volumen para `auth_info_baileys_1` |
| CORS / envío por Chats | SSH | `bash scripts/aplicar_cors_whatsapp_servidor.sh` |
| CORS sigue fallando | SSH | `bash scripts/diagnostico_cors_whatsapp.sh` → ver cabeceras y labels; revisar en EasyPanel que el dominio use este stack |

Documento generado para alinear la última implementación y evitar los problemas típicos (404, sesión perdida, imagen equivocada).
