# Solución: Traefik No Detecta el Webmail

## Problema
Las etiquetas de Traefik están configuradas, pero Traefik no está detectando el servicio webmail.

## Soluciones

### Solución 1: Reiniciar Traefik

A veces Traefik necesita reiniciarse para detectar nuevos servicios:

```bash
# Reiniciar Traefik
docker service update --force traefik

# Esperar 30 segundos
sleep 30

# Verificar logs
docker service logs traefik --tail 50 | grep -i webmail
```

### Solución 2: Verificar Versión de Traefik

Traefik v2 usa una sintaxis diferente para las etiquetas. Verifica la versión:

```bash
docker service logs traefik --tail 5 | head -1
```

Si es Traefik v2, las etiquetas deberían ser:
- `traefik.enable=true`
- `traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)`
- `traefik.http.routers.webmail.entrypoints=web`
- `traefik.http.services.webmail.loadbalancer.server.port=80`

### Solución 3: Verificar que Estén en la Misma Red

```bash
# Ver redes del webmail
docker service inspect checkin24hs_webmail --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

# Ver redes de Traefik
docker service inspect traefik --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

# Deben ser iguales
```

### Solución 4: Configurar desde EasyPanel (Recomendado)

En lugar de usar comandos Docker, configura desde EasyPanel:

1. Ve a EasyPanel → Servicio `webmail`
2. Ve a la sección "Dominios"
3. Verifica que `webmail.checkin24hs.com` esté configurado
4. Si no está, agrégalo:
   - Dominio: `webmail.checkin24hs.com`
   - Puerto interno: `80`
5. Guarda los cambios
6. Espera 1-2 minutos

EasyPanel debería configurar Traefik automáticamente.

### Solución 5: Verificar Configuración de Traefik

Si Traefik está usando configuración estática, puede que necesites agregar el servicio manualmente:

```bash
# Ver configuración de Traefik
docker exec $(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1) cat /etc/traefik/traefik.yml 2>&1 | head -30
```

## Verificación Final

Después de aplicar las soluciones:

```bash
# Ver logs de Traefik
docker service logs traefik --tail 200 | grep -i webmail

# Verificar acceso
curl -I http://webmail.checkin24hs.com
```

## Nota Importante

Si configuraste las etiquetas manualmente pero EasyPanel también gestiona los dominios, puede haber conflicto. Es mejor usar **solo EasyPanel** para configurar dominios, ya que lo hace automáticamente.






