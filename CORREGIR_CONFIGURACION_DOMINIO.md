# 🔧 Corregir Configuración del Dominio

## 🎯 Problema en el Modal

Veo que hay un error y los campos no están configurados correctamente:

- **Host** debe ser: `dashboard.checkin24hs.com` (el dominio)
- **Destino** debe ser: `http://dashboard:80/` (el servicio interno)

## ✅ Solución: Configurar Correctamente

### Paso 1: Cerrar el Modal Actual

1. Haz clic en la **"X"** (cerrar) del modal
2. O haz clic fuera del modal

### Paso 2: Eliminar el Dominio Actual

1. En la pestaña **"Dominios"**, busca el dominio `dashboard.checkin24hs.com`
2. Haz clic en el icono de **basura** (eliminar) del dominio
3. Confirma la eliminación
4. Espera 30 segundos

### Paso 3: Agregar el Dominio de Nuevo

1. Haz clic en **"Agregar dominio"** (botón en la parte inferior)
2. Se abrirá un modal para agregar dominio

### Paso 4: Configurar el Dominio Correctamente

En el modal que se abre:

1. **Campo "Host"** o **"Dominio"**:
   - Ingresa: `dashboard.checkin24hs.com`
   - **NO** pongas `http://dashboard:80/` aquí

2. **Sección "Destino"**:
   - **Protocolo**: `HTTP`
   - **Puerto**: `80`
   - **Ruta**: `/` (o déjalo vacío)

3. **IMPORTANTE**: Verifica si hay un campo para especificar el servicio o destino
   - Puede estar en una sección separada
   - O puede generarse automáticamente

4. Haz clic en **"Guardar"**

### Paso 5: Verificar el Destino Generado

Después de guardar:

1. En la lista de dominios, busca `dashboard.checkin24hs.com`
2. **Verifica qué destino aparece**
   - ¿Es `http://checkin24hs_dashboard:80/` (guión bajo)?
   - ¿O es `http://dashboard:80/`?

### Paso 6: Si el Destino Tiene Guión Bajo

Si EasyPanel genera `http://checkin24hs_dashboard:80/` (guión bajo), entonces:

- El problema es que EasyPanel siempre usa el formato `proyecto_servicio`
- Necesitamos que el servicio tenga el alias `checkin24hs_dashboard` (guión bajo)

---

**Cierra el modal actual, elimina el dominio, y agrégalo de nuevo. Cuando agregues el dominio, comparte qué campos ves en el modal y qué destino genera EasyPanel.**
