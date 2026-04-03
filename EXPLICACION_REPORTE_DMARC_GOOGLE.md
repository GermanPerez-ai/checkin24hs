# Reporte DMARC de Google – Explicación y qué hacer

---

## 📋 Info para quien te guíe (copiar y pegar)

**Nombre del software de correo en el VPS:**  
No tengo mailserver en el VPS. En el VPS solo corre **Roundcube** (webmail cliente) en Docker. Roundcube se conecta por IMAP/SMTP al **servidor de correo de Hostinger** (mail.checkin24hs.com / srv1152402.hstgr.cloud). El envío real lo hace Hostinger, no el VPS. No hay docker-compose de mailserver; DKIM tendría que configurarse en el panel de Hostinger (donde está el servicio de correo), no en el VPS.

**Dominio de correo:**  
checkin24hs.com

---

## ¿Qué es este correo?

Google te envía **reportes agregados DMARC** cuando tu dominio (`checkin24hs.com`) tiene un registro DMARC en DNS. El XML que recibiste es un resumen de cómo Google evaluó los correos que **llegaron a Gmail** enviados desde tu dominio.

---

## Qué dice tu reporte

| Campo | Valor | Significado |
|-------|--------|-------------|
| **Dominio** | checkin24hs.com | Correos con `From: ...@checkin24hs.com` |
| **IP de origen** | 72.61.58.240 | Servidor que envió el correo |
| **SPF** | **pass** | Esa IP está autorizada en tu SPF → bien |
| **DKIM** | **fail** | La firma DKIM falló o no existía → hay que corregir |
| **Política publicada** | p=none | Solo monitoreo; no se rechaza nada por ahora |

En resumen: **SPF está bien; DKIM está fallando.**

---

## Por qué importa

- **SPF** dice “esta IP puede enviar por checkin24hs.com”.
- **DKIM** firma el mensaje con una clave privada; el receptor comprueba la firma con un registro DNS (clave pública). Si DKIM falla:
  - Gmail y otros pueden marcar el correo como menos fiable o spam.
  - Si más adelante pones una política DMARC estricta (`p=quarantine` o `p=reject`), esos correos podrían bloquearse.

Mientras tengas `p=none`, Google no rechaza; solo te avisa. Es el momento ideal para arreglar DKIM.

---

## Qué hacer: configurar DKIM para checkin24hs.com

En tu caso: **Roundcube es solo el cliente** (la interfaz web desde la que escribís y enviás). El correo sale realmente desde el **servidor de correo de Hostinger** (mail.checkin24hs.com / srv1152402.hstgr.cloud). Por eso **DKIM hay que configurarlo en Hostinger**, no en Roundcube ni en tu VPS.

---

### Tu caso: correo desde Roundcube → servidor Hostinger

1. **Entrá al panel de Hostinger** (hPanel).
2. Andá a **Correo** (o **Email** / **Dominios** / **Correo electrónico**).
3. Elegí el dominio **checkin24hs.com**.
4. Buscá la sección **DKIM** o **Autenticación de correo** / **Email authentication**. En Hostinger suele estar en:
   - *Correo* → *Configuración del dominio* → *DKIM*, o  
   - *Dominios* → *checkin24hs.com* → *Zona DNS* / *Configuración de correo*.
5. **Activá DKIM** para checkin24hs.com. El panel te mostrará un **registro TXT** que tenés que tener en el DNS (nombre tipo `something._domainkey.checkin24hs.com` y valor largo que empieza con `v=DKIM1; k=rsa; p=...`).
6. Si Hostinger **gestiona el DNS** de checkin24hs.com, a veces el panel agrega el registro solo al activar DKIM; si no, copiá el registro y agregalo en **Zona DNS** como registro **TXT** con el nombre y valor que indique.
7. Esperá unos minutos (o hasta 24 h según propagación) y **probá** enviando un correo desde Roundcube a Gmail y revisando el siguiente reporte DMARC, o usando [mail-tester.com](https://www.mail-tester.com) (envías un correo desde @checkin24hs.com al mail que te dan y te dice SPF/DKIM/DMARC).

---

### Comprobar

- Herramientas en línea: por ejemplo “DKIM record checker” o “mail-tester.com” (envía un correo desde tu dominio y te dice SPF/DKIM/DMARC).
- Esperar el siguiente reporte DMARC de Google (suelen ser diarios); en el XML, en `<policy_evaluated>` debería aparecer `<dkim>pass</dkim>`.

---

## Resumen

| Qué | Estado |
|-----|--------|
| Reporte | Es un reporte DMARC normal de Google (monitoreo). |
| SPF | Correcto. |
| DKIM | Fallando → hay que configurar DKIM en el servidor de correo y en DNS. |
| Acción | Activar DKIM en **Hostinger** (panel → Correo → checkin24hs.com → DKIM) y asegurar el registro TXT en el DNS. |
