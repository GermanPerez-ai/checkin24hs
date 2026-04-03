# 🚀 Pasos Siguientes: Configurar Cotizador en EasyPanel

## ✅ Ya completado:
- ✅ DNS configurado: `cotizar.checkin24hs.com` → `72.61.58.240`

---

## 📤 PASO 1: Subir archivos al servidor

**Desde PowerShell en tu computadora:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Subir archivos necesarios
scp cotizador-cliente.html root@72.61.58.240:/root/checkin24hs/
scp supabase-config.js root@72.61.58.240:/root/checkin24hs/
scp supabase-client.js root@72.61.58.240:/root/checkin24hs/
scp Dockerfile.cotizador root@72.61.58.240:/root/checkin24hs/
```

**Espera a que termine cada comando** (puede tardar unos segundos).

---

## 🔍 PASO 2: Verificar archivos en servidor

**Conéctate al servidor:**

```bash
ssh root@72.61.58.240
```

**Verifica que los archivos estén:**

```bash
cd /root/checkin24hs
ls -la cotizador-cliente.html
ls -la supabase-config.js
ls -la supabase-client.js
ls -la Dockerfile.cotizador
```

**Todos deben aparecer con sus tamaños y fechas.**

---

## 🎛️ PASO 3: Crear servicio en EasyPanel

1. **Accede a EasyPanel:**
   - **Opción A:** Si tienes un subdominio configurado:
     - `http://panel.checkin24hs.com`
     - `http://easypanel.checkin24hs.com`
     - `http://admin.checkin24hs.com`
   - **Opción B:** Si conoces otro puerto (no 3000, ese lo usa el dashboard):
     - `http://72.61.58.240:8080`
     - `http://72.61.58.240:3001`
   - **Opción C:** Si no sabes el puerto, verifica desde SSH:
     ```bash
     ssh root@72.61.58.240
     sudo netstat -tulpn | grep LISTEN | grep -E "(8080|3001|easypanel)"
     docker ps | grep easypanel
     ```
   - Inicia sesión

2. **Crear nuevo servicio:**
   - Clic en **"Nuevo Servicio"** o **"+"** (botón verde)
   - Selecciona **"Aplicación Estática"** o **"Static Site"**

3. **Configurar el servicio:**
   - **Nombre del servicio:** `cotizador`
   - **Build Path:** `/root/checkin24hs`
   - **Dockerfile:** `Dockerfile.cotizador` (o selecciona el archivo)
   - **Puerto:** `80`
   - **Variables de entorno:** (no necesarias por ahora)

4. **Guardar y construir:**
   - Clic en **"Guardar"** o **"Deploy"**
   - EasyPanel construirá la imagen Docker automáticamente
   - Espera a que termine el build (puede tardar 1-2 minutos)

---

## 🌐 PASO 4: Agregar dominio en EasyPanel

1. **Ir al servicio creado:**
   - En EasyPanel, busca el servicio `cotizador` en la lista
   - Haz clic en él

2. **Ir a la pestaña "Dominios":**
   - En el menú lateral, clic en **"Dominios"** o **"Domains"**

3. **Agregar dominio:**
   - Clic en **"Agregar dominio"** o **"+"** o **"Add Domain"**
   - Ingresa: `cotizar.checkin24hs.com`
   - **HTTPS:** ✅ Habilitado (Traefik generará certificado SSL automáticamente)
   - Guarda los cambios

4. **Esperar configuración automática:**
   - Traefik detectará el nuevo dominio (1-2 minutos)
   - Generará certificado SSL con Let's Encrypt (puede tardar 2-3 minutos)
   - El servicio estará disponible

---

## ✅ PASO 5: Verificar que funciona

### Desde el navegador:

1. **Espera 2-3 minutos** después de agregar el dominio
2. **Accede a:** `https://cotizar.checkin24hs.com`
3. **Verifica:**
   - ✅ El formulario se carga correctamente
   - ✅ Los hoteles se cargan desde Supabase
   - ✅ El teléfono se autocompleta desde URL (prueba: `?phone=+54912345678&name=Juan`)

### Desde el servidor (opcional):

```bash
# Ver servicios de Docker
docker ps | grep cotizador

# Ver logs del servicio
docker logs cotizador --tail 50

# Verificar que Traefik detectó el dominio
docker logs traefik --tail 100 | grep cotizar
```

---

## 🆘 Si algo no funciona

### El servicio no se crea:
- Verifica que los archivos estén en `/root/checkin24hs/`
- Verifica que el Dockerfile se llama exactamente `Dockerfile.cotizador`

### El dominio no funciona:
- Verifica DNS: `nslookup cotizar.checkin24hs.com` (debe devolver `72.61.58.240`)
- Espera 2-3 minutos más (Traefik puede tardar)
- Verifica logs de Traefik: `docker logs traefik --tail 100`

### Error 404 o página no encontrada:
- Verifica que el servicio esté corriendo: `docker ps | grep cotizador`
- Verifica logs del servicio: `docker logs cotizador --tail 50`
- Reinicia el servicio desde EasyPanel

---

## 📝 Resumen rápido

1. ✅ **Subir archivos** al servidor (scp)
2. ✅ **Verificar archivos** en servidor (ls -la)
3. ✅ **Crear servicio** en EasyPanel
4. ✅ **Agregar dominio** `cotizar.checkin24hs.com` en EasyPanel
5. ✅ **Verificar** que funciona en el navegador

---

**¿Listo para empezar?** Comienza con el PASO 1 (subir archivos).
