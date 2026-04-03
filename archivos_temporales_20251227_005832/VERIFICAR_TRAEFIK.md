# Verificar Traefik (Proxy Inverso)

## Estado Actual

- ✅ **Servicio dashboard**: Corriendo correctamente
- ✅ **Logs**: Servidor escuchando en 0.0.0.0:3000
- ⚠️ **Traefik**: No aparece en contenedores corriendo

## Verificar Traefik

### Ver Servicios de Swarm

```bash
# Ver todos los servicios de Swarm
docker service ls

# Ver si Traefik está como servicio
docker service ls | grep traefik

# Ver detalles del servicio Traefik (si existe)
docker service ps traefik
```

### Ver Contenedores de Traefik

```bash
# Ver contenedores corriendo
docker ps | grep traefik

# Ver todos los contenedores (incluyendo detenidos)
docker ps -a | grep traefik
```

### Verificar Puertos 80 y 443

```bash
# Ver qué está usando los puertos 80 y 443
sudo lsof -i :80
sudo lsof -i :443

# O con netstat
sudo netstat -tulpn | grep -E "(80|443)"
```

## Si Traefik No Está Corriendo

EasyPanel debería iniciar Traefik automáticamente. Si no está corriendo:

### Opción 1: Iniciar desde EasyPanel

1. Ve a EasyPanel: http://72.61.58.240:3000
2. Busca la configuración de Traefik o servicios del sistema
3. Inicia Traefik desde ahí

### Opción 2: Iniciar Manualmente

Si EasyPanel tiene un comando para iniciar Traefik:

```bash
# Ver si hay un script de EasyPanel
ls -la /etc/easypanel/

# O iniciar Traefik manualmente (si conoces la configuración)
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  traefik:v2.9
```

### Opción 3: Verificar Configuración de EasyPanel

EasyPanel puede tener Traefik configurado de manera diferente. Verifica:

```bash
# Ver configuración de EasyPanel
cat /etc/easypanel/config.json 2>/dev/null || echo "No hay archivo de configuración"

# Ver logs de EasyPanel
docker logs easypanel --tail 100 | grep -i traefik
```

## Configurar Dominio en EasyPanel

Mientras verificas Traefik, puedes configurar el dominio en EasyPanel:

1. Ve a EasyPanel: http://72.61.58.240:3000
2. Ve al servicio "dashboard"
3. Ve a la pestaña **"Dominios"**
4. Agrega: `dashboard.checkin24hs.com`
5. Guarda los cambios

EasyPanel debería iniciar Traefik automáticamente si no está corriendo.

## Notas Importantes

- Traefik es necesario para que los dominios funcionen
- EasyPanel debería gestionar Traefik automáticamente
- Si Traefik no está corriendo, los dominios no funcionarán
- El servicio dashboard está corriendo correctamente, solo necesita Traefik para el enrutamiento

## Acceso Directo Temporal

Mientras configuras Traefik, puedes acceder directamente al servicio si expones el puerto:

```bash
# Verificar si el servicio tiene puertos expuestos
docker service inspect checkin24hs_dashboard | grep -A 10 Ports
```

Pero lo ideal es usar Traefik con el dominio configurado.


