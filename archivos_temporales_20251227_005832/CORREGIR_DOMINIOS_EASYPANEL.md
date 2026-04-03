# 🔧 Corregir Dominios en EasyPanel

## Problema Identificado

Los dominios están configurados para apuntar directamente a:
- `checkin24hs_whatsapp-api:4001`
- `checkin24hs_whatsapp-api:4002`
- etc.

Pero esos servicios **NO existen en Docker Swarm**. Los servicios WhatsApp están corriendo directamente en el host (`127.0.0.1:4001-4004`).

## Solución

**Todos los dominios deben apuntar al contenedor NGINX (puerto 80)**, y NGINX se encargará de enrutar internamente a los puertos correctos.

---

## Pasos para Corregir

### Paso 1: Eliminar Dominios Incorrectos

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api** → **Dominios**
2. **Elimina** estos dominios (haz clic en el icono de basura):
   - `https://configwp.checkin24hs.com/api1/` → `checkin24hs_whatsapp-api:4001`
   - `https://configwp.checkin24hs.com/api2/` → `checkin24hs_whatsapp-api:4002`
   - `https://configwp.checkin24hs.com/api3/` → `checkin24hs_whatsapp-api:4003`
   - `https://configwp.checkin24hs.com/api4/` → `checkin24hs_whatsapp-api:4004`

---

### Paso 2: Configurar Dominio Principal Correctamente

1. **Edita** el dominio `https://configwp.checkin24hs.com/` (haz clic en el icono de editar)
2. Verifica que esté configurado así:
   - **Host:** `configwp.checkin24hs.com`
   - **Ruta:** `/` (o deja vacío)
   - **Destino:**
     - Protocolo: HTTP
     - Puerto: **80** (puerto del contenedor NGINX)
     - Ruta: `/`
3. **Guarda**

---

### Paso 3: Verificar SSL

1. En el mismo dominio, ve a la pestaña **"SSL"**
2. Verifica que:
   - Resolutor de certificados: `letsencrypt`
   - Dominio comodín: **Deshabilitado** (toggle apagado)
3. **Guarda**

---

### Paso 4: Esperar y Probar

1. Espera 30-60 segundos para que Traefik actualice la configuración
2. Prueba las rutas:

```bash
curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1
curl -k https://configwp.checkin24hs.com/api2/api/qr?card=2
curl -k https://configwp.checkin24hs.com/api3/api/qr?card=3
curl -k https://configwp.checkin24hs.com/api4/api/qr?card=4
```

---

## Cómo Funciona Ahora

1. **Traefik** recibe la petición en `https://configwp.checkin24hs.com/api1/...`
2. **Traefik** enruta al contenedor NGINX (puerto 80)
3. **NGINX** (dentro del contenedor) recibe la petición en `/api1/`
4. **NGINX** hace proxy a `172.18.0.1:4001` (servicio WhatsApp en el host)
5. **Servicio WhatsApp** responde con el QR code

---

## Resumen

- ❌ **Eliminar:** Dominios que apuntan a puertos 4001-4004 directamente
- ✅ **Mantener:** Solo el dominio principal `configwp.checkin24hs.com/` apuntando a puerto 80
- ✅ **NGINX** se encarga del enrutamiento interno

¡Sigue estos pasos y debería funcionar! 🎉


