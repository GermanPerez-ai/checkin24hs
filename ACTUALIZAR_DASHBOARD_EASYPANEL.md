# 🔄 Actualizar Dashboard en EasyPanel

## 🚨 Problema

Estás viendo la versión **antigua** del dashboard que tiene:
- ❌ Botón "+ Agregar conexión a WhatsApp" (antiguo)
- ❌ No tiene el modal de conexión múltiple

Necesitas actualizar a la versión **nueva** que tiene:
- ✅ Botón "Conectar Múltiples WhatsApp (hasta 4)" (nuevo)
- ✅ Modal para conectar hasta 4 instancias de WhatsApp

---

## ✅ Solución: Actualizar el Dashboard

### Paso 1: Verificar que el Código Está en GitHub

El código ya está actualizado en GitHub con la nueva funcionalidad. Verifica:

1. Ve a: https://github.com/GermanPerez-ai/checkin24hs
2. Navega a: `dashboard.html`
3. Busca: "Conectar Múltiples WhatsApp" (debe aparecer)

✅ **Si está actualizado**: Continúa con el Paso 2  
❌ **Si no está actualizado**: Espera unos minutos y vuelve a verificar

---

### Paso 2: Actualizar el Dashboard en EasyPanel

#### Opción A: Si el Dashboard está conectado a GitHub (Recomendado)

1. **Ve al servicio del Dashboard** en EasyPanel
   - Busca el servicio llamado `checkin24hs_dashboard` o `dashboard`

2. **Verifica la configuración de Source**:
   - Source: GitHub
   - Owner: `GermanPerez-ai`
   - Repository: `checkin24hs`
   - Branch: `main`
   - Build Path: `/` (o la ruta donde esté el dashboard)

3. **Haz clic en "Deploy"** o **"Implementar"**:
   - Busca el botón "Deploy" o "Implementar"
   - Haz clic en él
   - Espera 2-3 minutos mientras se actualiza

4. **Verifica que se actualizó**:
   - Refresca la página del dashboard (Ctrl+F5 o Cmd+Shift+R)
   - Deberías ver el botón "Conectar Múltiples WhatsApp (hasta 4)"

---

#### Opción B: Si el Dashboard NO está conectado a GitHub

1. **Ve al servicio del Dashboard** en EasyPanel

2. **Configura Source desde GitHub**:
   - Ve a la sección "Source" o "Fuente"
   - Selecciona "GitHub"
   - Configura:
     - Owner: `GermanPerez-ai`
     - Repository: `checkin24hs`
     - Branch: `main`
     - Build Path: `/` (o la ruta donde esté el dashboard)
   - Guarda

3. **Haz clic en "Deploy"** o **"Implementar"**

4. **Espera** 2-3 minutos

5. **Refresca** el dashboard (Ctrl+F5)

---

#### Opción C: Subir el Archivo Manualmente (Si no usas GitHub)

1. **Descarga el archivo actualizado**:
   - Ve a: https://github.com/GermanPerez-ai/checkin24hs
   - Navega a: `dashboard.html`
   - Haz clic en "Raw" (botón derecho → "Guardar como...")
   - O clona el repositorio y copia `dashboard.html`

2. **Sube el archivo a EasyPanel**:
   - Ve al servicio del Dashboard
   - Busca "Storage" o "Files" o "Archivos"
   - Localiza `dashboard.html`
   - Reemplázalo con el archivo actualizado

3. **Reinicia el servicio**:
   - Haz clic en "Restart" o "Reiniciar"
   - O haz "Deploy" nuevamente

---

## ✅ Verificar que Funciona

Después de actualizar, el dashboard debe mostrar:

### Nueva Interfaz (Correcta):

1. **En la sección "Configuración del Servidor"**:
   - Campo: "URL del Servidor WhatsApp" con `http://72.61.58.240`
   - Botón: "Verificar Conexión"

2. **En la sección "Conexiones WhatsApp"** (o similar):
   - Botón: **"Conectar Múltiples WhatsApp (hasta 4)"** ← Este es el nuevo
   - O un botón que diga algo sobre "conectar múltiples"

3. **Al hacer clic en el botón**:
   - Debe abrir un modal
   - Debe mostrar 4 tarjetas (Instancia 1, 2, 3, 4)
   - Cada tarjeta debe tener un botón "Conectar" o "🔗 Conectar"

---

## 🆘 Si No Aparece la Nueva Interfaz

### Problema 1: Cache del Navegador

**Solución**:
1. **Refresca forzado**: Ctrl+F5 (Windows) o Cmd+Shift+R (Mac)
2. **O limpia la cache**: Ctrl+Shift+Delete → Limpiar cache
3. **O modo incógnito**: Abre el dashboard en modo incógnito

### Problema 2: El Dashboard No Se Actualizó

**Solución**:
1. **Verifica los logs** del servicio en EasyPanel
2. **Verifica** que el Deploy terminó correctamente
3. **Espera** 1-2 minutos más
4. **Vuelve a hacer Deploy**

### Problema 3: El Código No Está en GitHub

**Solución**:
1. **Verifica** que `dashboard.html` esté en GitHub
2. **Verifica** que tenga "Conectar Múltiples WhatsApp"
3. Si no está, avísame y lo actualizo

---

## 📋 Checklist Final

- [ ] El código está en GitHub (verificado)
- [ ] El servicio del Dashboard está conectado a GitHub
- [ ] Se hizo "Deploy" o "Implementar"
- [ ] Se refrescó el dashboard (Ctrl+F5)
- [ ] Aparece el botón "Conectar Múltiples WhatsApp (hasta 4)"
- [ ] Al hacer clic, se abre el modal con 4 instancias

---

## 🎉 ¡Listo!

Una vez que veas la nueva interfaz:

1. **Configura la URL del servidor**: `http://72.61.58.240`
2. **Haz clic en "Conectar Múltiples WhatsApp (hasta 4)"**
3. **Haz clic en "Conectar"** en cada instancia
4. **Escanear los códigos QR** con WhatsApp

---

## 📖 Referencias

- [GUIA_PASO_A_PASO_WHATSAPP_EASYPANEL.md](./GUIA_PASO_A_PASO_WHATSAPP_EASYPANEL.md) - Guía completa de WhatsApp
- [DONDE_CONFIGURAR_WHATSAPP.md](./DONDE_CONFIGURAR_WHATSAPP.md) - Dónde configurar WhatsApp

