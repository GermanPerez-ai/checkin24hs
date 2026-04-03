# 🔧 Corregir Error 404 del Dominio

## Problema
El proxy funciona localmente pero `https://dashboard.checkin24hs.com/` devuelve 404.

## Causa
El dominio está configurado en el servicio incorrecto o apunta al destino incorrecto.

## Solución

### Paso 1: Verificar dónde está configurado el dominio

En EasyPanel:
1. Ve a **Servicios**
2. Busca el servicio que tiene el dominio `dashboard.checkin24hs.com` configurado
3. Anota en qué servicio está (debería ser `dashboard-proxy`, no `dashboard`)

### Paso 2: Si el dominio está en el servicio `dashboard`

**Opción A: Mover el dominio al servicio `dashboard-proxy`**

1. Ve a `dashboard` service → Pestaña "Dominios"
2. Elimina el dominio `dashboard.checkin24hs.com` (o desmárcalo como primario)
3. Ve a `dashboard-proxy` service → Pestaña "Dominios"
4. Agrega el dominio `dashboard.checkin24hs.com`
5. Verifica que el destino interno sea `http://checkin24hs_dashboard-proxy:80/` (o similar)
6. Guarda los cambios

**Opción B: Si no puedes moverlo, cambiar el destino en `dashboard`**

1. Ve a `dashboard` service → Pestaña "Dominios"
2. Edita `dashboard.checkin24hs.com`
3. Cambia el destino interno a: `http://checkin24hs_dashboard-proxy:80/`
4. Guarda los cambios

### Paso 3: Verificar configuración correcta

El dominio `dashboard.checkin24hs.com` debe estar:
- **Servicio**: `dashboard-proxy`
- **Destino interno**: `http://checkin24hs_dashboard-proxy:80/` o `http://checkin24hs-dashboard-proxy:80/`

### Paso 4: Esperar y probar

1. Espera 30-60 segundos para que Traefik se actualice
2. Abre: `https://dashboard.checkin24hs.com/`
3. Debería cargar el dashboard

---

**⚠️ IMPORTANTE**: Si EasyPanel no permite cambiar el destino interno del dominio, necesitarás eliminar el dominio del servicio `dashboard` y crearlo en el servicio `dashboard-proxy`.
