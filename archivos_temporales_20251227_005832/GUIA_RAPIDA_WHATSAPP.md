# Guía Rápida: Crear WhatsApp en EasyPanel

## ⚡ Configuración Rápida

### Para cada servicio (whatsapp1, whatsapp2, whatsapp3, whatsapp4):

**1. EasyPanel → New Service → App → GitHub**

**2. Configuración básica:**
- Repository: `checkin24hs`
- Branch: `main`
- Source Directory: `/whatsapp-server`
- Service Name: `whatsapp1` (o 2, 3, 4)
- Port: `3001` (o 3002, 3003, 3004)
- Command: `node whatsapp-server.js`

**3. Variables de Entorno:**
```
INSTANCE_NUMBER=1
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**4. Red:**
- Asegúrate de estar en la red `easypanel`

**5. Crear**

---

## 📋 Tabla de Configuración

| Servicio | Puerto | INSTANCE_NUMBER | Dominio |
|----------|--------|-----------------|---------|
| whatsapp1 | 3001 | 1 | whatsapp1.checkin24hs.com |
| whatsapp2 | 3002 | 2 | whatsapp2.checkin24hs.com |
| whatsapp3 | 3003 | 3 | whatsapp3.checkin24hs.com |
| whatsapp4 | 3004 | 4 | whatsapp4.checkin24hs.com |

---

## ✅ Después de Crear

1. Verificar servicios: `docker service ls | grep whatsapp`
2. Configurar Traefik: `bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh`
3. Configurar DNS: Agregar registros A para los 4 dominios






