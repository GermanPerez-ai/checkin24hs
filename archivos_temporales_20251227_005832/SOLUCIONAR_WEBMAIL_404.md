# Solucionar Error 404 del Webmail

## Diagnóstico Rápido

Ejecuta estos comandos en el servidor:

```bash
# 1. Ver estado del servicio webmail
docker service ps checkin24hs_webmail --no-trunc | head -10

# 2. Ver logs del webmail
docker service logs checkin24hs_webmail --tail 30

# 3. Ver configuración de Traefik para webmail
docker service inspect checkin24hs_webmail --format '{{json .Spec.Labels}}' | grep -i traefik

# 4. Verificar contenedores corriendo
docker ps --filter "name=webmail" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"

# 5. Verificar conectividad interna
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Verificando respuesta del servidor interno:"
    docker exec $CONTAINER_ID wget -qO- --timeout=5 http://localhost:80 2>&1 | head -10
fi
```

## Soluciones Comunes

### Problema 1: Servicio no está corriendo

**Solución:**
```bash
# Reiniciar el servicio
docker service update --force checkin24hs_webmail

# Esperar y verificar
sleep 30
docker service ps checkin24hs_webmail
```

### Problema 2: Configuración de Traefik incorrecta

**Solución en EasyPanel:**
1. Ve a EasyPanel → Servicio `webmail`
2. Ve a la sección "Dominios"
3. Verifica que `webmail.checkin24hs.com` esté configurado correctamente
4. Verifica que el puerto interno sea `80`
5. Guarda los cambios

### Problema 3: Puerto incorrecto en la configuración

**Verificar:**
```bash
# Ver puertos del servicio
docker service inspect checkin24hs_webmail --format '{{json .Endpoint.Ports}}' | jq '.'
```

**Si el puerto es incorrecto:**
1. Ve a EasyPanel → Servicio `webmail`
2. Ve a "Puertos"
3. Cambia el puerto interno a `80`
4. Guarda y espera a que se actualice

### Problema 4: El servicio está corriendo pero Traefik no lo encuentra

**Solución:**
```bash
# Verificar que estén en la misma red
docker service inspect checkin24hs_webmail --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'
docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

# Si están en redes diferentes, agregar webmail a la red de Traefik
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
docker service update --network-add $EASYPANEL_NET checkin24hs_webmail
```

## Verificación Final

Después de aplicar las soluciones:

1. **Verifica logs:**
   ```bash
   docker service logs checkin24hs_webmail --tail 20
   ```

2. **Verifica estado:**
   ```bash
   docker service ps checkin24hs_webmail
   ```

3. **Intenta acceder:**
   - `http://webmail.checkin24hs.com`
   - O verifica el dominio configurado en EasyPanel

## Si el problema persiste

Comparte la salida de los comandos de diagnóstico para identificar el problema específico.






