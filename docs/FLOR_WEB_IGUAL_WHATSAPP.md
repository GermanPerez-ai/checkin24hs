# Por qué el chat de la web no funciona como WhatsApp (y cómo arreglarlo)

Para que Flor en la web responda **igual** que en WhatsApp, la web tiene que usar la **Flor API**. Desde 2025 se usa **flor-api** (proxy bajo el mismo dominio): la web llama a `https://www.checkin24hs.com/api/flor/process` → **sin CORS** → flor-api reenvía al servidor WhatsApp y devuelve la misma respuesta. **No entra en conflicto con WhatsApp**: solo reenvía la petición.

---

## 1. Ver qué está pasando ahora

Abrí https://www.checkin24hs.com, abrí Flor, **F12 → Consola** y enviá un mensaje (ej. "info de Futangue").

- **Si ves:** `[Flor AI] 📡 Origen: intentando Flor API (WhatsApp)` y luego `[Flor AI] 🌸 Respuesta desde Flor API (misma que WhatsApp)`  
  → La web **sí** está usando la misma Flor que WhatsApp. Si aun así responde distinto, el problema es otro (ej. contexto distinto).

- **Si ves:** `[Flor AI] Flor API no alcanzable (¿CORS?)`  
  → El navegador está **bloqueando** la llamada a whatsapp.checkin24hs.com. Falta **CORS** en el servidor WhatsApp.

- **Si ves:** `[Flor AI] ⚠️ Origen: sin API key` y después `[Flor Agent] 📋 Origen: reglas`  
  → La web **no** está intentando la Flor API (no tiene URL o no la recibe el iframe), o la API falló y no hay Gemini; responde por **reglas** + flor_info.

- **Si no ves** ningún `[Flor AI] 📡 Origen: intentando Flor API`  
  → El iframe **no** recibe `florApiUrl` (la web se construyó sin `VITE_FLOR_API_URL` o el build no la pasa).

---

## 2. Qué tiene que estar bien

### A) La web debe tener la URL de la Flor API

- En el **build** de la web tiene que estar `VITE_FLOR_API_URL` (en el compose ya está por defecto `https://whatsapp.checkin24hs.com`).
- El **iframe** del chat recibe esa URL como `florApiUrl` en la query (ej. `flor-chatbot.html?...&florApiUrl=https://whatsapp.checkin24hs.com`).
- **Comprobar:** En la consola, al cargar el chat, no debería aparecer:  
  `[Flor] florApiUrl no está en la URL del iframe`.

### B) CORS del servidor WhatsApp

- El servidor que sirve **whatsapp.checkin24hs.com** (Traefik + servicio WhatsApp) debe permitir peticiones desde **https://www.checkin24hs.com**.
- En el compose está:  
  `accesscontrolalloworiginlist=https://dashboard.checkin24hs.com,https://www.checkin24hs.com`
- Esos **labels** tienen que estar aplicados al **servicio** que atiende WhatsApp en el servidor (Swarm/EasyPanel). Si el stack se desplegó antes del cambio de CORS, el servicio puede seguir con el CORS viejo (solo dashboard).

---

## 3. Qué hacer en el servidor

### Opción 1: Actualizar solo el CORS del servicio WhatsApp

En el servidor (SSH):

```bash
docker service update \
  --label-add "traefik.http.middlewares.whatsapp-cors.headers.accesscontrolalloworiginlist=https://dashboard.checkin24hs.com,https://www.checkin24hs.com" \
  checkin24hs_whatsapp
```

(Si el servicio tiene otro nombre, listalo con `docker service ls | grep -i whatsapp` y usá ese nombre.)

### Opción 2: Redeploy del stack desde EasyPanel

Si usás EasyPanel para este proyecto, hacé **Redeploy** del stack que incluye el servicio WhatsApp, para que tome el `docker-compose.easypanel.yml` actual (con CORS que incluye www.checkin24hs.com).

### Reconstruir y desplegar la web

Para que la web lleve `florApiUrl` y los últimos cambios:

```bash
cd /root/checkin24hs
git pull origin main
bash scripts/deploy_web_servidor.sh
```

---

## 4. Comprobar de nuevo

1. Entrá a https://www.checkin24hs.com (mejor **Ctrl+Shift+R** o ventana de incógnito).
2. Abrí Flor y la consola (F12).
3. Escribí por ejemplo "info de Futangue".

Si todo está bien deberías ver:

- `[Flor] Usando Flor API (misma que WhatsApp): https://www.checkin24hs.com` (mismo origen, sin CORS)
- `[Flor AI] 📡 Origen: intentando Flor API (WhatsApp)`
- `[Flor AI] 🌸 Respuesta desde Flor API (misma que WhatsApp)`

Y la respuesta debería ser la misma que en WhatsApp (mismo texto, mismo criterio).

---

## API dedicada para la web (flor-api) — sin conflicto con WhatsApp

- **Servicio:** `flor-api` (en `flor-web-api/`). Proxy que recibe `POST /api/flor/process` y reenvía al servidor WhatsApp (misma lógica Flor).
- **URL:** **https://flor-api.checkin24hs.com** (subdominio propio para evitar 404 con enrutado por path en EasyPanel).
- **CORS:** La API permite orígenes `https://www.checkin24hs.com` y `https://checkin24hs.com`.
- **Conflicto con WhatsApp:** Ninguno. WhatsApp sigue en whatsapp.checkin24hs.com; flor-api solo reenvía.
- **Despliegue:** Incluido en `docker-compose.easypanel.yml`. Redeploy en EasyPanel construye y levanta `flor-api`.
- **Dominio:** Hay que tener **flor-api.checkin24hs.com** apuntando al mismo servidor (registro DNS tipo A o CNAME) para que Traefik/Let's Encrypt sirva HTTPS. En EasyPanel, si usás el mismo host que el resto, el mismo certificado o dominio suele valer; si no, añadí el subdominio en tu DNS.

### Si el build de flor-api falla en EasyPanel con "flor-web-api: no such file or directory"

EasyPanel clona el repo en `code/` y espera `code/flor-web-api`; si el contexto o la ruta del Dockerfile no coinciden con la estructura real, aparece ese error. Para evitarlo se usa un **Dockerfile en la raíz** que construye desde `flor-web-api/`:

- **En el repo:** existe `flor-api.Dockerfile` en la raíz. Hace `COPY flor-web-api/...` y construye la app; el contexto de build es la raíz del repo.
- **En EasyPanel (flor-api):**
  - **Build context:** raíz del repo (`.` o vacío; no poner subcarpeta `flor-web-api`).
  - **Dockerfile path:** `flor-api.Dockerfile` (no `flor-web-api/Dockerfile`).

Así el build usa siempre la raíz del clone y no depende de que exista `code/flor-web-api` como ruta. Después del deploy, comprobar que el servicio esté en verde y que `https://flor-api.checkin24hs.com/health` responda.

---

## Resumen

| Causa frecuente | Síntoma en consola | Solución |
|-----------------|--------------------|----------|
| CORS no permite www | `Flor API no alcanzable (¿CORS?)` | Actualizar labels del servicio WhatsApp (o redeploy) con `www.checkin24hs.com` en la lista de orígenes |
| iframe sin florApiUrl | No aparece "intentando Flor API" o aviso de florApiUrl | Build de la web con VITE_FLOR_API_URL (default https://www.checkin24hs.com) y redeploy web + tener flor-api desplegado |
| API cae o devuelve error | "Flor API respondió 4xx/5xx" | Revisar logs del contenedor WhatsApp y que `/api/flor/process` responda bien |

Cuando la web use la Flor API sin errores de CORS, el chat de la web funciona como en WhatsApp porque usa el mismo backend.
