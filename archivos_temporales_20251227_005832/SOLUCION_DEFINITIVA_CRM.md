# Solución Definitiva para CRM

## Problema
Los contenedores nuevos no tienen `serve-crm.js` porque no está en la imagen Docker.

## Solución Inmediata: Copiar a Todos los Contenedores

Ejecuta este comando en el servidor:

```bash
SERVICE_NAME="checkin24hs_crm"
# Copiar a todos los contenedores existentes
CONTAINER_NAMES=$(docker service ps $SERVICE_NAME --format "{{.Name}}" | sort -u)
for CONTAINER_NAME in $CONTAINER_NAMES; do 
    CONTAINER_ID=$(docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
    if [ ! -z "$CONTAINER_ID" ]; then 
        echo "Copiando a $CONTAINER_NAME ($CONTAINER_ID)"
        docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js 2>&1 | head -1
    fi
done

# Reiniciar servicio
docker service update --force $SERVICE_NAME

# Esperar y copiar a contenedores nuevos
sleep 40

# Copiar a contenedores nuevos que se crearon
RUNNING_CONTAINERS=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}} {{.Names}}")
while IFS= read -r line; do 
    CONTAINER_ID=$(echo "$line" | awk '{print $1}')
    if [ ! -z "$CONTAINER_ID" ]; then 
        echo "Copiando a nuevo contenedor $CONTAINER_ID"
        docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js 2>&1 | head -1
        docker exec $CONTAINER_ID ls -lh /app/serve-crm.js 2>&1 | head -1
    fi
done <<< "$RUNNING_CONTAINERS"

# Ver logs
docker service logs $SERVICE_NAME --tail 30
```

## Solución Permanente: Configurar Dockerfile en EasyPanel

El problema es que EasyPanel está ejecutando `node serve-crm.js` pero el archivo no está en la imagen Docker.

### Opción 1: Cambiar el comando en EasyPanel (Temporal)

1. Ve a EasyPanel → Servicio `crm`
2. Busca el campo "Comando" o "Command"
3. Cámbialo temporalmente a algo que funcione, por ejemplo:
   - `node server.js` (si existe server.js)
   - O crea un script que copie el archivo antes de ejecutar

### Opción 2: Configurar Dockerfile (Permanente)

1. **Agregar archivos a Git** (desde tu máquina local):
```bash
git add Dockerfile.crm serve-crm.js
git commit -m "Agregar Dockerfile para CRM"
git push
```

2. **Configurar en EasyPanel:**
   - Ve a EasyPanel → Servicio `crm`
   - Cambia "Tipo de compilación" a `Dockerfile`
   - Archivo Dockerfile: `Dockerfile.crm`
   - Guarda y espera 2-5 minutos

3. **Verificar:**
```bash
docker service logs checkin24hs_crm --tail 50
```

Deberías ver: `CRM corriendo en http://0.0.0.0:3005`

## Nota Importante

La solución inmediata funciona, pero cada vez que se recrea un contenedor, necesitarás copiar el archivo de nuevo. La solución permanente (Dockerfile) asegura que el archivo siempre esté en la imagen.

