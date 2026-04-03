# 🔧 Configurar Servicio Sin NGINX (Usando Traefik)

## Si No Tienes Opción NGINX

EasyPanel está usando **Traefik** directamente, no NGINX dentro del contenedor. Necesitas configurar las rutas de manera diferente.

## Opción 1: Usar Servicio Tipo "Proxy" o "Aplicación"

### Paso 1: Crear Servicio Básico

1. En "Fuente", usa **"Imagen Docker"** con: `nginx:alpine`
2. O usa **"Dockerfile"** y crea uno básico
3. Guarda y continúa

### Paso 2: Configurar Dominio con Rutas

1. Ve a la pestaña **"Dominios"**
2. Agrega el dominio: `configwp.checkin24hs.com`
3. Configura:
   - **HTTPS:** Habilitado
   - **Host:** `configwp.checkin24hs.com`
   - **Ruta:** `/api1/` (para la primera ruta)
   - **Destino:**
     - Protocolo: HTTP
     - Puerto: 4001
     - Ruta: `/`

4. **Repite para cada ruta:**
   - Agrega otro dominio/ruta: `/api2/` → Puerto 4002
   - Agrega otro dominio/ruta: `/api3/` → Puerto 4003
   - Agrega otro dominio/ruta: `/api4/` → Puerto 4004

---

## Opción 2: Configurar Rutas en Variables de Entorno

Si EasyPanel permite configurar rutas mediante variables de entorno o etiquetas:

1. Ve a la pestaña **"Entorno"** o **"Environment"**
2. Agrega variables de entorno relacionadas con Traefik:
   - `TRAEFIK_HTTP_ROUTERS_API1_RULE=Host(\`configwp.checkin24hs.com\`) && PathPrefix(\`/api1/\`)`
   - `TRAEFIK_HTTP_SERVICES_API1_LOADBALANCER_SERVER_PORT=4001`
   - (Repite para api2, api3, api4)

---

## Opción 3: Usar Servicio Separado para Cada Ruta

Si ninguna de las opciones anteriores funciona:

1. Crea **4 servicios separados**:
   - `whatsapp-api-1` → Dominio: `configwp.checkin24hs.com`, Ruta: `/api1/`, Puerto: 4001
   - `whatsapp-api-2` → Dominio: `configwp.checkin24hs.com`, Ruta: `/api2/`, Puerto: 4002
   - `whatsapp-api-3` → Dominio: `configwp.checkin24hs.com`, Ruta: `/api3/`, Puerto: 4003
   - `whatsapp-api-4` → Dominio: `configwp.checkin24hs.com`, Ruta: `/api4/`, Puerto: 4004

---

## Verificar Qué Opciones Tienes

Dime qué pestañas/opciones ves en EasyPanel para el servicio `whatsapp-api`:

1. ¿Tienes pestaña **"Rutas"** o **"Proxy Routes"**?
2. ¿Tienes pestaña **"Entorno"** o **"Environment"**?
3. ¿Puedes agregar múltiples dominios/rutas en la pestaña **"Dominios"**?
4. ¿Qué otras pestañas/opciones ves además de "Fuente", "Dominios"?

Con esta información podremos configurarlo correctamente.


