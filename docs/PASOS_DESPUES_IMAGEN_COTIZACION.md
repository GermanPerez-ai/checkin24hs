# Pasos después de los cambios de imagen de cotización

## Cambios realizados

1. **WhatsApp (Flor) incrusta imagen al enviar cotización**
   - `whatsapp-server/whatsapp-server-baileys.js`: `IMAGEN_COTIZACION_URL`, `prepararMensajeFlorParaEnvio()`, envío de imagen + caption cuando la respuesta contiene el link del cotizador.
   - Variable de entorno opcional: `IMAGEN_COTIZACION_URL` (por defecto: `https://dashboard.checkin24hs.com/og-cotizar.jpg`).

2. **URL `/og-cotizar.jpg` devuelve imagen**
   - `checkin24hs-admin/public/og-cotizar.jpg`: imagen incluida en el build.
   - `checkin24hs-admin/server.js`: prioridad 0 = `build/og-cotizar.jpg`, así la ruta siempre tiene una imagen en el contenedor.

---

## Checklist para aplicar en producción

- [ ] **1. Subir cambios a Git**
  ```powershell
  cd c:\Users\German\Downloads\Checkin24hs
  git add whatsapp-server/whatsapp-server-baileys.js checkin24hs-admin/server.js checkin24hs-admin/public/og-cotizar.jpg docs/PASOS_DESPUES_IMAGEN_COTIZACION.md
  git status
  git commit -m "Imagen cotización: Flor envía imagen+caption; og-cotizar.jpg en build del dashboard"
  git push
  ```

- [ ] **2. Redeploy del Dashboard (checkin24hs-admin) en EasyPanel**
  - Rebuild de la imagen para que incluya `public/og-cotizar.jpg` en el build.
  - Redeploy del servicio del dashboard.
  - Verificar: abrir https://dashboard.checkin24hs.com/og-cotizar.jpg y confirmar que se ve la imagen.

- [ ] **3. Redeploy del servicio WhatsApp en EasyPanel**
  - Redeploy de `checkin24hs_whatsapp` para que use el nuevo código (imagen + caption en respuestas de cotización).
  - Opcional: en variables del servicio, configurar `IMAGEN_COTIZACION_URL` si querés otra URL (si no, usa la de dashboard).

- [ ] **4. Probar en WhatsApp**
  - Enviar un mensaje que dispare la respuesta de cotización (ej. "quiero cotizar").
  - Confirmar que Flor envía **una imagen** con el texto/link debajo (caption), no solo texto.

---

## Resumen

| Qué | Dónde | Acción |
|-----|--------|--------|
| Imagen en mensaje de cotización (Flor) | whatsapp-server | Redeploy servicio WhatsApp |
| URL og-cotizar.jpg con imagen | checkin24hs-admin | Rebuild + redeploy dashboard |
| Cambios en repo | Git | commit + push |

Cuando termines los tres despliegues y la prueba en WhatsApp, los cambios quedan aplicados.
