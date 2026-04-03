# 🔧 Solucionar Error de Chromium en EasyPanel

## ❌ Error Actual

```
Error: Could not find expected browser (chrome) locally. Run `npm install` to download the correct Chromium revision (1045629).
```

---

## ✅ Solución: Agregar Variables de Entorno Adicionales

EasyPanel necesita variables de entorno adicionales para que Puppeteer encuentre Chromium.

### Paso 1: Agregar Variables de Entorno en EasyPanel

Ve a **EasyPanel** → **Servicios** → **`whatsapp`** → **"⚙️ Entorno"** (Environment Variables)

Agrega estas **3 variables adicionales** (además de las que ya tienes):

#### Variable 1: PUPPETEER_EXECUTABLE_PATH
```
Nombre: PUPPETEER_EXECUTABLE_PATH
Valor: /usr/bin/chromium
```

#### Variable 2: CHROME_BIN
```
Nombre: CHROME_BIN
Valor: /usr/bin/chromium
```

#### Variable 3: CHROMIUM_FLAGS
```
Nombre: CHROMIUM_FLAGS
Valor: --no-sandbox --disable-setuid-sandbox
```

---

## 📋 Variables de Entorno Completas

Después de agregar las nuevas variables, deberías tener **8 variables** en total:

1. ✅ `INSTANCE_NUMBER=1`
2. ✅ `PORT=3001`
3. ✅ `SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co`
4. ✅ `SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
5. ✅ `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true`
6. ➕ **`PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium`** ← NUEVA
7. ➕ **`CHROME_BIN=/usr/bin/chromium`** ← NUEVA
8. ➕ **`CHROMIUM_FLAGS=--no-sandbox --disable-setuid-sandbox`** ← NUEVA

---

## 🔧 Alternativa: Si EasyPanel No Tiene Chromium Instalado

Si después de agregar las variables sigue fallando, EasyPanel puede estar usando una imagen base que no tiene Chromium instalado.

### Opción A: Configurar Build Command en EasyPanel

En la configuración del servicio, busca **"Build Command"** o **"Comando de Build"** y agrega:

```bash
apt-get update && apt-get install -y chromium chromium-sandbox && npm install
```

### Opción B: Usar Imagen Base con Chromium

Si EasyPanel permite cambiar la imagen base, usa:
- `node:18-slim` (en lugar de `node:18-alpine`)
- O una imagen que ya incluya Chromium

---

## ✅ Después de Agregar las Variables

1. **Guarda** los cambios en EasyPanel
2. **Reinicia** el servicio (detener e iniciar nuevamente)
3. **Espera** 1-2 minutos
4. **Revisa los logs** - Deberías ver:
   ```
   🚀 Iniciando servidor WhatsApp...
   WhatsApp server iniciado en puerto 3001
   ```

---

## 🆘 Si Sigue Fallando

Si después de agregar las variables sigue el error, puede ser que:

1. **EasyPanel no tenga Chromium instalado** en la imagen base
2. **Necesites instalar Chromium durante el build**

En ese caso, comparte:
- La imagen base que está usando EasyPanel
- Si hay opciones de "Build Command" o "Dockerfile" en EasyPanel

---

**Agrega las 3 variables nuevas y reinicia el servicio. ¿Qué ves en los logs después?**









