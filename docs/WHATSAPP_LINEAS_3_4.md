# WhatsApp Líneas 3 y 4 — Infra lista (sin número aún)

Mismo patrón que Línea 2: un servicio Swarm por línea, Flor compartida, chats filtrados por pestaña en el dashboard.

---

## 1. DNS (cuando tengas los números)

Creá registros **A** al mismo servidor que `whatsapp.checkin24hs.com`:

| Host | Puerto | Instancia |
|------|--------|-----------|
| `whatsapp3.checkin24hs.com` | 3003 | 3 |
| `whatsapp4.checkin24hs.com` | 3004 | 4 |

Podés crear el DNS **antes** de tener el chip: el servicio arranca y muestra QR cuando esté listo.

---

## 2. Servidor — desplegar

```bash
cd /root/checkin24hs
git pull origin main

# Línea 3
bash scripts/deploy_whatsapp_linea_servidor.sh 3

# Línea 4
bash scripts/deploy_whatsapp_linea_servidor.sh 4

# Traefik para las 4 líneas
bash scripts/aplicar_traefik_whatsapp_ambos.sh
```

También podés redeployar L2 con el script genérico:

```bash
bash scripts/deploy_whatsapp_linea_servidor.sh 2
```

Cada línea usa:

| | L3 | L4 |
|---|----|----|
| Servicio | `checkin24hs_whatsapp3` | `checkin24hs_whatsapp4` |
| Volumen sesión | `whatsapp3-auth` → `auth_info_baileys_3` | `whatsapp4-auth` → `auth_info_baileys_4` |
| `INSTANCE_NUMBER` | 3 | 4 |

**Un número = una línea.** No reutilices el mismo chip en dos líneas.

---

## 3. Dashboard

Tras deploy del dashboard (Build ≥ 182):

- **Chats Activos** → pestañas **Línea 1** … **Línea 4**
- **Flor IA → WhatsApp** → estado y QR de cada línea

Config en `DASHBOARD_CONFIG.whatsappInstances`:

```javascript
whatsappInstances: [
  { instance: 1, label: 'Línea 1', url: 'https://whatsapp.checkin24hs.com' },
  { instance: 2, label: 'Línea 2', url: 'https://whatsapp2.checkin24hs.com' },
  { instance: 3, label: 'Línea 3', url: 'https://whatsapp3.checkin24hs.com' },
  { instance: 4, label: 'Línea 4', url: 'https://whatsapp4.checkin24hs.com' }
]
```

Proxy interno en el dashboard (`/api/whatsapp-status/3`, `/api/whatsapp-qr/4`, etc.).

---

## 4. Cuando tengas los números

1. DNS activo para `whatsapp3` / `whatsapp4`
2. Deploy de la línea correspondiente (comandos arriba)
3. **Flor IA → WhatsApp** → **Abrir QR Línea 3/4** y escanear con el chip nuevo
4. Probar un mensaje y verificar la pestaña correcta en **Chats Activos**

---

## 5. Resumen completo (4 líneas)

| | L1 | L2 | L3 | L4 |
|---|----|----|----|-----|
| Dominio | whatsapp.checkin24hs.com | whatsapp2… | whatsapp3… | whatsapp4… |
| Puerto | 3001 | 3002 | 3003 | 3004 |
| Servicio | checkin24hs_whatsapp | checkin24hs_whatsapp2 | checkin24hs_whatsapp3 | checkin24hs_whatsapp4 |
