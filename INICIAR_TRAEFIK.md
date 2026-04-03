# Iniciar Traefik para EasyPanel

## Problema

Traefik no está corriendo. Hay contenedores en estado "Dead" pero no hay servicio activo.

## Solución

### Opción 1: Dejar que EasyPanel Gestione Traefik (Recomendado)

EasyPanel debería gestionar Traefik automáticamente. Intenta:

1. Ve a EasyPanel: http://72.61.58.240:3000
2. Ve al servicio "dashboard"
3. Ve a la pestaña **"Dominios"**
4. Agrega: `dashboard.checkin24hs.com`
5. Guarda los cambios

EasyPanel debería detectar que Traefik no está corriendo y lo iniciará automáticamente.

### Opción 2: Iniciar Traefik Manualmente como Servicio de Swarm

Si EasyPanel no lo inicia automáticamente:

```bash
# 1. Eliminar contenedores muertos
docker rm traefik 2>/dev/null || true
docker rm $(docker ps -a | grep traefik | awk '{print $1}') 2>/dev/null || true

# 2. Crear servicio de Traefik en Swarm
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock:ro \
  --network easypanel \
  traefik:v3.3.7 \
  --api.insecure=true \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false \
  --entrypoints.web.address=:80 \
  --entrypoints.websecure.address=:443

# 3. Verificar que se creó
docker service ls | grep traefik
docker service ps traefik

# 4. Esperar a que se inicie
sleep 10

# 5. Verificar logs
docker service logs traefik --tail 30
```

### Opción 3: Usar el Comando de Instalación de EasyPanel

EasyPanel puede tener un comando para reinstalar Traefik:

```bash
# Ver si hay scripts de EasyPanel
ls -la /etc/easypanel/

# O ejecutar el setup de EasyPanel nuevamente
docker run --rm -it \
  -v /etc/easypanel:/etc/easypanel \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  easypanel/easypanel setup
```

### Opción 4: Verificar Configuración de EasyPanel

EasyPanel puede tener Traefik configurado de manera diferente:

```bash
# Ver logs de EasyPanel para errores relacionados con Traefik
docker logs easypanel --tail 100 | grep -i traefik

# Ver configuración de EasyPanel
cat /etc/easypanel/config.json 2>/dev/null || echo "No hay archivo de configuración"
```

## Verificar que Traefik Está Corriendo

Después de iniciar Traefik:

```bash
# Ver servicios de Swarm
docker service ls | grep traefik

# Ver contenedores
docker ps | grep traefik

# Ver logs
docker service logs traefik --tail 30

# Verificar puertos
sudo lsof -i :80
sudo lsof -i :443
```

## Configurar Dominio en EasyPanel

Una vez que Traefik esté corriendo:

1. Ve a EasyPanel: http://72.61.58.240:3000
2. Ve al servicio "dashboard"
3. Ve a la pestaña **"Dominios"**
4. Agrega: `dashboard.checkin24hs.com`
5. Guarda los cambios

Traefik debería detectar automáticamente el servicio y crear las reglas de enrutamiento.

## Notas Importantes

- Traefik es esencial para que los dominios funcionen
- EasyPanel debería gestionar Traefik automáticamente
- Si Traefik no está corriendo, los dominios no funcionarán
- El servicio dashboard está corriendo correctamente

## Solución Rápida

La forma más fácil es agregar el dominio en EasyPanel y dejar que EasyPanel gestione Traefik automáticamente. Si eso no funciona, entonces inicia Traefik manualmente con el comando de la Opción 2.


