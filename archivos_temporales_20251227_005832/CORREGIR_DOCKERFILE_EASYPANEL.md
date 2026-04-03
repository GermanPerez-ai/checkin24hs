# Corregir Dockerfile en EasyPanel

## Problema Identificado

EasyPanel está usando el `Dockerfile` (del dashboard) en lugar de `Dockerfile.crm`. Por eso la imagen tiene `dashboard.html` y `server.js` pero no `serve-crm.js` ni `crm.html`.

## Solución: Configurar Dockerfile.crm en EasyPanel

### Paso 1: Ve a EasyPanel

1. Abre EasyPanel en tu navegador
2. Ve al servicio `crm`
3. Haz click en "Editar" o el icono de lápiz

### Paso 2: Ve a la Pestaña "Fuente" o "Source"

1. Busca la sección de configuración de compilación
2. Busca el campo **"Archivo Dockerfile"** o **"Dockerfile File"**

### Paso 3: Cambiar el Dockerfile

**IMPORTANTE**: El campo debe decir exactamente:

```
Dockerfile.crm
```

**NO** debe decir:
- `Dockerfile` ❌
- `Dockerfile.crm` (con espacios) ❌
- `./Dockerfile.crm` ❌

### Paso 4: Verificar Ruta de Compilación

Asegúrate de que la **"Ruta de compilación"** o **"Build path"** sea:
- `/` (raíz)
- O `.` (punto)

### Paso 5: Guardar y Reconstruir

1. Haz click en **"Guardar"** o **"Save"**
2. Busca la opción **"Rebuild"** o **"Reconstruir"** o **"Redeploy"**
3. Haz click para reconstruir la imagen
4. Espera 3-5 minutos

### Paso 6: Verificar

Después de reconstruir, verifica en el servidor:

```bash
# Ver archivos en la nueva imagen
docker run --rm easypanel/checkin24hs/crm:latest ls -lh /app/serve-crm.js
docker run --rm easypanel/checkin24hs/crm:latest ls -lh /app/crm.html

# Deberías ver los archivos ahora
```

## Si No Puedes Encontrar el Campo "Archivo Dockerfile"

### Opción A: Buscar en Otra Sección

1. Ve a la pestaña **"Configuración"** o **"Settings"**
2. O busca un menú desplegable con opciones de compilación
3. Busca campos relacionados con "Dockerfile", "Build", "Compilación"

### Opción B: Usar la Pestaña "Dockerfile"

1. En la sección "Fuente", busca las pestañas:
   - Github
   - Dockerfile ← **Esta pestaña**
   - Git
   - etc.
2. Haz click en la pestaña **"Dockerfile"**
3. Ahí deberías poder especificar el archivo Dockerfile

### Opción C: Eliminar y Recrear el Servicio

Si no encuentras la opción:

1. **Elimina el servicio** `crm` en EasyPanel
2. **Créalo de nuevo** siguiendo estos pasos:
   - Nombre: `crm`
   - Tipo: `Aplicación`
   - Repositorio: Tu repositorio
   - **Tipo de compilación**: `Dockerfile`
   - **Archivo Dockerfile**: `Dockerfile.crm` ← **MUY IMPORTANTE**
   - Puerto: `3005`
   - Dominio: `crm.checkin24hs.com`

## Verificación Final

Después de corregir, la imagen debería tener:

```bash
docker run --rm easypanel/checkin24hs/crm:latest ls -lh /app/ | grep -E "serve-crm|crm.html|crm.js"
```

Deberías ver:
- `serve-crm.js`
- `crm.html`
- `crm.js`

## Nota Importante

El problema es que EasyPanel está usando el `Dockerfile` por defecto (que es para el dashboard) en lugar de `Dockerfile.crm`. Asegúrate de especificar explícitamente `Dockerfile.crm` en la configuración.






