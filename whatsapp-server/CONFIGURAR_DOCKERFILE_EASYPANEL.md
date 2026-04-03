# 🐳 Configurar EasyPanel para usar Dockerfile

## ✅ Paso 1: Subir el Dockerfile al servidor

El Dockerfile ya está actualizado. Necesitas asegurarte de que esté en el repositorio o en el servidor donde EasyPanel lo pueda leer.

---

## 🔧 Paso 2: Configurar EasyPanel para usar Dockerfile

### Opción A: Si EasyPanel está conectado a Git

1. **Sube el Dockerfile al repositorio Git**:
   ```bash
   git add whatsapp-server/Dockerfile
   git commit -m "Actualizar Dockerfile para WhatsApp server"
   git push
   ```

2. **En EasyPanel**:
   - Ve a **Servicios** → **`whatsapp`**
   - Ve a **"Fuente"** → **"Repositorio"**
   - Haz clic en **"Sincronizar"** o **"Actualizar"**

### Opción B: Si EasyPanel está usando código local del servidor

1. **Sube el Dockerfile al servidor**:
   ```bash
   scp whatsapp-server/Dockerfile root@72.61.58.240:/root/checkin24hs/whatsapp-server/Dockerfile
   ```

---

## ⚙️ Paso 3: Cambiar el tipo de build en EasyPanel

1. **Ve a EasyPanel** → **Servicios** → **`whatsapp`**

2. **Ve a "Fuente"** → **"Compilación"**

3. **Busca la opción "Tipo de build"** o **"Buildpack"**:
   - Debe estar en **"Nixpacks"** o **"Auto-detect"**
   - **Cámbialo a "Dockerfile"**

4. **Si no ves la opción "Tipo de build"**:
   - Busca **"Ruta del Dockerfile"** o **"Dockerfile path"**
   - Asegúrate de que esté en: `whatsapp-server/Dockerfile` o `./Dockerfile`

5. **Elimina o vacía estos campos** (ya no son necesarios con Dockerfile):
   - **Paquetes Nix**: Vacío
   - **Paquetes APT**: Vacío (el Dockerfile ya los instala)
   - **Comando de instalación**: Vacío (el Dockerfile ya lo hace)

6. **Guarda los cambios**

---

## 🚀 Paso 4: Configurar Variables de Entorno

Ve a **"Entorno"** y asegúrate de tener estas variables:

```
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false
CHROMIUM_FLAGS=--no-sandbox --disable-setuid-sandbox
```

**Nota**: El Dockerfile ya configura algunas de estas, pero es mejor tenerlas también en EasyPanel.

---

## 🔄 Paso 5: Reconstruir el servicio

1. **Ve a "Implementaciones"**
2. **Haz clic en "Implementar"** o **"Reconstruir"**
3. **Espera 10-15 minutos** (el build con Dockerfile puede tardar más)

---

## ✅ Paso 6: Verificar que funciona

Después del build, verifica los logs:

1. **Ve a "Logs"** del servicio
2. **Busca estos mensajes**:
   - ✅ `Chromium instalado` o `Chromium version`
   - ✅ `Servidor WhatsApp iniciado en puerto 3001`
   - ❌ Si ves `Could not find expected browser`, el problema persiste

---

## 🔍 Solución de Problemas

### Si EasyPanel no encuentra el Dockerfile:

1. **Verifica la ruta**:
   - Si el código está en `/root/checkin24hs/whatsapp-server/`, la ruta debe ser `./Dockerfile` o `whatsapp-server/Dockerfile`

2. **Verifica que el Dockerfile existe**:
   ```bash
   ls -la /root/checkin24hs/whatsapp-server/Dockerfile
   ```

### Si el build falla:

1. **Revisa los logs** en EasyPanel
2. **Verifica que todas las variables de entorno estén configuradas**
3. **Asegúrate de que el Dockerfile esté en la ubicación correcta**

---

## 📋 Resumen

- ✅ Dockerfile actualizado con soporte para Chromium del sistema y Puppeteer como fallback
- ✅ Configurar EasyPanel para usar "Dockerfile" en lugar de "Nixpacks"
- ✅ Variables de entorno configuradas
- ✅ Reconstruir el servicio

**¿Necesitas ayuda con algún paso específico?**









