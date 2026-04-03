# Usar Traefik v2 (Más Estable)

## Problema

Traefik v3 sigue fallando. Traefik v2 es más estable y usa la sintaxis antigua que funciona mejor.

## Solución: Usar Traefik v2

### Eliminar Traefik v3 y Crear v2

```bash
# 1. Eliminar Traefik v3 fallido
docker service rm traefik

# 2. Crear Traefik v2 (más estable)
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock:ro \
  traefik:v2.10 \
  --providers.docker.swarmmode=true \
  --providers.docker.exposedbydefault=false \
  --log.level=INFO

# 3. Verificar que se creó
docker service ps traefik

# 4. Esperar y ver logs
sleep 10
docker service logs traefik --tail 30
```

### Verificar que Funciona

```bash
# Ver servicios
docker service ls | grep traefik

# Ver estado
docker service ps traefik

# Ver logs (debería estar sin errores)
docker service logs traefik --tail 50

# Verificar puertos
sudo lsof -i :80
sudo lsof -i :443

# Probar conexión local
curl -I http://localhost
```

## Después de Iniciar Traefik v2

1. **Espera 1-2 minutos** para que Traefik se inicialice completamente

2. **En EasyPanel**:
   - Ve al servicio "dashboard"
   - Ve a "Dominios"
   - Edita `dashboard.checkin24hs.com`
   - Guarda los cambios nuevamente

3. **Espera 1-2 minutos** más para que Traefik detecte el dominio

4. **Intenta acceder**: http://dashboard.checkin24hs.com

## Diferencias entre v2 y v3

- **v2**: Usa `--providers.docker.swarmmode=true`
- **v3**: Usa `--providers.docker.swarm=true` (pero parece tener problemas)
- **v2**: Más estable y probado
- **v3**: Más nuevo pero puede tener problemas de compatibilidad

## Si Traefik v2 También Falla

Si incluso v2 falla, puede ser un problema más profundo:

1. **Verificar versión de Docker**:
   ```bash
   docker --version
   docker info | grep -i swarm
   ```

2. **Verificar permisos del Docker socket**:
   ```bash
   ls -la /var/run/docker.sock
   ```

3. **Intentar sin Swarm mode** (solo Docker):
   ```bash
   docker run -d \
     --name traefik \
     --restart unless-stopped \
     -p 80:80 \
     -p 443:443 \
     -v /var/run/docker.sock:/var/run/docker.sock:ro \
     traefik:v2.10 \
     --providers.docker=true \
     --providers.docker.exposedbydefault=false
   ```

## Notas Importantes

- Traefik v2 es más estable que v3
- La sintaxis `swarmmode` funciona mejor en v2
- Una vez que Traefik esté corriendo, debería detectar automáticamente los servicios
- EasyPanel puede necesitar que Traefik esté corriendo antes de configurar dominios


