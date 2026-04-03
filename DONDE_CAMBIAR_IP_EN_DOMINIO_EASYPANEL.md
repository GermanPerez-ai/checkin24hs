# 📍 Dónde Cambiar a la IP en EasyPanel

## 🎯 Ubicación del Campo

En el modal "Actualizar dominio" que estás viendo:

### Opción 1: Campo "Target Service" o "Servicio de destino"

1. **En la sección "Destino"** (donde está Protocolo, Puerto, Ruta)
2. **Busca un campo** que diga:
   - **"Target Service"** (en inglés)
   - **"Servicio de destino"** (en español)
   - **"Service"** o **"Servicio"**
   - O puede estar **debajo** de los campos que ves (haz scroll hacia abajo)

3. **Ese campo** es donde debes poner: `10.11.125.90:3000`

### Opción 2: Si No Ves ese Campo

Puede que el campo esté en otra pestaña o sección:

1. **Revisa las otras pestañas**: "Middlewares" o "SSL"
2. **O haz scroll hacia abajo** en la pestaña "Detalles"
3. **O busca un botón** que diga "Avanzado" o "Advanced" que muestre más opciones

### Opción 3: Campo Oculto o en Otra Ubicación

Si no encuentras el campo, puede ser que:
- Esté **debajo** de los campos visibles (haz scroll)
- Esté en **otra sección** del modal
- Necesites **hacer clic en "Avanzado"** para verlo

## 🔍 Qué Buscar Exactamente

Busca un campo de texto que actualmente tenga:
- `checkin24hs-dashboard`
- O `checkin24hs_dashboard`
- O esté vacío

**Ese es el campo** donde debes escribir: `10.11.125.90:3000`

---

**¿Puedes hacer scroll hacia abajo en el modal o revisar si hay más campos debajo de "Ruta"? O dime qué otros campos ves en la sección "Destino".**

