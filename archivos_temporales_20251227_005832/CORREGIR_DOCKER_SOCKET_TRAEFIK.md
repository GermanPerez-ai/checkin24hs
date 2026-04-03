# Corregir Acceso al Docker Socket en Traefik

## Problema

Traefik está corriendo pero no puede acceder al Docker socket:
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

## Solución: Corregir el Mount del Socket

### Paso 1: Eliminar Servicio Actual

```bash
docker service rm traefik
```

### Paso 2: Crear con Mount Correcto

En Docker Swarm, el mount del socket necesita configuración especial:

```bash
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  traefik:v2.10 \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false \
  --providers.docker.endpoint=unix:///var/run/docker.sock \
  --log.level=INFO
```

### Paso 3: Verificar

```bash
# Esperar a que se inicie
sleep 10

# Ver logs (no debería haber errores de conexión)
docker service logs traefik --tail 30

# Verificar estado
docker service ps traefik
```

## Alternativa: Usar Tipo de Mount Diferente

Si el problema persiste, intenta con `type=volume`:

```bash
docker service rm traefik

docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly=false \
  traefik:v2.10 \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false \
  --log.level=INFO
```

## Verificar Permisos del Socket

```bash
# Ver permisos del Docker socket
ls -la /var/run/docker.sock

# Si es necesario, ajustar permisos (cuidado con esto)
sudo chmod 666 /var/run/docker.sock
```

## Después de Corregir

1. **Espera 1-2 minutos** para que Traefik se conecte correctamente
2. **Verifica logs**: No debería haber más errores de conexión
3. **En EasyPanel**:
   - Ve al servicio "dashboard"
   - Ve a "Dominios"
   - Edita `dashboard.checkin24hs.com`
   - Guarda los cambios
4. **Espera 1-2 minutos** más
5. **Intenta acceder**: http://dashboard.checkin24hs.com

## Notas Importantes

- En Docker Swarm, el mount del socket puede necesitar configuración especial
- El socket debe estar montado correctamente para que Traefik detecte servicios
- Una vez que Traefik se conecte, debería detectar automáticamente el servicio dashboard


