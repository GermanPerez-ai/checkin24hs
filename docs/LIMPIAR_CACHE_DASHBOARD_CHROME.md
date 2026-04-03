# Ver Build #81 en navegador normal (Chrome)

Si en **incógnito** ves Build #81 pero en **navegador normal** sigue apareciendo Build #80, el navegador tiene guardada la versión antigua. Hay que borrar la caché **solo de ese sitio**.

---

## Opción 1: Borrar datos del sitio (recomendado)

1. Abrí Chrome **normal** (no incógnito).
2. Entrá a **https://dashboard.checkin24hs.com**.
3. Hacé clic en el **candado** (o el ícono a la izquierda de la URL) en la barra de direcciones.
4. Clic en **“Configuración del sitio”** o **“Site settings”**.
5. En **“Permisos”** o **“Almacenamiento”**, buscá **“Borrar datos”** / **“Clear data”** y hacé clic para borrar **solo** los datos de este sitio (caché, cookies, etc.).

O por DevTools:

1. Con la pestaña de **dashboard.checkin24hs.com** abierta, abrí **DevTools** (F12).
2. Andá a la pestaña **Application** (o **Aplicación**).
3. En el menú izquierdo, en **“Storage”** / **“Almacenamiento”**, hacé clic en **“Clear site data”** / **“Borrar datos del sitio”**.
4. Cerrá DevTools y recargá la página con **Ctrl+Shift+R**.

Después de eso deberías ver **Build #81** en navegador normal.

---

## Opción 2: Recarga forzada con DevTools abierto

1. Abrí una **pestaña nueva** en Chrome normal.
2. **Antes** de escribir la URL, abrí **DevTools** (F12).
3. Andá a la pestaña **Network** / **Red**.
4. Marcá **“Disable cache”**.
5. **Ahora** escribí **https://dashboard.checkin24hs.com** y Enter (o recargá si ya estaba abierta).
6. Deberías ver Build #81.

(“Disable cache” solo evita caché en las peticiones que se hacen **después** de marcarlo; por eso hay que tenerlo marcado **antes** de cargar la página.)

---

## Para adelante

El servidor ya envía cabeceras para no cachear el HTML. Después de borrar los datos del sitio una vez, en navegador normal no debería volver a quedar trabado en Build #80. Si en el futuro ves un build viejo, repetí “Borrar datos del sitio” solo para dashboard.checkin24hs.com.
