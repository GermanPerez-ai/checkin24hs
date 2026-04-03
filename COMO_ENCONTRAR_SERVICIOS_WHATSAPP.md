# 🔍 Cómo Encontrar los Servicios de WhatsApp en EasyPanel

## ⚠️ IMPORTANTE

**NO necesitas crear un servicio nuevo.** Los servicios de WhatsApp **YA DEBEN EXISTIR** en EasyPanel.

---

## 📋 Paso 1: Buscar los Servicios Existentes

Los servicios de WhatsApp pueden tener estos nombres:

- `whatsapp`
- `whatsapp2`
- `whatsapp3`
- `whatsapp4`
- O nombres similares como:
  - `whatsapp-server`
  - `whatsapp-flor`
  - `whatsapp-bot`
  - `flor-whatsapp`

---

## 🔍 Paso 2: Dónde Buscar

### Opción A: En la Lista de Servicios

1. En EasyPanel, ve a **"Servicios"** o **"Services"** (donde estás ahora)
2. **Busca en la lista** de servicios existentes
3. Busca servicios que:
   - Tengan "whatsapp" en el nombre
   - Estén usando los puertos **3001, 3002, 3003, 3004**
   - Estén en estado **"Running"** (verde)

### Opción B: En un Proyecto Específico

1. Ve a **"Proyectos"** o **"Projects"** en EasyPanel
2. Busca un proyecto llamado:
   - `checkin24hs`
   - `whatsapp`
   - O el nombre de tu proyecto principal
3. **Abre el proyecto**
4. Dentro del proyecto, verás la lista de servicios

---

## ✅ Paso 3: Una Vez que Encuentres los Servicios

Cuando encuentres cada servicio (`whatsapp`, `whatsapp2`, `whatsapp3`, `whatsapp4`):

1. **Haz clic en el servicio** para abrirlo
2. **Busca la pestaña/sección "Dominios"** o **"Domains"**
3. **Haz clic en "Agregar Dominio"** o **"Add Domain"**
4. **Configura**:
   - Para `whatsapp`: Dominio = `api1.checkin24hs.com`, Puerto = `3001`, SSL = ✅
   - Para `whatsapp2`: Dominio = `api2.checkin24hs.com`, Puerto = `3002`, SSL = ✅
   - Para `whatsapp3`: Dominio = `api3.checkin24hs.com`, Puerto = `3003`, SSL = ✅
   - Para `whatsapp4`: Dominio = `api4.checkin24hs.com`, Puerto = `3004`, SSL = ✅

---

## ❓ ¿No Encuentras los Servicios?

Si no ves los servicios de WhatsApp:

1. **Revisa todos los proyectos** en EasyPanel
2. **Busca por puerto**: Servicios usando puertos 3001-3004
3. **Revisa los logs**: Servicios que muestren errores o logs de WhatsApp
4. **Pregúntame**: ¿Qué servicios ves en tu lista? Puedo ayudarte a identificarlos

---

## 🎯 Resumen

- ❌ **NO crear** un servicio nuevo
- ✅ **BUSCAR** los servicios existentes (`whatsapp`, `whatsapp2`, etc.)
- ✅ **AGREGAR dominios** a esos servicios existentes

---

**¿Qué servicios ves en tu lista de EasyPanel? Compárteme los nombres y te ayudo a identificar cuáles son los de WhatsApp.**









