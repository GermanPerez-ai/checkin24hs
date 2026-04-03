# 🔄 Actualizar Dashboard para HTTPS

**Ejecuta esto DESPUÉS de configurar HTTPS en EasyPanel**

---

## 📋 Cambios Necesarios

Necesitamos modificar el código para que use los subdominios HTTPS correctos según la tarjeta:

- **Tarjeta 1** → `https://api1.checkin24hs.com`
- **Tarjeta 2** → `https://api2.checkin24hs.com`
- **Tarjeta 3** → `https://api3.checkin24hs.com`
- **Tarjeta 4** → `https://api4.checkin24hs.com`

---

## ✅ Pasos

1. **Configura HTTPS en EasyPanel** (ver `GUIA_HTTPS_EASYPANEL_PASO_A_PASO.md`)
2. **Verifica que HTTPS funciona** (abre los enlaces en el navegador)
3. **Ejecuta el script de actualización** (te lo daré cuando termines)
4. **Actualiza la configuración en el dashboard**:
   - Ve a **Flor IA** → **WhatsApp** → **⚙️ Configurar Servidor**
   - Cambia la URL base a: `https://api1.checkin24hs.com` (o cualquier subdominio, el código detectará automáticamente)

---

## 🎯 Lo que hará el script

El script modificará las funciones para que:

1. **Detecte automáticamente** si la URL base es HTTPS y tiene un dominio
2. **Use el subdominio correcto** según la tarjeta (api1, api2, api3, api4)
3. **Mantenga compatibilidad** con URLs HTTP o IPs si es necesario

---

**Cuando termines de configurar HTTPS en EasyPanel, avísame y te doy el script de actualización.**









