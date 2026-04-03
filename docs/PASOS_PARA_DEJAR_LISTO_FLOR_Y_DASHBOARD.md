# Pasos para dejar listo Flor IA + Dashboard (archivos por temporada, PDF, cotización)

Seguí este orden para que los cambios queden activos en el servidor y en el dashboard.

---

## 1. Subir cambios a GitHub (en tu PC)

```bash
cd C:\Users\German\Downloads\Checkin24hs
git add whatsapp-server/whatsapp-server-baileys.js dashboard.html deploy/dashboard.html docs/PASOS_PARA_DEJAR_LISTO_FLOR_Y_DASHBOARD.md
git status
git commit -m "Flor: solo PDF o texto (sin imagen), cotización con emojis, tabla verano/invierno"
git push origin main
```

---

## 2. Actualizar el servicio WhatsApp en el servidor

Conectado por SSH al servidor:

```bash
cd ~/checkin24hs
git pull origin main
cd whatsapp-server
docker build --no-cache -t easypanel/checkin24hs/whatsapp:latest .
docker service update --image easypanel/checkin24hs/whatsapp:latest --force checkin24hs_whatsapp
```

Esperá 1–2 minutos a que el servicio arranque.

**Si el servicio se construye desde EasyPanel (GitHub):** después del `git push`, en EasyPanel → proyecto → app **WhatsApp** → **Implementar / Redeploy**.

---

## 3. Actualizar el dashboard en el servidor

- Si el dashboard se sirve desde **deploy/dashboard.html** (por ejemplo con Docker/Nginx), copiá el `dashboard.html` actualizado a `deploy/` y volvé a desplegar el dashboard (o hacé pull + rebuild según tu flujo).
- Documentación de referencia: [ACTUALIZAR_DASHBOARD_EN_SERVIDOR.md](ACTUALIZAR_DASHBOARD_EN_SERVIDOR.md).

---

## 4. Revisar en el dashboard (opcional)

- Entrá a **Hoteles** → Editar un hotel → **Ficha Flor**.
- Confirmá que ves la tabla **Verano / Invierno** (Spa, Carta restaurante, Excursiones, Instagram).
- Si antes tenías datos en los 6 campos viejos, al abrir el hotel se cargan en los nuevos (ej. PDF menú spa → Spa Verano). Guardá de nuevo si hiciste cambios.

---

## 5. Probar en WhatsApp

- **PDF:** Pedile a Flor info de un hotel (ej. menú spa). Cuando pregunte “¿En PDF o por texto?”, elegí **PDF**. Deberías recibir el archivo como documento (no como link).
- **Cotización:** Pedí cotización o precio. El mensaje con el link de cotizar debería salir con emojis (💰 📋) al inicio, sin carácter raro (rombo con signo de preguntas).

---

## Resumen de cambios aplicados

| Cambio | Dónde |
|--------|--------|
| Opciones Flor: solo **PDF o texto** (sin imagen) | Prompt/reglas en `whatsapp-server-baileys.js` |
| Cotización con emojis (💰 📋) en vez de carácter raro | Función `añadirEmojiMensaje` en el servidor |
| Tabla Verano/Invierno en Ficha Flor | `dashboard.html` y `deploy/dashboard.html` |
| Flor envía PDF como documento | Herramienta `enviarDocumentoPorWhatsApp` + descarga y envío en el servidor |
