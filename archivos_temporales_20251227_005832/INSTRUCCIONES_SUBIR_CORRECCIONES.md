# 📋 Instrucciones para Subir Correcciones de WhatsApp

## ✅ Archivos Corregidos (Listos para Subir)

Los siguientes archivos han sido corregidos y están listos en la carpeta `deploy/`:

1. ✅ `deploy/crm.html` - Eliminadas referencias a WhatsApp
2. ✅ `deploy/crm.js` - Eliminadas funciones de WhatsApp
3. ✅ `deploy/dashboard.html` - Eliminadas referencias a WhatsApp

---

## 🚀 Opción 1: Subir Manualmente con PowerShell

### Paso 1: Subir los archivos

Abre PowerShell y ejecuta:

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Subir archivos
scp deploy\crm.html root@72.61.58.240:/root/checkin24hs/deploy/crm.html
scp deploy\crm.js root@72.61.58.240:/root/checkin24hs/deploy/crm.js
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

# Subir script de aplicación
scp APLICAR_CORRECCIONES_WHATSAPP.sh root@72.61.58.240:/root/checkin24hs/
```

### Paso 2: Conectarse al servidor y aplicar cambios

```powershell
ssh root@72.61.58.240
```

Una vez conectado, ejecuta:

```bash
cd /root/checkin24hs
chmod +x APLICAR_CORRECCIONES_WHATSAPP.sh
bash APLICAR_CORRECCIONES_WHATSAPP.sh
```

---

## 🚀 Opción 2: Usar WinSCP (Más Fácil)

### Paso 1: Conectar con WinSCP

1. Abre WinSCP
2. Conecta a:
   - **Host:** `72.61.58.240`
   - **Usuario:** `root`
   - **Contraseña:** (tu contraseña)
   - **Protocolo:** SFTP

### Paso 2: Subir archivos

1. Navega a `/root/checkin24hs/deploy/` en el servidor
2. Arrastra estos archivos desde tu máquina local:
   - `deploy/crm.html`
   - `deploy/crm.js`
   - `deploy/dashboard.html`
3. Arrastra `APLICAR_CORRECCIONES_WHATSAPP.sh` a `/root/checkin24hs/`

### Paso 3: Aplicar cambios

Conéctate por SSH y ejecuta:

```bash
cd /root/checkin24hs
chmod +x APLICAR_CORRECCIONES_WHATSAPP.sh
bash APLICAR_CORRECCIONES_WHATSAPP.sh
```

---

## 🔍 Verificar que Funcionó

Después de aplicar los cambios:

1. **Abre en el navegador:**
   - https://crm.checkin24hs.com/
   - https://dashboard.checkin24hs.com/

2. **Limpia la caché:**
   - Presiona `Ctrl + Shift + R` (hard refresh)
   - O abre en modo incógnito (`Ctrl + Shift + N`)

3. **Abre la consola del navegador (F12):**
   - Verifica que NO aparezcan errores de Mixed Content
   - Verifica que NO aparezcan errores de `whatsapp.checkin24hs.com`

---

## ✅ Cambios Realizados

### En `crm.html`:
- ✅ Eliminada pestaña "📱 WhatsApp"
- ✅ Eliminada sección completa de WhatsApp con 4 iframes HTTP

### En `crm.js`:
- ✅ Eliminadas funciones:
  - `loadWhatsAppConfig()`
  - `saveWhatsAppConfig()`
  - `checkWhatsAppConnection()`
  - `disconnectWhatsApp()`
  - `loadWhatsAppStats()`
- ✅ Comentada llamada en `showFlorTab()`

### En `dashboard.html`:
- ✅ Eliminada pestaña "📱 WhatsApp"
- ✅ Eliminada sección completa de WhatsApp con 4 iframes
- ✅ Modificada función `getServerURL()` para evitar generar puertos 3001-3004
- ✅ Eliminadas URLs por defecto `http://72.61.58.240`

---

## 🆘 Si Hay Problemas

### Error: "No se encontró contenedor"

Si el script dice que no encontró contenedores, verifica manualmente:

```bash
# Ver contenedores Docker
docker ps

# Ver servicios PM2
pm2 list
```

### Error: "No se pudo copiar archivo"

Verifica que los archivos estén en `/root/checkin24hs/deploy/`:

```bash
ls -lh /root/checkin24hs/deploy/crm.html
ls -lh /root/checkin24hs/deploy/crm.js
ls -lh /root/checkin24hs/deploy/dashboard.html
```

### Los errores persisten

1. **Verifica qué archivo se está sirviendo:**
   - Revisa la configuración de Nginx o el contenedor Docker
   - Verifica que esté apuntando a los archivos correctos

2. **Limpia la caché del navegador completamente:**
   - Abre las herramientas de desarrollador (F12)
   - Ve a Application → Clear Storage → Clear site data

3. **Verifica que los archivos se hayan copiado correctamente:**
   ```bash
   # Dentro del contenedor
   docker exec -it <nombre_contenedor> ls -lh /usr/share/nginx/html/crm.html
   ```

---

## 📝 Notas

- Los archivos corregidos están en `deploy/` en tu máquina local
- El script `APLICAR_CORRECCIONES_WHATSAPP.sh` aplicará los cambios automáticamente
- Si no hay contenedores Docker, el script verificará servicios PM2
- Después de aplicar cambios, limpia la caché del navegador




