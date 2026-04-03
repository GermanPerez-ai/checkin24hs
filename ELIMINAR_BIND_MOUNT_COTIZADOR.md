# 🔧 Eliminar Bind Mount del Cotizador

## 🎯 Problema Identificado

El servicio del cotizador tiene un **bind mount** que está sobrescribiendo los archivos copiados por el Dockerfile:

- **Bind mount:** `/root/checkin24hs` → `/usr/share/nginx/html`
- **Problema:** Este mount hace que el contenedor use los archivos del servidor host (que incluyen `index.html` obsoleto) en lugar de los archivos copiados por el Dockerfile durante la construcción.

## ✅ Solución: Eliminar el Bind Mount

### Paso 1: Acceder a EasyPanel

1. Ve a: `http://72.61.58.240:3000`
2. Inicia sesión

### Paso 2: Ir al Servicio del Cotizador

1. Busca el servicio `cotizador` en el proyecto `checkin24hs`
2. Haz clic en él

### Paso 3: Eliminar el Bind Mount

1. Ve a la pestaña **"Puntos de montaje"** o **"Mount points"**
2. Busca el bind mount que muestra:
   - **Origen (Host):** `/root/checkin24hs`
   - **Destino (Container):** `/usr/share/nginx/html`
3. Haz clic en el botón **"Eliminar"** o **"Delete"** junto a ese bind mount
4. Confirma la eliminación

### Paso 4: Reconstruir el Servicio

Después de eliminar el bind mount:

1. Ve a la pestaña **"Implementaciones"** o **"Deployments"**
2. Haz clic en **"Reconstruir"** o **"Rebuild"**
3. Espera 2-5 minutos a que termine la compilación

**Importante:** El Dockerfile copiará `cotizador-cliente.html` como `index.html` durante la construcción, y ahora no será sobrescrito por el bind mount.

### Paso 5: Volver a Configurar Traefik

Después de reconstruir, las etiquetas de Traefik se pierden. Vuelve a configurarlas:

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.cotizador.service=cotizador-service" \
  --label-add "traefik.http.services.cotizador-service.loadbalancer.server.port=80" \
  --label-add "traefik.docker.network=easypanel" \
  checkin24hs_cotizador
```

### Paso 6: Verificar

1. Espera 1-2 minutos después de configurar Traefik
2. Prueba acceder a: `https://cotizar.checkin24hs.com/`
3. Debe mostrar el formulario de cotización (NO el archivo obsoleto)

---

## 🔍 Verificación Adicional

Para verificar que el bind mount fue eliminado:

```bash
# Verificar que no hay bind mounts en el servicio
docker service inspect checkin24hs_cotizador --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Source}}:{{.Target}} {{end}}'
```

Si no muestra nada (o solo muestra volúmenes, no bind mounts), está correcto.

---

## 📝 Resumen

**Problema:** Bind mount sobrescribe archivos del Dockerfile  
**Solución:** Eliminar el bind mount y reconstruir el servicio  
**Resultado:** El contenedor usará los archivos copiados por el Dockerfile
