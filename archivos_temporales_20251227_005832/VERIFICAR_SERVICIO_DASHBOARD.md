# Verificar Servicio Dashboard

## ✅ Estado Actual

- ✅ **Servicio corriendo**: 1/1 réplicas
- ✅ **Estado**: Running
- ✅ **DNS configurado**: dashboard.checkin24hs.com → 72.61.58.240

## Verificar Configuración del Servicio

### Ver Puertos del Servicio

```bash
# Ver puertos del servicio
docker service inspect checkin24hs_dashboard --format "{{.Endpoint.Ports}}"

# O ver detalles completos
docker service inspect checkin24hs_dashboard | grep -A 20 Ports

# Ver configuración completa
docker service inspect checkin24hs_dashboard
```

### Ver Logs del Servicio

```bash
# Ver logs recientes
docker service logs checkin24hs_dashboard --tail 20

# Ver logs en tiempo real
docker service logs -f checkin24hs_dashboard
```

### Ver Contenedor del Servicio

```bash
# Ver contenedores del servicio
docker ps | grep dashboard

# Ver logs del contenedor
docker logs $(docker ps | grep dashboard | awk '{print $1}') --tail 20
```

## Configurar Dominio en EasyPanel

### Pasos en EasyPanel

1. **Acceder a EasyPanel**
   - Ve a: http://72.61.58.240:3000
   - Inicia sesión si es necesario

2. **Ir al servicio dashboard**
   - Ve al proyecto "checkin24hs"
   - Haz clic en el servicio "dashboard"

3. **Configurar dominio**
   - Ve a la pestaña **"Dominios"**
   - Haz clic en **"Agregar dominio"** o **"+"**
   - Ingresa: `dashboard.checkin24hs.com`
   - Guarda los cambios

4. **Esperar actualización**
   - Espera 1-2 minutos para que Traefik actualice la configuración
   - Traefik es el proxy inverso que maneja el enrutamiento

5. **Acceder al dominio**
   - Intenta acceder: **http://dashboard.checkin24hs.com**
   - El dashboard debería aparecer sin login

## Verificar Traefik (Proxy Inverso)

EasyPanel usa Traefik para enrutar los dominios. Verifica:

```bash
# Ver contenedor de Traefik
docker ps | grep traefik

# Ver logs de Traefik
docker logs traefik --tail 50

# Ver configuración de Traefik
docker exec traefik cat /etc/traefik/traefik.yml 2>/dev/null || echo "No hay archivo de configuración estática"

# Ver reglas dinámicas (donde están los dominios)
docker exec traefik ls -la /etc/traefik/dynamic/ 2>/dev/null || echo "No hay configuración dinámica"
```

## Verificar Puertos del Host

```bash
# Ver qué puertos están en uso
sudo netstat -tulpn | grep LISTEN | grep -E "(80|443|3000)"

# Verificar que Traefik está escuchando en 80 y 443
sudo lsof -i :80
sudo lsof -i :443
```

## Solución de Problemas

### Si el dominio no funciona después de configurarlo:

1. **Verificar que Traefik está corriendo**
   ```bash
   docker ps | grep traefik
   ```

2. **Verificar logs de Traefik**
   ```bash
   docker logs traefik --tail 100
   ```

3. **Verificar que el dominio está en la configuración de Traefik**
   - Los dominios se configuran automáticamente cuando los agregas en EasyPanel
   - Traefik debería detectar el servicio y crear las reglas de enrutamiento

4. **Verificar firewall**
   ```bash
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

### Si necesitas acceder directamente al servicio:

Si conoces el puerto interno del servicio, puedes acceder directamente:

```
http://72.61.58.240:PUERTO_INTERNO
```

Pero lo ideal es usar el dominio configurado en EasyPanel.

## Notas Importantes

- EasyPanel usa Traefik como proxy inverso
- Traefik escucha en puertos 80 (HTTP) y 443 (HTTPS)
- Los dominios se configuran automáticamente cuando los agregas en EasyPanel
- Traefik detecta los servicios y crea las reglas de enrutamiento automáticamente
- El DNS ya está configurado correctamente


