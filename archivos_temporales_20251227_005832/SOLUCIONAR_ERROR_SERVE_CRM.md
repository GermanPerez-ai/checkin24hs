# Solucionar Error: Cannot find module '/app/serve-crm.js'

## Problema
El servicio CRM está intentando ejecutar `node serve-crm.js` pero el archivo no está en la imagen Docker.

## Solución Rápida (Temporal)

### Paso 1: Subir archivos al servidor

```bash
# Desde tu máquina local, conecta al servidor y copia los archivos:
scp serve-crm.js root@TU_SERVIDOR:/root/checkin24hs/
scp Dockerfile.crm root@TU_SERVIDOR:/root/checkin24hs/
scp APLICAR_SERVE_CRM_SERVIDOR.sh root@TU_SERVIDOR:/root/checkin24hs/
```

### Paso 2: Aplicar en el servidor

```bash
# En el servidor:
cd /root/checkin24hs
chmod +x APLICAR_SERVE_CRM_SERVIDOR.sh
./APLICAR_SERVE_CRM_SERVIDOR.sh
```

## Solución Permanente: Configurar Dockerfile en EasyPanel

### Paso 1: Agregar archivos a Git

```bash
# En tu máquina local:
git add Dockerfile.crm serve-crm.js
git commit -m "Agregar Dockerfile y serve-crm.js para CRM"
git push
```

### Paso 2: Configurar en EasyPanel

1. **Ve a EasyPanel → Servicio `crm`**
2. **Ve a la pestaña "Fuente" o "Source"**
3. **Configuración:**
   - **Tipo de compilación**: Cambia a `Dockerfile`
   - **Archivo Dockerfile**: `Dockerfile.crm`
   - **Puerto**: `3005`
   - **Dominio**: `crm.checkin24hs.com`
4. **Guarda los cambios**
5. **Espera 2-5 minutos** para que EasyPanel reconstruya la imagen

### Paso 3: Verificar

```bash
# En el servidor, verifica los logs:
docker service logs checkin24hs_crm --tail 50

# Deberías ver:
# 🚀 CRM corriendo en http://0.0.0.0:3005
```

## Archivos Necesarios

Asegúrate de que estos archivos estén en el repositorio:

- ✅ `Dockerfile.crm` (nuevo)
- ✅ `serve-crm.js`
- ✅ `deploy/crm.html`
- ✅ `deploy/crm.js`
- ✅ `package.json` (ya tiene `express`)

## Notas

- El `package.json` ya incluye `express`, así que no necesitas modificarlo
- El Dockerfile copiará `deploy/crm.html` como `crm.html` en la raíz del contenedor
- El Dockerfile copiará `deploy/crm.js` como `crm.js` en la raíz del contenedor
- Si tienes problemas, verifica que todos los archivos estén en Git antes de reconstruir

