# Puertos para Dominios en EasyPanel

## 📋 Respuesta Rápida

**NO necesitas especificar el puerto** cuando agregas el dominio personalizado en EasyPanel. EasyPanel usa automáticamente el puerto que ya está configurado en cada servicio.

---

## 🔧 Cómo Funciona

Cuando agregas un dominio personalizado en EasyPanel:

1. **EasyPanel detecta automáticamente** el puerto del servicio
2. **Traefik configura** el enrutamiento automáticamente
3. **No necesitas escribir el puerto** en el campo del dominio

---

## 📊 Puertos Internos de Cada Servicio

Estos son los puertos que **ya están configurados** en cada servicio:

| Servicio | Puerto Interno | Dominio a Agregar |
|----------|---------------|-------------------|
| whatsapp1 | **3001** | `whatsapp1.checkin24hs.com` |
| whatsapp2 | **3002** | `whatsapp2.checkin24hs.com` |
| whatsapp3 | **3003** | `whatsapp3.checkin24hs.com` |
| whatsapp4 | **3004** | `whatsapp4.checkin24hs.com` |

---

## 🎯 Qué Escribir en el Campo "Agregar Dominio"

Cuando hagas clic en "Agregar dominio", solo escribe:

```
whatsapp1.checkin24hs.com
```

**NO escribas:**
- ❌ `whatsapp1.checkin24hs.com:3001` (incorrecto)
- ❌ `http://whatsapp1.checkin24hs.com` (incorrecto)
- ❌ `https://whatsapp1.checkin24hs.com` (incorrecto)

**Solo escribe:**
- ✅ `whatsapp1.checkin24hs.com` (correcto)

---

## 🔍 Verificar Puertos en EasyPanel

Si quieres verificar qué puerto tiene configurado cada servicio:

1. **Ve al servicio** (ej: whatsapp1)
2. **Clic en "Recursos"** o **"Resources"** en el menú lateral
3. **Busca "Puerto"** o **"Port"** - debería mostrar `3001`, `3002`, `3003`, o `3004`

O también puedes verificar desde el servidor:

```bash
# Ver puerto de whatsapp1
docker service inspect checkin24hs_whatsapp1 --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}{{end}}'

# Ver puerto de whatsapp2
docker service inspect checkin24hs_whatsapp2 --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}{{end}}'

# Ver puerto de whatsapp3
docker service inspect checkin24hs_whatsapp3 --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}{{end}}'

# Ver puerto de whatsapp4
docker service inspect checkin24hs_whatsapp4 --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}{{end}}'
```

---

## ⚙️ Cómo Traefik Maneja los Puertos

Cuando agregas el dominio `whatsapp1.checkin24hs.com` en EasyPanel:

1. **EasyPanel configura Traefik** con:
   - Dominio: `whatsapp1.checkin24hs.com`
   - Puerto interno: `3001` (lo detecta automáticamente del servicio)

2. **Traefik enruta:**
   - `https://whatsapp1.checkin24hs.com` → `checkin24hs_whatsapp1:3001`

3. **El usuario accede:**
   - `https://whatsapp1.checkin24hs.com` (puerto 443 HTTPS, automático)
   - Traefik redirige internamente al puerto 3001

---

## 📝 Resumen

**Al agregar dominio en EasyPanel:**

1. **Solo escribe el dominio:** `whatsapp1.checkin24hs.com`
2. **NO especifiques puerto:** EasyPanel lo detecta automáticamente
3. **NO agregues http/https:** EasyPanel lo maneja automáticamente
4. **Guarda:** EasyPanel configurará Traefik automáticamente

**Los puertos ya están configurados:**
- whatsapp1 → 3001
- whatsapp2 → 3002
- whatsapp3 → 3003
- whatsapp4 → 3004

---

## ✅ Ejemplo Visual

Cuando hagas clic en "Agregar dominio", verás un campo como:

```
┌─────────────────────────────────────┐
│ Agregar dominio                     │
├─────────────────────────────────────┤
│ [whatsapp1.checkin24hs.com    ] [✓]│ ← Solo escribe esto
└─────────────────────────────────────┘
```

**NO escribas:**
```
[whatsapp1.checkin24hs.com:3001]  ← Incorrecto
[http://whatsapp1.checkin24hs.com] ← Incorrecto
```

---

## 🎯 Pasos Finales

1. **WhatsApp 1:** Agrega dominio `whatsapp1.checkin24hs.com` (puerto 3001 automático)
2. **WhatsApp 2:** Agrega dominio `whatsapp2.checkin24hs.com` (puerto 3002 automático)
3. **WhatsApp 3:** Agrega dominio `whatsapp3.checkin24hs.com` (puerto 3003 automático)
4. **WhatsApp 4:** Agrega dominio `whatsapp4.checkin24hs.com` (puerto 3004 automático)

**¡Eso es todo!** EasyPanel y Traefik se encargan del resto automáticamente.


















