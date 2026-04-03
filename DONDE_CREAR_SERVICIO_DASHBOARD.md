# 📍 Dónde Crear el Nuevo Servicio "dashboard"

## 🎯 Ubicación en la Imagen

### Paso 1: Crear el Nuevo Servicio

1. **Busca el botón "+ Servicio"** en la parte superior derecha de la pantalla
2. Haz clic en **"+ Servicio"**
3. Se abrirá un modal para crear un nuevo servicio

### Paso 2: Configurar el Nuevo Servicio

En el modal que se abre:

1. **Nombre del servicio**: Escribe `dashboard`
2. **Seleccionar proyecto**: Elige `checkin24hs`
3. **Tipo de servicio**: Selecciona "Aplicación" o "App"
4. **Configuración**:
   - **Fuente**: Ve a la pestaña **"Github"** o **"Git"** (no "Subir")
   - O si prefieres, usa **"Dockerfile"** directamente
   - **Build Path**: `/deploy`
   - **Dockerfile Path**: `Dockerfile` (o `deploy/Dockerfile` dependiendo de la configuración)
   - **Puerto**: `80`
   - **Variables de entorno**: Agrega `PORT=80`

### Paso 3: Implementar

1. Haz clic en **"Crear"** o **"Implementar"**
2. Espera a que se construya e inicie el servicio

### Paso 4: Agregar el Dominio

1. Una vez que el servicio esté creado, ve a la pestaña **"Dominios"** (en el menú lateral izquierdo)
2. Haz clic en **"Agregar dominio"**
3. Ingresa: `dashboard.checkin24hs.com`
4. EasyPanel debería generar: `http://dashboard:80/`

---

## 🔍 Ubicaciones Específicas en la Imagen

- **"+ Servicio"**: Botón en la parte superior derecha, al lado de "Plantillas"
- **"Dominios"**: En el menú lateral izquierdo, debajo de "Entorno"
- **Configuración del servicio**: En las pestañas "Fuente", "Entorno", etc. en el área principal

---

**Haz clic en el botón "+ Servicio" en la parte superior derecha para crear el nuevo servicio.**
