# 📱 WhatsApp – Configuración nueva (única y simple)

Guía **única** para conectar WhatsApp con Flor IA.

---

## 1. Qué tenés que tener

- **Dashboard**: https://dashboard.checkin24hs.com (Flor IA → WhatsApp).
- **Servidor WhatsApp (Baileys)**: Servicio Docker `checkin24hs_whatsapp` en puerto **3001**.
- **Traefik**: **https://api1.checkin24hs.com** → ese servicio (websecure + TLS).
- **DNS**: `api1.checkin24hs.com` apuntando a la IP del servidor.

---

## 2. En el servidor (SSH)

### 2.1 ¿Existe el servicio WhatsApp?

```bash
docker service ls | grep whatsapp
docker service ps checkin24hs_whatsapp --no-trunc 2>/dev/null | head -3
```

Si **no existe**: crealo (EasyPanel/Docker) desde `whatsapp-server/`. Nombre: **checkin24hs_whatsapp**, puerto **3001**.

### 2.2 Configurar Traefik para api1

```bash
cd /root/checkin24hs
chmod +x RESTAURAR_TRAEFIK_WHATSAPP.sh
./RESTAURAR_TRAEFIK_WHATSAPP.sh
```

### 2.3 Verificar

Esperá 30–60 segundos:

```bash
curl -sI https://api1.checkin24hs.com/api/status | head -5
curl -s https://api1.checkin24hs.com/api/status
```

Deberías ver **HTTP/2 200** y JSON. Si **404** o **502** → Traefik o servicio mal configurados.

---

## 3. En el dashboard

1. **https://dashboard.checkin24hs.com** → **Flor IA** → **WhatsApp**.
2. URL = **`https://api1.checkin24hs.com`** → **Guardar**.
3. **Conectar** → modal con **QR**.
4. Escanealo con WhatsApp: Dispositivos vinculados → Vincular dispositivo.

---

## 4. Si algo falla

| Problema | Qué hacer |
|----------|-----------|
| **404** o **CORS** | Ejecutá **`./RESTAURAR_TRAEFIK_WHATSAPP.sh`** en el servidor. Verificá api1 con `curl`. |
| **Servicio no encontrado** | Creá `checkin24hs_whatsapp` (puerto 3001), luego el script Traefik. |
| **Dashboard desde `file://`** | WhatsApp **solo** funciona desde **https://dashboard.checkin24hs.com**. |
| **Flor no responde a mensajes** | El **servicio WhatsApp** (no el dashboard) debe tener **`GEMINI_API_KEY`** en sus variables de entorno (EasyPanel → checkin24hs_whatsapp → Variables). Sin esa clave, Flor no puede usar la IA para contestar. |
| **504 / Timeout al vincular; modal no se cierra** | Tras escanear el QR, Baileys puede tardar 30–60 s. El dashboard reintenta cada 3 s (timeout 60 s). Si ves 504: `docker service update --force checkin24hs_whatsapp`, esperá 1–2 min y probá de nuevo. |

---

## 5. Teléfono “sesión activa” pero dashboard “Desconectado”

El estado se actualiza al abrir la pestaña WhatsApp y cada **25 segundos** mientras estés en ella. Si el backend a veces reporta “disconnected” (p. ej. por reconexiones de Baileys), hacé clic en **Actualizar** o esperá al próximo refresco. Si sigue “Desconectado” con sesión activa en el teléfono, revisá los logs del servicio: `docker service logs checkin24hs_whatsapp --tail 50`.

---

## 6. Resumen

1. **Servidor**: `checkin24hs_whatsapp` en 3001, con **`GEMINI_API_KEY`** para que Flor responda con IA.
2. **Traefik**: `./RESTAURAR_TRAEFIK_WHATSAPP.sh` → api1 con HTTPS.
3. **Dashboard**: Flor IA → WhatsApp → URL → Guardar → Conectar → escanear QR. El modal se cierra solo al vincular.
