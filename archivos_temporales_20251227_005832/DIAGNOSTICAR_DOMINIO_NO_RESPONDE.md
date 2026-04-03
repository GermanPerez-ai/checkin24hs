# Diagnosticar Dominio que No Responde

## Problema

El dominio `dashboard.checkin24hs.com` está configurado en EasyPanel pero no responde (timeout).

## Diagnóstico

### Paso 1: Verificar Traefik

```bash
# Ver si Traefik está corriendo como servicio
docker service ls | grep traefik

# Ver contenedores de Traefik
docker ps | grep traefik

# Ver logs de Traefik (si está corriendo)
docker service logs traefik --tail 50
```

### Paso 2: Verificar Puertos

```bash
# Ver qué está usando los puertos 80 y 443
sudo lsof -i :80
sudo lsof -i :443

# O con netstat
sudo netstat -tulpn | grep -E "(80|443)"
```

### Paso 3: Verificar Servicio Dashboard

```bash
# Verificar que el servicio dashboard está corriendo
docker service ps checkin24hs_dashboard

# Ver logs del servicio
docker service logs checkin24hs_dashboard --tail 20
```

### Paso 4: Verificar Firewall

```bash
# Ver estado del firewall
sudo ufw status

# Si está activo, permitir puertos 80 y 443
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Paso 5: Verificar DNS

```bash
# Verificar resolución DNS desde el servidor
nslookup dashboard.checkin24hs.com

# O con dig
dig dashboard.checkin24hs.com

# Debería resolver a: 72.61.58.240
```

## Soluciones

### Si Traefik No Está Corriendo

**Opción 1: Dejar que EasyPanel lo gestione**

1. Elimina Traefik manual si existe:
   ```bash
   docker service rm traefik 2>/dev/null || true
   ```

2. En EasyPanel:
   - Ve al servicio "dashboard"
   - Ve a "Dominios"
   - Edita el dominio `dashboard.checkin24hs.com`
   - Guarda los cambios
   - EasyPanel debería iniciar Traefik automáticamente

**Opción 2: Iniciar Traefik manualmente (si EasyPanel no lo hace)**

```bash
# Crear Traefik con configuración simple
docker service create \
  --name traefik \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock:ro \
  traefik:v3.3.7 \
  --providers.docker.swarm=true \
  --providers.docker.exposedbydefault=false

# Verificar
docker service ps traefik
docker service logs traefik --tail 30
```

### Si Traefik Está Corriendo pero No Funciona

1. **Verificar logs de Traefik**:
   ```bash
   docker service logs traefik --tail 100
   ```

2. **Verificar configuración del dominio en EasyPanel**:
   - Ve a "Dominios"
   - Edita `dashboard.checkin24hs.com`
   - Verifica que el puerto destino sea `80`
   - Guarda los cambios

3. **Reiniciar Traefik**:
   ```bash
   docker service update --force traefik
   ```

### Si Hay Problemas de Firewall

```bash
# Permitir puertos HTTP y HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Verificar reglas de iptables
sudo iptables -L -n | grep -E "(80|443)"
```

## Verificar Acceso Directo

Mientras solucionas el dominio, puedes acceder directamente:

```bash
# Ver qué puerto usa el servicio dashboard internamente
docker service inspect checkin24hs_dashboard | grep -A 10 Ports

# O acceder directamente por IP si conoces el puerto
# http://72.61.58.240:PUERTO_INTERNO
```

## Pasos Recomendados

1. **Verificar Traefik**: `docker service ls | grep traefik`
2. **Si no está corriendo**: Eliminar manual y dejar que EasyPanel lo gestione
3. **Verificar firewall**: Permitir puertos 80 y 443
4. **Verificar DNS**: Debe resolver a 72.61.58.240
5. **Esperar 2-3 minutos** después de cualquier cambio
6. **Intentar acceder nuevamente**: http://dashboard.checkin24hs.com

## Notas Importantes

- Traefik es necesario para que los dominios funcionen
- Los puertos 80 y 443 deben estar abiertos en el firewall
- El DNS debe estar configurado correctamente
- EasyPanel debería gestionar Traefik automáticamente


