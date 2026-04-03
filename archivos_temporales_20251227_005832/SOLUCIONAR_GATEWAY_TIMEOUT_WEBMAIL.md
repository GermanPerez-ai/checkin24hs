# Solucionar Gateway Timeout del Webmail

## Problema
Traefik encuentra el servicio webmail pero obtiene un Gateway Timeout, lo que significa que el webmail no responde a tiempo.

## Causas Posibles

1. **Servicio sobrecargado o lento**
2. **Problemas de conectividad entre Traefik y webmail**
3. **Timeout muy corto en Traefik**
4. **Recursos insuficientes (CPU/RAM)**
5. **Problemas con la base de datos de Roundcube**

## Soluciones

### Solución 1: Aumentar Recursos del Servicio

En EasyPanel:
1. Ve a EasyPanel → Servicio `webmail`
2. Ve a "Recursos" o "Resources"
3. Aumenta:
   - **CPU**: Mínimo 1.0 (mejor 2.0)
   - **RAM**: Mínimo 512MB (mejor 1024MB)
4. Guarda y espera a que se actualice

### Solución 2: Aumentar Timeout en Traefik

```bash
# Ver configuración actual de Traefik
docker service inspect traefik --format '{{range .Spec.TaskTemplate.ContainerSpec.Args}}{{.}}{{"\n"}}{{end}}'

# Agregar timeout más largo (si es necesario)
# Esto normalmente se hace desde EasyPanel o la configuración de Traefik
```

### Solución 3: Verificar y Reiniciar el Servicio

```bash
# Reiniciar el servicio webmail
docker service update --force checkin24hs_webmail

# Esperar y verificar
sleep 30
docker service logs checkin24hs_webmail --tail 30
```

### Solución 4: Verificar Base de Datos

El webmail (Roundcube) necesita una base de datos. Verifica:

1. En EasyPanel → Servicio `webmail`
2. Ve a "Variables de Entorno"
3. Verifica que tenga:
   - `ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com`
   - Variables de base de datos si las necesita

### Solución 5: Verificar Logs para Errores Específicos

```bash
# Ver logs completos del webmail
docker service logs checkin24hs_webmail --tail 100

# Buscar errores específicos
docker service logs checkin24hs_webmail --tail 200 | grep -iE "error|timeout|failed|database|connection"
```

## Verificación

Después de aplicar las soluciones:

```bash
# Ver estado del servicio
docker service ps checkin24hs_webmail

# Ver logs recientes
docker service logs checkin24hs_webmail --tail 30

# Verificar respuesta
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID ps aux | grep apache
```

## Nota sobre el Error de Login

Si también tienes errores de "nombre o contraseña inválida", puede ser:
1. **Credenciales incorrectas** - Verifica usuario y contraseña
2. **Configuración de servidor de correo incorrecta** - Verifica las variables de entorno
3. **Problemas de conectividad con el servidor de correo** - Verifica que `mail.checkin24hs.com` sea accesible

## Próximos Pasos

1. Ejecuta el script de diagnóstico para identificar la causa específica
2. Aumenta los recursos del servicio en EasyPanel
3. Verifica los logs para errores específicos
4. Si el problema persiste, verifica la configuración de la base de datos






