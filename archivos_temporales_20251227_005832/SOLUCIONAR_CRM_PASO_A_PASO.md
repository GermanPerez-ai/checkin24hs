# Solucionar Error CRM: Paso a Paso

## Problema
El servicio CRM no puede encontrar `/app/serve-crm.js` porque el archivo no está en la imagen Docker.

## Solución Paso a Paso

### Paso 1: Subir archivos al servidor (desde tu máquina local)

**Opción A: Usar el script PowerShell (Windows)**

```powershell
.\SUBIR_Y_APLICAR_CRM.ps1
```

**Opción B: Subir manualmente**

```powershell
# Desde PowerShell en tu máquina local:
scp serve-crm.js root@72.61.58.240:/root/checkin24hs/
scp Dockerfile.crm root@72.61.58.240:/root/checkin24hs/
scp APLICAR_CRM_MANUAL_SERVIDOR.sh root@72.61.58.240:/root/checkin24hs/
```

### Paso 2: Aplicar en el servidor

**Conecta al servidor y ejecuta:**

```bash
cd /root/checkin24hs

# Dar permisos de ejecución
chmod +x APLICAR_CRM_MANUAL_SERVIDOR.sh

# Ejecutar el script
./APLICAR_CRM_MANUAL_SERVIDOR.sh
```

**O manualmente:**

```bash
# 1. Verificar servicios CRM disponibles
docker service ls | grep -i crm

# 2. Obtener el nombre exacto del servicio (puede ser checkin24hs_crm, crm, etc.)
SERVICE_NAME="checkin24hs_crm"  # Cambia esto por el nombre real

# 3. Obtener contenedor
CONTAINER_ID=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.ID}}" | head -1)

# Si no encuentra, intentar con docker service ps
if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_NAME=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.Name}}" | head -1)
    CONTAINER_ID=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
fi

# 4. Copiar archivo
docker cp /root/checkin24hs/serve-crm.js $CONTAINER_ID:/app/serve-crm.js

# 5. Reiniciar servicio
docker service update --force $SERVICE_NAME

# 6. Verificar logs (después de 30 segundos)
sleep 30
docker service logs $SERVICE_NAME --tail 50
```

### Paso 3: Verificar que funciona

```bash
# Ver logs del servicio
docker service logs checkin24hs_crm --tail 50

# Deberías ver:
# 🚀 CRM corriendo en http://0.0.0.0:3005
```

### Paso 4: Solución Permanente (Opcional)

Para que el archivo esté siempre en la imagen Docker:

1. **Agregar archivos a Git (desde tu máquina local):**

```bash
git add Dockerfile.crm serve-crm.js
git commit -m "Agregar Dockerfile y serve-crm.js para CRM"
git push
```

2. **Configurar en EasyPanel:**
   - Ve a EasyPanel → Servicio CRM
   - Cambia "Tipo de compilación" a `Dockerfile`
   - Archivo Dockerfile: `Dockerfile.crm`
   - Guarda y espera 2-5 minutos

## Notas

- Si el servicio tiene otro nombre, el script `APLICAR_CRM_MANUAL_SERVIDOR.sh` te pedirá el nombre correcto
- La solución temporal funciona inmediatamente pero se pierde al recrear el contenedor
- La solución permanente requiere reconstruir la imagen Docker

