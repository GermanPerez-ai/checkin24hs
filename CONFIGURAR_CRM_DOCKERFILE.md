# Configurar CRM con Dockerfile

## Problema
El servicio CRM está intentando ejecutar `node serve-crm.js` pero el archivo no está en la imagen Docker.

## Solución: Usar Dockerfile para CRM

### Opción 1: Configurar en EasyPanel (Recomendado)

1. **Ve a EasyPanel → Servicio `crm`**
2. **Ve a la pestaña "Fuente" o "Source"**
3. **Configuración:**
   - **Tipo de compilación**: `Dockerfile`
   - **Archivo Dockerfile**: `Dockerfile.crm`
   - **Puerto**: `3005`
   - **Dominio**: `crm.checkin24hs.com`

4. **Guarda y espera a que se reconstruya la imagen**

### Opción 2: Aplicar archivos manualmente (Temporal)

Si necesitas que funcione inmediatamente mientras configuras el Dockerfile:

```bash
# En el servidor, ejecuta:
cd /root/checkin24hs
./APLICAR_SERVE_CRM_SERVIDOR.sh
```

O manualmente:

```bash
# 1. Obtener contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_crm | awk '{print $1}' | head -1)

# 2. Copiar serve-crm.js
docker cp serve-crm.js $CONTAINER_ID:/app/serve-crm.js

# 3. Reiniciar servicio
docker service update --force checkin24hs_crm
```

### Archivos Necesarios

Asegúrate de que estos archivos estén en Git para que EasyPanel los incluya:

- ✅ `Dockerfile.crm` (nuevo)
- ✅ `serve-crm.js`
- ✅ `deploy/crm.html`
- ✅ `deploy/crm.js` (si existe)
- ✅ `package.json` (debe incluir `express`)

### Verificar package.json

Asegúrate de que `package.json` incluya `express`:

```json
{
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### Después de Configurar

1. Espera 2-5 minutos para que EasyPanel reconstruya la imagen
2. Verifica los logs: `docker service logs checkin24hs_crm --tail 50`
3. Accede a `http://crm.checkin24hs.com` (o HTTPS si está configurado)

