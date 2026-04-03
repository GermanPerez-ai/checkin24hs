# Usar Versión Reciente de Traefik

## Problema

Traefik v2.10 es muy antiguo y usa la API de Docker 1.24, pero el servidor Docker requiere mínimo API 1.44.

Error: `client version 1.24 is too old. Minimum supported API version is 1.44`

## Solución: Usar Traefik v2.11 o Superior

### Verificar Versión de Docker

```bash
docker --version
docker info | grep "Server Version"
```

### Opción 1: Traefik v2.11 (Más Reciente de v2)

```bash
# Eliminar Traefik v2.10
docker service rm traefik

# Crear con Traefik v2.11
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  traefik:v2.11 \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false \
  --log.level=INFO

# Verificar
sleep 10
docker service logs traefik --tail 30
```

### Opción 2: Traefik Latest (v2 más reciente)

```bash
docker service rm traefik

docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  traefik:latest \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false \
  --log.level=INFO
```

### Opción 3: Traefik v3 con Configuración Correcta

Si las versiones v2 no funcionan, intenta v3 con configuración específica:

```bash
docker service rm traefik

docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  traefik:v3.3.7 \
  --providers.docker.swarm=true \
  --providers.docker.exposedbydefault=false \
  --log.level=INFO
```

## Verificar que Funciona

Después de crear el servicio:

```bash
# Ver servicios
docker service ls | grep traefik

# Ver estado
docker service ps traefik

# Ver logs (no debería haber errores de versión)
docker service logs traefik --tail 50

# Verificar puertos
sudo lsof -i :80
sudo lsof -i :443
```

## Después de Iniciar Traefik Correctamente

1. **Espera 1-2 minutos** para que Traefik se inicialice
2. **Verifica logs**: No debería haber errores de versión de API
3. **En EasyPanel**:
   - Ve al servicio "dashboard"
   - Ve a "Dominios"
   - Edita `dashboard.checkin24hs.com`
   - Guarda los cambios
4. **Espera 1-2 minutos** más
5. **Intenta acceder**: http://dashboard.checkin24hs.com

## Notas sobre Versiones

- **Traefik v2.10**: Muy antiguo, API Docker 1.24 (incompatible)
- **Traefik v2.11+**: Más reciente, compatible con Docker moderno
- **Traefik v3**: Más nuevo pero puede tener problemas de sintaxis
- **Docker 29.1.3**: Requiere API mínimo 1.44

## Recomendación

Usa Traefik v2.11 o `traefik:latest` (que será la versión más reciente de v2) para tener compatibilidad con Docker moderno pero mantener la sintaxis estable de v2.


