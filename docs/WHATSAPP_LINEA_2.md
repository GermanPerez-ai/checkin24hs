# WhatsApp Línea 2 — Segundo número (mismo negocio)

Dos números independientes, misma Flor y mismo Supabase. En el dashboard: pestañas **Línea 1** / **Línea 2** dentro de **Chats Activos**.

---

## 1. DNS

Creá un registro **A** (o CNAME) apuntando al mismo servidor que `whatsapp.checkin24hs.com`:

| Host | Tipo | Valor |
|------|------|--------|
| `whatsapp2.checkin24hs.com` | A | IP del servidor |

Verificá:

```bash
curl -s https://whatsapp2.checkin24hs.com/api/status
```

Antes del deploy verás error DNS (`Could not resolve host`).

---

## 2. Servidor — desplegar Línea 2

```bash
cd /root/checkin24hs
git pull origin main
bash scripts/deploy_whatsapp2_servidor.sh
```

Eso crea/actualiza el servicio Swarm `checkin24hs_whatsapp2` con:

- `INSTANCE_NUMBER=2`
- `PORT=3002`
- Volumen `whatsapp2-auth` → sesión en `auth_info_baileys_2`
- Traefik → `https://whatsapp2.checkin24hs.com`

**No uses el mismo número** que Línea 1. Escaneá el QR con el **segundo chip**.

---

## 3. Dashboard

Tras deploy del dashboard (Build ≥ 175):

- **Chats Activos** → pestañas **Línea 1** / **Línea 2**
- **Flor IA → WhatsApp** → estado y QR de cada línea

Config en `DASHBOARD_CONFIG.whatsappInstances`:

```javascript
whatsappInstances: [
  { instance: 1, label: 'Línea 1', url: 'https://whatsapp.checkin24hs.com' },
  { instance: 2, label: 'Línea 2', url: 'https://whatsapp2.checkin24hs.com' }
]
```

---

## 4. Base de datos

Los chats de Línea 2 se guardan con `whatsapp_instance = 2` en `whatsapp_chats` y `whatsapp_messages`. No hace falta otra base de datos.

---

## 5. Resumen

| | Línea 1 | Línea 2 |
|---|---------|---------|
| Dominio | whatsapp.checkin24hs.com | whatsapp2.checkin24hs.com |
| Puerto | 3001 | 3002 |
| Instancia | 1 | 2 |
| Servicio Swarm | checkin24hs_whatsapp | checkin24hs_whatsapp2 |
| Volumen sesión | auth_info_baileys_1 | auth_info_baileys_2 |
