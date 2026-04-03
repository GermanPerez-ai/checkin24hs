# 🚀 Configurar EasyPanel para usar Dockerfile

## ✅ Dockerfile subido a GitHub

Ahora necesitas configurar EasyPanel para que use el Dockerfile en lugar de Nixpacks.

---

## 📋 Pasos para cada servicio WhatsApp

Necesitas hacer esto para **TODOS** los servicios:
- `whatsapp` (tarjeta 1)
- `whatsapp2` (tarjeta 2)
- `whatsapp3` (tarjeta 3)
- `whatsapp4` (tarjeta 4)

---

## 🔧 Para cada servicio:

### 1. Ve a EasyPanel → Servicios → [nombre del servicio]

### 2. Ve a la pestaña "Fuente" o "Source"

### 3. Ve a "Compilación" o "Build"

### 4. Cambia la configuración:

**ANTES (Nixpacks):**
- Tipo de build: `Nixpacks`
- Paquetes Nix: (puede tener algo)
- Paquetes APT: (puede tener algo)
- Comando de instalación: (puede tener algo)

**DESPUÉS (Dockerfile):**
- ✅ **Tipo de build**: `Dockerfile`
- ✅ **Ruta del Dockerfile**: `whatsapp-server/Dockerfile`
- ✅ **Paquetes Nix**: (vacío - elimina todo)
- ✅ **Paquetes APT**: (vacío - elimina todo)
- ✅ **Comando de instalación**: (vacío - elimina todo)

### 5. Guarda los cambios

### 6. Haz clic en "Implementar" o "Deploy"

---

## ⏱️ Tiempo de compilación

La primera vez puede tardar **5-10 minutos** porque:
- Descarga la imagen base de Node.js
- Instala Chromium y todas las dependencias
- Instala paquetes npm
- Descarga Chromium con Puppeteer (fallback)

---

## ✅ Verificación después del despliegue

### 1. Espera a que el servicio esté en estado "Verde" (Running)

### 2. Verifica los logs:

En EasyPanel → Servicios → [servicio] → "Logs"

**Busca estos mensajes:**
- ✅ `✅ Cliente de Supabase inicializado correctamente`
- ✅ `✅ WhatsApp Web.js inicializado`
- ✅ `✅ Servidor escuchando en puerto 3001` (o 3002, 3003, 3004 según la tarjeta)

**NO deberías ver:**
- ❌ `Error: Could not find expected browser (chrome)`
- ❌ `Chromium not found`

### 3. Prueba el endpoint HTTPS:

Abre en tu navegador:
- `https://api1.checkin24hs.com/api/status?card=1` (para whatsapp)
- `https://api2.checkin24hs.com/api/status?card=2` (para whatsapp2)
- `https://api3.checkin24hs.com/api/status?card=3` (para whatsapp3)
- `https://api4.checkin24hs.com/api/status?card=4` (para whatsapp4)

**Deberías ver:**
```json
{
  "status": "disconnected",
  "card": 1,
  "message": "WhatsApp no está conectado"
}
```

---

## 🔄 Si hay errores

### Error: "Dockerfile not found"
- Verifica que la ruta sea exactamente: `whatsapp-server/Dockerfile`
- Asegúrate de que el Dockerfile esté en la rama `main` de GitHub

### Error: "Build failed"
- Revisa los logs de compilación en EasyPanel
- Verifica que GitHub esté accesible desde EasyPanel

### Error: "Chromium not found" (después del despliegue)
- Revisa los logs del contenedor
- Verifica que el Dockerfile tenga la línea 81: `RUN npx puppeteer browsers install chrome`

---

## 📝 Nota importante

**Haz esto para TODOS los servicios WhatsApp** antes de probar en el dashboard.

---

**¿Ya configuraste los servicios en EasyPanel?**








