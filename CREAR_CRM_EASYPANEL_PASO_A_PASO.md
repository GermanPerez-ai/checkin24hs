# Crear CRM en EasyPanel - Paso a Paso

## ✅ Archivos Verificados

Los siguientes archivos ya están en Git:
- ✅ `Dockerfile.crm`
- ✅ `serve-crm.js`
- ✅ `deploy/crm.html`
- ✅ `deploy/crm.js`
- ✅ Archivos JavaScript necesarios (supabase-*, flor-*)

## Pasos para Crear el Servicio en EasyPanel

### Paso 1: Acceder a EasyPanel

1. Abre tu navegador y ve a tu panel de EasyPanel
2. Inicia sesión con tus credenciales

### Paso 2: Crear Nuevo Servicio

1. **Click en "Nuevo Servicio"** o **"Crear Servicio"** o **"Add Service"**
2. Selecciona **"Aplicación"** o **"App"**

### Paso 3: Configuración Básica

1. **Nombre del servicio:**
   - Ingresa: `crm`
   - (Este será el nombre del servicio Docker)

2. **Repositorio:**
   - Selecciona tu repositorio de GitHub
   - O ingresa la URL: `https://github.com/TU_USUARIO/TU_REPOSITORIO`
   - **Rama**: `main` (o la rama que uses)

### Paso 4: Configuración de Compilación

1. **Tipo de compilación:**
   - Selecciona: **`Dockerfile`**

2. **Archivo Dockerfile:**
   - Ingresa: **`Dockerfile.crm`**
   - ⚠️ **IMPORTANTE**: Debe ser exactamente `Dockerfile.crm` (no `Dockerfile`)

3. **Contexto de compilación:**
   - Deja el valor por defecto (normalmente `/` o raíz)

### Paso 5: Configuración de Puerto

1. **Puerto interno:**
   - Ingresa: **`3005`**
   - Este es el puerto que usa `serve-crm.js`

2. **Puerto externo:**
   - Deja que EasyPanel lo asigne automáticamente
   - O especifica uno si prefieres

### Paso 6: Configuración de Dominio

1. **Dominio:**
   - Ingresa: **`crm.checkin24hs.com`**
   - O el dominio que prefieras

2. **SSL:**
   - Activa **"Let's Encrypt"** o **"SSL automático"** si está disponible
   - Esto generará un certificado SSL automáticamente

### Paso 7: Variables de Entorno (Opcional)

Si quieres especificar el puerto explícitamente:
- **Nombre**: `PORT`
- **Valor**: `3005`

(No es necesario porque `serve-crm.js` ya usa 3005 por defecto)

### Paso 8: Recursos (Recomendado)

Configura recursos mínimos:
- **CPU**: `0.5` cores (mínimo)
- **RAM**: `512` MB (mínimo)
- **Disco**: `1` GB (mínimo)

### Paso 9: Red

- Asegúrate de que el servicio esté en la misma red que Traefik
- Normalmente EasyPanel lo configura automáticamente
- Si hay problemas, verifica que esté en la red `easypanel` o similar

### Paso 10: Guardar y Desplegar

1. **Revisa toda la configuración**
2. **Click en "Guardar"** o **"Deploy"** o **"Crear"**
3. **Espera 3-5 minutos** mientras:
   - EasyPanel clona el repositorio
   - Construye la imagen Docker usando `Dockerfile.crm`
   - Inicia el servicio

### Paso 11: Verificar Instalación

En el servidor, ejecuta:

```bash
# Ver estado del servicio
docker service ls | grep crm

# Ver logs
docker service logs checkin24hs_crm --tail 50
```

**Deberías ver:**
```
CRM corriendo en http://0.0.0.0:3005
Sirviendo archivos desde: /app
```

### Paso 12: Acceder al CRM

1. Abre tu navegador
2. Ve a: `http://crm.checkin24hs.com` (o HTTPS si configuraste SSL)
3. Deberías ver el CRM con el menú lateral

## Solución de Problemas

### Error: "Cannot find module '/app/serve-crm.js'"

**Causa**: El Dockerfile no se está usando o el archivo no está en Git.

**Solución**:
1. Verifica en EasyPanel que "Archivo Dockerfile" sea exactamente `Dockerfile.crm`
2. Verifica que `serve-crm.js` esté en Git: `git ls-files | grep serve-crm.js`
3. Haz un nuevo deploy

### Error: "Cannot find module 'express'"

**Causa**: `package.json` no se está instalando correctamente.

**Solución**:
1. Verifica que `package.json` esté en la raíz del repositorio
2. Verifica que tenga `express` en `dependencies`
3. Haz un nuevo deploy

### El servicio no responde

**Solución**:
```bash
# Ver logs detallados
docker service logs checkin24hs_crm --tail 100

# Ver estado
docker service ps checkin24hs_crm --no-trunc

# Verificar contenedores
docker ps --filter "name=crm"
```

### El dominio no funciona

**Solución**:
1. Verifica que el dominio apunte al servidor (DNS)
2. Verifica las etiquetas de Traefik:
```bash
docker service inspect checkin24hs_crm --format '{{json .Spec.Labels}}' | jq
```

## Resumen de Configuración

```
Nombre: crm
Tipo: Aplicación
Repositorio: [Tu repositorio]
Rama: main
Tipo de compilación: Dockerfile
Archivo Dockerfile: Dockerfile.crm
Puerto: 3005
Dominio: crm.checkin24hs.com
SSL: Let's Encrypt (si está disponible)
```

## Notas Importantes

1. ⚠️ **El archivo Dockerfile debe ser `Dockerfile.crm`**, no `Dockerfile`
2. ⚠️ **El puerto debe ser `3005`** (coincide con `serve-crm.js`)
3. ⚠️ **Espera 3-5 minutos** después de crear el servicio para que se construya la imagen
4. ✅ **Todos los archivos necesarios ya están en Git**


















