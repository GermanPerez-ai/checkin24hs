# Instalar CRM desde Cero - Guía Completa

## Paso 1: Eliminar el Servicio Actual

En el servidor, ejecuta:

```bash
# Detener y eliminar el servicio actual
docker service rm checkin24hs_crm

# Verificar que se eliminó
docker service ls | grep crm
```

## Paso 2: Preparar Archivos en Git

Desde tu máquina local, asegúrate de que estos archivos estén en Git:

### Archivos Requeridos:

1. **Dockerfile.crm** (ya creado)
2. **serve-crm.js** (ya creado)
3. **deploy/crm.html**
4. **deploy/crm.js**
5. **package.json** (debe incluir `express`)
6. Archivos JavaScript necesarios:
   - `supabase-config.js`
   - `supabase-client.js`
   - `flor-knowledge-base.js`
   - `flor-ai-service.js`
   - `flor-learning-system.js`
   - `flor-agent.js`

### Verificar package.json

Asegúrate de que `package.json` incluya:

```json
{
  "dependencies": {
    "express": "^4.21.2"
  }
}
```

### Agregar a Git

```bash
# Desde tu máquina local
git add Dockerfile.crm serve-crm.js
git add deploy/crm.html deploy/crm.js
git add supabase-config.js supabase-client.js
git add flor-knowledge-base.js flor-ai-service.js flor-learning-system.js flor-agent.js
git commit -m "Agregar CRM completo con Dockerfile"
git push
```

## Paso 3: Crear Servicio en EasyPanel

1. **Ve a EasyPanel** → Click en "Nuevo Servicio" o "Crear Servicio"

2. **Configuración Básica:**
   - **Nombre del servicio**: `crm`
   - **Tipo**: `Aplicación` o `App`
   - **Repositorio**: Tu repositorio de GitHub (el mismo que usas para el dashboard)

3. **Configuración de Compilación:**
   - **Tipo de compilación**: `Dockerfile`
   - **Archivo Dockerfile**: `Dockerfile.crm`
   - **Rama**: `main` (o la rama que uses)

4. **Configuración de Puerto:**
   - **Puerto interno**: `3005`
   - **Puerto externo**: Dejar que EasyPanel lo asigne automáticamente

5. **Configuración de Dominio:**
   - **Dominio**: `crm.checkin24hs.com`
   - **SSL**: Activar "Let's Encrypt" o "SSL automático" (si está disponible)

6. **Variables de Entorno** (si las necesitas):
   - `PORT=3005` (opcional, el código ya usa 3005 por defecto)

7. **Recursos** (recomendado):
   - **CPU**: 0.5 cores mínimo
   - **RAM**: 512MB mínimo
   - **Disco**: 1GB mínimo

8. **Red:**
   - Asegúrate de que esté en la misma red que Traefik (normalmente `easypanel` o similar)

9. **Guardar y Desplegar:**
   - Click en "Guardar" o "Deploy"
   - Espera 3-5 minutos para que se construya la imagen y se inicie el servicio

## Paso 4: Verificar Instalación

En el servidor, ejecuta:

```bash
# Ver estado del servicio
docker service ls | grep crm

# Ver logs
docker service logs checkin24hs_crm --tail 50

# Deberías ver:
# CRM corriendo en http://0.0.0.0:3005
# Sirviendo archivos desde: /app
```

## Paso 5: Verificar Funcionamiento

1. **Accede al CRM:**
   - `http://crm.checkin24hs.com` (o HTTPS si configuraste SSL)

2. **Verifica que carga correctamente:**
   - Deberías ver el menú lateral con "Interacciones", "Chats", "Flor IA"
   - No deberían aparecer errores en la consola del navegador

## Paso 6: Configurar Traefik (si es necesario)

Si el dominio no funciona automáticamente, verifica las etiquetas de Traefik:

```bash
# Ver configuración del servicio
docker service inspect checkin24hs_crm --format '{{json .Spec.Labels}}' | jq

# Si falta configuración de Traefik, agrega las etiquetas necesarias
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.crm.entrypoints=web" \
  --label-add "traefik.http.services.crm.loadbalancer.server.port=3005" \
  checkin24hs_crm
```

## Solución de Problemas

### Error: "Cannot find module '/app/serve-crm.js'"

**Causa**: El Dockerfile no se está usando o el archivo no está en Git.

**Solución**:
1. Verifica que `Dockerfile.crm` esté en la raíz del repositorio
2. Verifica que `serve-crm.js` esté en la raíz del repositorio
3. Verifica en EasyPanel que "Archivo Dockerfile" sea `Dockerfile.crm`
4. Haz un nuevo deploy en EasyPanel

### Error: "Cannot find module 'express'"

**Causa**: `package.json` no incluye `express` o no se está instalando.

**Solución**:
1. Verifica que `package.json` tenga `express` en `dependencies`
2. Haz un nuevo deploy en EasyPanel

### Error: "Cannot GET /"

**Causa**: El archivo `crm.html` no está en el contenedor.

**Solución**:
1. Verifica que `deploy/crm.html` esté en Git
2. Verifica que el Dockerfile copie `deploy/crm.html` como `crm.html`
3. Haz un nuevo deploy

### El servicio no responde

**Solución**:
```bash
# Ver logs detallados
docker service logs checkin24hs_crm --tail 100

# Ver estado del servicio
docker service ps checkin24hs_crm --no-trunc

# Verificar contenedores
docker ps --filter "name=crm"
```

## Estructura Final del Repositorio

```
checkin24hs/
├── Dockerfile.crm          # Dockerfile para CRM
├── serve-crm.js            # Servidor Node.js para CRM
├── package.json            # Debe incluir express
├── supabase-config.js      # Configuración de Supabase
├── supabase-client.js      # Cliente de Supabase
├── flor-knowledge-base.js  # Base de conocimiento de Flor
├── flor-ai-service.js      # Servicio de IA de Flor
├── flor-learning-system.js # Sistema de aprendizaje de Flor
├── flor-agent.js           # Agente de Flor
└── deploy/
    ├── crm.html            # HTML principal del CRM
    └── crm.js              # JavaScript del CRM
```

## Notas Importantes

1. **El Dockerfile.crm ya está configurado** para copiar todos los archivos necesarios
2. **El puerto por defecto es 3005**, pero EasyPanel puede cambiarlo si es necesario
3. **Los archivos JavaScript deben estar en la raíz** del repositorio para que el Dockerfile los copie
4. **Después de cada cambio**, haz un nuevo deploy en EasyPanel para reconstruir la imagen

## Comandos Útiles

```bash
# Ver logs en tiempo real
docker service logs -f checkin24hs_crm

# Reiniciar servicio
docker service update --force checkin24hs_crm

# Ver configuración del servicio
docker service inspect checkin24hs_crm

# Entrar al contenedor (para debugging)
CONTAINER_ID=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)
docker exec -it $CONTAINER_ID sh
```

