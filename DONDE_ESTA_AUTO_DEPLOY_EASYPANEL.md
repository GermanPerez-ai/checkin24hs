# 🔍 ¿Dónde Está Auto-Deploy en EasyPanel?

## ⚠️ IMPORTANTE

**Auto-Deploy puede NO estar disponible** en todas las versiones de EasyPanel o puede estar en diferentes lugares según la versión que uses.

## 🔍 Dónde Buscar Auto-Deploy

### Opción 1: En la Sección Source (Fuente)

1. Ve a la sección **"Source"** o **"Fuente"**
2. Busca un **interruptor** (toggle) que diga:
   - "Auto Deploy"
   - "Auto Deploy on Push"
   - "Enable Auto Deploy"
   - "Despliegue Automático"

3. Si lo encuentras, puede tener un campo para seleccionar la rama:
   - **Branch**: `main`
   - O puede estar en un menú desplegable

### Opción 2: En Settings (Configuración)

1. Busca una sección llamada:
   - **"Settings"**
   - **"Configuración"**
   - **"Advanced"** (Avanzado)
   - **"General"**

2. Dentro de esa sección, busca:
   - "Auto Deploy"
   - "Deployment"
   - "Git Integration"

### Opción 3: Como Interruptor en la Parte Superior

1. Mira la parte **superior de la página** del servicio
2. Busca un **interruptor** o **toggle switch**
3. Puede estar junto a otros controles como "Start", "Stop", "Restart"

### Opción 4: En la Configuración de GitHub

1. Cuando configuras GitHub como fuente
2. Puede haber una **casilla de verificación** (checkbox) que diga:
   - "Enable auto-deploy"
   - "Auto deploy on push"
   - "Watch for changes"

## ✅ Si NO Encuentras Auto-Deploy

**¡NO ES PROBLEMA!** Auto-Deploy es una característica **opcional** y **NO es necesaria** para que funcione.

### Alternativa: Despliegue Manual

Puedes desplegar manualmente cuando sea necesario:

1. **Cada vez que hagas cambios en GitHub**:
   - Haz `git push origin main`
   - Luego ve a EasyPanel
   - Haz clic en el botón **"Deploy"** o **"Redeploy"** del servicio
   - Espera a que se actualice

2. **Ventajas del despliegue manual**:
   - Tienes control total sobre cuándo actualizar
   - Puedes verificar los cambios antes de desplegar
   - Evitas actualizaciones inesperadas

## 🎯 Lo MÁS IMPORTANTE

Lo **CRÍTICO** para que funcione es:

✅ **Source configurado correctamente**:
- Propietario: `GermanPerez-ai`
- Repositorio: `checkin24hs`
- **Rama: `main`** ← Esto SÍ es importante, debe estar en la sección Source
- Ruta: `/whatsapp-server`

✅ **Variables de entorno** configuradas

✅ **Puertos** configurados

✅ **Comando de inicio**: `node whatsapp-server.js`

✅ **Desplegar manualmente** cuando sea necesario

## 📝 Resumen

- **Auto-Deploy**: Opcional, no crítico
- **Rama (Branch)**: Debe estar en la sección Source/GitHub
- **Si no encuentras Auto-Deploy**: Usa despliegue manual (es igual de efectivo)

---

**¿Dónde está la rama?**

La rama (`main`) **DEBE estar** en la sección **Source** cuando configuras GitHub. Si no la ves:

1. Busca un campo que diga **"Branch"** o **"Rama"**
2. O busca un menú desplegable en la configuración de GitHub
3. O puede estar como parte del campo del repositorio

Si realmente no encuentras el campo de rama, es posible que EasyPanel use `main` por defecto cuando configuras GitHub.

