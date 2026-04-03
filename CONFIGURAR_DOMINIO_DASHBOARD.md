# Configurar Dominio para el Dashboard

## Estado Actual

- ✅ **DNS configurado**: `dashboard.checkin24hs.com` → `72.61.58.240`
- ✅ **Puerto 3000**: Usado por EasyPanel
- ✅ **Dashboard corriendo**: Según logs de EasyPanel

## Problema

El dominio no está configurado en EasyPanel para que enrute al servicio dashboard.

## Solución

### Paso 1: Verificar Puerto del Servicio Dashboard

Ejecuta en el servidor:

```bash
# Ver servicios corriendo
docker service ls | grep dashboard

# Ver detalles del servicio
docker service ps checkin24hs_dashboard

# Ver puertos del servicio
docker service inspect checkin24hs_dashboard | grep -A 10 Ports

# O ver todos los puertos en uso
sudo netstat -tulpn | grep LISTEN
```

### Paso 2: Configurar Dominio en EasyPanel

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

4. **EasyPanel configurará automáticamente**
   - EasyPanel usará Traefik (su proxy inverso) para enrutar el dominio
   - Traefik escucha en los puertos 80 y 443
   - El dominio se enrutará automáticamente al servicio dashboard

### Paso 3: Verificar Configuración de Traefik

EasyPanel usa Traefik como proxy inverso. Verifica:

```bash
# Ver contenedor de Traefik
docker ps | grep traefik

# Ver logs de Traefik
docker logs traefik --tail 50

# Ver configuración de Traefik
docker exec traefik cat /etc/traefik/traefik.yml
```

### Paso 4: Verificar que el Dominio Funciona

Después de configurar el dominio en EasyPanel:

1. Espera 1-2 minutos para que Traefik actualice la configuración
2. Intenta acceder: **http://dashboard.checkin24hs.com**
3. O con HTTPS si está configurado: **https://dashboard.checkin24hs.com**

## Configuración DNS Necesaria

Ya tienes configurado:
- ✅ Tipo: A
- ✅ Nombre: dashboard
- ✅ Valor: 72.61.58.240

## Notas Importantes

- EasyPanel usa Traefik como proxy inverso
- Traefik escucha en puertos 80 (HTTP) y 443 (HTTPS)
- El dominio debe estar configurado en EasyPanel, no solo en DNS
- EasyPanel creará automáticamente las reglas de enrutamiento en Traefik

## Si el Dominio No Funciona

### Verificar que Traefik Está Corriendo

```bash
docker ps | grep traefik
docker logs traefik --tail 50
```

### Verificar Reglas de Traefik

```bash
# Ver configuración de Traefik
docker exec traefik cat /etc/traefik/dynamic/*.yml 2>/dev/null || echo "No hay configuración dinámica"
```

### Verificar Firewall

```bash
# Verificar que los puertos 80 y 443 están abiertos
sudo ufw status
sudo iptables -L -n | grep -E "(80|443)"
```

## Acceso Temporal

Mientras configuras el dominio, puedes acceder directamente al servicio si conoces su puerto:

```
http://72.61.58.240:PUERTO_DEL_SERVICIO
```

Pero lo ideal es usar el dominio configurado en EasyPanel para que Traefik maneje el enrutamiento.
