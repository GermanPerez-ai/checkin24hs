# 🧪 Guía de Pruebas - Build #42

## 📋 Botones y Funciones a Probar

### 🎯 Ubicación: Sección "Gestión de Cotizaciones"

**Ruta:** Dashboard → **Cotizaciones** (en el menú lateral)

---

## ✅ Prueba 1: Crear y Enviar Cotización por WhatsApp

### Botón a usar:
**"Nueva Cotización"** (botón verde con ícono `+`)

### Pasos:
1. Haz clic en **"Nueva Cotización"**
2. Completa el formulario:
   - Selecciona un hotel
   - Ingresa fechas (Check-in y Check-out)
   - Ingresa número de huéspedes
   - Selecciona módulo
   - Ingresa tarifa
3. **En el campo "Número de WhatsApp del destinatario":**
   - **Prueba A:** Deja vacío → Debe mostrar notificación: "❌ Por favor ingresa el número de WhatsApp del destinatario"
   - **Prueba B:** Ingresa número sin código de país (ej: `123456789`) → Debe mostrar notificación: "❌ El número de teléfono debe incluir código de país (mínimo 10 dígitos)"
   - **Prueba C:** Ingresa número válido con código de país (ej: `+56912345678` o `56912345678`)
4. Haz clic en **"Crear y Enviar por WhatsApp"** (botón verde con ícono de envío)

### ✅ Resultados esperados:
- ✅ Si el servidor está configurado: Notificación verde "✅ Cotización creada y enviada exitosamente..."
- ✅ Si el servidor falla: Notificación amarilla "⚠️ No se pudo enviar automáticamente..." y se abre WhatsApp Web
- ✅ **IMPORTANTE:** Debe usar `showNotification()` (notificación en la esquina superior derecha), NO `alert()` (ventana emergente)

---

## ✅ Prueba 2: Enviar Link del Cotizador

### Botón a usar:
**"Enviar Link Cotizador"** (botón verde con ícono de link)

### Pasos:
1. Haz clic en **"Enviar Link Cotizador"**
2. **En el campo "Número de WhatsApp del Cliente":**
   - **Prueba A:** Deja vacío → Debe mostrar notificación: "❌ Por favor ingresa el número de WhatsApp del cliente"
   - **Prueba B:** Ingresa número inválido (menos de 10 dígitos) → Debe mostrar notificación: "❌ El número de teléfono no es válido. Debe incluir el código de país."
   - **Prueba C:** Ingresa número válido (ej: `+56912345678`)
3. (Opcional) Ingresa mensaje personalizado
4. Haz clic en **"Enviar Link por WhatsApp"** (botón verde)

### ✅ Resultados esperados:
- ✅ Si funciona: Notificación verde "✅ Link del cotizador enviado exitosamente..."
- ✅ Si falla: Notificación amarilla y se abre WhatsApp Web
- ✅ **IMPORTANTE:** Debe usar `showNotification()`, NO `alert()`

---

## ✅ Prueba 3: Enviar Cotización desde Lista Existente

### Botón a usar:
**"Editar y Cotizar"** (botón naranja en cada cotización de la lista)

### Pasos:
1. En la lista de cotizaciones, busca una cotización existente
2. Haz clic en **"Editar y Cotizar"** (botón naranja)
3. Modifica lo que necesites
4. Haz clic en **"Enviar por WhatsApp"** (dentro del modal de edición)

### ✅ Resultados esperados:
- ✅ Validaciones funcionan igual que en Prueba 1
- ✅ Notificaciones claras con `showNotification()`
- ✅ Fallback a WhatsApp Web si falla

---

## 🔍 Qué Verificar en Todas las Pruebas

### 1. **Validaciones** ✅
- [ ] Número vacío → Muestra error claro
- [ ] Número inválido (sin código de país) → Muestra error claro
- [ ] Número válido → Acepta y procede

### 2. **Notificaciones** ✅
- [ ] Usa `showNotification()` (notificación en esquina superior derecha)
- [ ] **NO** usa `alert()` (ventana emergente molesta)
- [ ] Mensajes claros y específicos
- [ ] Colores correctos:
  - Verde para éxito
  - Amarillo/Naranja para advertencias
  - Rojo para errores

### 3. **Manejo de Errores** ✅
- [ ] Si el servidor no responde → Timeout después de 30 segundos
- [ ] Si falla la conexión → Fallback automático a WhatsApp Web
- [ ] Mensajes de error descriptivos
- [ ] No se rompe la aplicación

### 4. **Logging en Consola** ✅
- [ ] Abre la consola del navegador (F12 → Console)
- [ ] Debe mostrar logs claros:
  - `📱 Enviando mensaje por WhatsApp a: [número]`
  - `✅ Mensaje enviado exitosamente` (si funciona)
  - `❌ Error...` (si falla)

---

## 🚨 Errores Comunes a Probar

### Error 1: Servidor no configurado
**Qué hacer:** No configures la URL del servidor WhatsApp
**Resultado esperado:** Notificación clara y fallback a WhatsApp Web

### Error 2: Servidor no responde
**Qué hacer:** Configura una URL inválida del servidor
**Resultado esperado:** Timeout después de 30 segundos y fallback

### Error 3: Número inválido
**Qué hacer:** Ingresa números como `123`, `abc`, etc.
**Resultado esperado:** Validación clara antes de intentar enviar

---

## 📝 Checklist de Pruebas

- [ ] **Prueba 1:** Crear cotización nueva → Validaciones funcionan
- [ ] **Prueba 1:** Crear cotización nueva → Envío exitoso muestra notificación verde
- [ ] **Prueba 1:** Crear cotización nueva → Error muestra notificación amarilla y abre WhatsApp Web
- [ ] **Prueba 2:** Enviar link cotizador → Validaciones funcionan
- [ ] **Prueba 2:** Enviar link cotizador → Envío exitoso muestra notificación verde
- [ ] **Prueba 3:** Editar cotización existente → Validaciones funcionan
- [ ] **Verificación:** Todas usan `showNotification()`, NO `alert()`
- [ ] **Verificación:** Logs en consola son claros y útiles
- [ ] **Verificación:** Timeout funciona (si el servidor no responde)

---

## 🎯 Resultado Final Esperado

**Antes (Build #41):**
- ❌ Usaba `alert()` (ventanas emergentes molestas)
- ❌ Validaciones básicas o inexistentes
- ❌ Mensajes de error genéricos
- ❌ Sin timeout (podía esperar infinitamente)

**Ahora (Build #42):**
- ✅ Usa `showNotification()` (notificaciones elegantes)
- ✅ Validaciones completas y claras
- ✅ Mensajes de error específicos y útiles
- ✅ Timeout de 30 segundos
- ✅ Fallback automático a WhatsApp Web

---

**¿Todo funcionando como se espera?** ✅
