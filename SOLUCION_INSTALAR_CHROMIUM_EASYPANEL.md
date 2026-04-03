# 🔧 Instalar Chromium en EasyPanel

## ❌ Error Actual

```
Error: Tried to use PUPPETEER_EXECUTABLE_PATH env variable to launch browser but did not find any executable at: /usr/bin/chromium
```

**Problema**: Chromium no está instalado en el contenedor de EasyPanel.

---

## ✅ Solución: Instalar Chromium Durante el Build

EasyPanel necesita instalar Chromium durante el proceso de build. Hay varias formas de hacerlo:

---

## 🔧 Opción 1: Usar Build Command en EasyPanel (Recomendado)

### Paso 1: Encontrar Build Command

1. Ve a **EasyPanel** → **Servicios** → **`whatsapp`**
2. Busca la sección **"Build"** o **"Compilación"** o **"Settings"**
3. Busca **"Build Command"** o **"Comando de Build"** o **"Install Command"**

### Paso 2: Configurar Build Command

Si encuentras esta opción, configura:

```bash
apt-get update && apt-get install -y chromium chromium-sandbox && npm install
```

O si solo permite un comando:

```bash
npm install
```

Y luego agrega un **"Start Command"** o **"Run Command"**:

```bash
apt-get update && apt-get install -y chromium chromium-sandbox && node whatsapp-server.js
```

---

## 🔧 Opción 2: Usar Dockerfile Personalizado

Si EasyPanel permite usar un Dockerfile personalizado:

### Paso 1: Verificar si hay opción de Dockerfile

En la configuración del servicio, busca:
- **"Dockerfile"**
- **"Custom Dockerfile"**
- **"Build Settings"**

### Paso 2: Si permite Dockerfile

El Dockerfile en `whatsapp-server/Dockerfile` ya tiene Chromium instalado. Asegúrate de que EasyPanel lo esté usando.

---

## 🔧 Opción 3: Cambiar Variables de Entorno (Temporal)

Si ninguna de las opciones anteriores funciona, podemos intentar que Puppeteer descargue Chromium automáticamente:

### Cambiar Variables de Entorno:

1. **Elimina** estas variables:
   - `PUPPETEER_EXECUTABLE_PATH`
   - `CHROME_BIN`
   - `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD`

2. **Agrega** esta variable:
   ```
   Nombre: PUPPETEER_SKIP_CHROMIUM_DOWNLOAD
   Valor: false
   ```

Esto hará que Puppeteer descargue Chromium automáticamente, pero puede ser más lento.

---

## 🔧 Opción 4: Usar Imagen Base con Chromium

Si EasyPanel permite cambiar la imagen base:

1. Busca **"Base Image"** o **"Docker Image"** en la configuración
2. Cambia a una imagen que incluya Chromium, como:
   - `node:18-slim` (y luego instalar Chromium)
   - O una imagen personalizada con Chromium

---

## 🎯 Solución Más Probable: Build Command

La solución más probable es usar el **Build Command** de EasyPanel para instalar Chromium antes de iniciar el servicio.

### Pasos:

1. **Ve a la configuración del servicio** `whatsapp`
2. **Busca "Build Command"** o **"Install Command"**
3. **Configura**:
   ```bash
   apt-get update && apt-get install -y chromium chromium-sandbox && npm install
   ```
4. **Guarda** y **reconstruye** el servicio

---

## 📋 Verificar Configuración de EasyPanel

En EasyPanel, busca estas opciones en la configuración del servicio:

- ✅ **"Build Command"** / **"Comando de Build"**
- ✅ **"Install Command"** / **"Comando de Instalación"**
- ✅ **"Dockerfile"** / **"Custom Dockerfile"**
- ✅ **"Base Image"** / **"Imagen Base"**
- ✅ **"Settings"** / **"Configuración"**

---

## 🆘 Si No Encuentras Estas Opciones

Si EasyPanel no tiene estas opciones, puede ser que:

1. **EasyPanel use una imagen predefinida** sin Chromium
2. **Necesites usar un servicio diferente** que soporte Chromium
3. **Necesites instalar Chromium manualmente** en el contenedor (no recomendado)

---

## ✅ Próximos Pasos

1. **Busca "Build Command"** en la configuración del servicio
2. **Configura** el comando para instalar Chromium
3. **Reconstruye** el servicio
4. **Revisa los logs** para verificar que Chromium se instaló

---

**¿Puedes buscar en la configuración del servicio `whatsapp` si hay alguna opción de "Build Command", "Dockerfile" o "Install Command"? Compárteme qué opciones ves.**









