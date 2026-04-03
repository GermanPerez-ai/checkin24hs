# Solucionar Error DNS para CRM

## Problema
El error `DNS_PROBE_FINISHED_NXDOMAIN` significa que el dominio `crm.checkin24hs.com` no está configurado en el DNS.

## Solución 1: Configurar DNS (Recomendado)

### Paso 1: Verificar configuración en EasyPanel

1. Ve a EasyPanel → Servicio `crm`
2. Ve a la sección "Dominios" o "Domains"
3. Verifica que `crm.checkin24hs.com` esté agregado
4. Si no está, agrégalo

### Paso 2: Configurar DNS en tu proveedor de dominio

Necesitas agregar un registro DNS tipo **A** o **CNAME**:

**Opción A: Registro A (si tienes la IP del servidor)**
```
Tipo: A
Nombre: crm
Valor: [IP del servidor]
TTL: 3600 (o el que recomiende tu proveedor)
```

**Opción B: Registro CNAME (si usas un subdominio)**
```
Tipo: CNAME
Nombre: crm
Valor: checkin24hs.com (o el dominio principal)
TTL: 3600
```

### Paso 3: Obtener la IP del servidor

En el servidor, ejecuta:

```bash
# Ver IP pública del servidor
curl ifconfig.me

# O verificar IPs de las interfaces
ip addr show | grep "inet " | grep -v "127.0.0.1"
```

## Solución 2: Acceso Temporal por IP

Mientras configuras el DNS, puedes acceder temporalmente usando la IP del servidor:

1. Obtén la IP del servidor (ver arriba)
2. Verifica el puerto que usa EasyPanel para el CRM
3. Accede a: `http://[IP_DEL_SERVIDOR]:[PUERTO]`

## Solución 3: Verificar Configuración de Traefik

Si el dominio está configurado pero no funciona, verifica Traefik:

```bash
# Ver configuración del servicio CRM
docker service inspect checkin24hs_crm --format '{{json .Spec.Labels}}' | grep -i traefik

# Ver logs de Traefik
docker service logs traefik --tail 50 | grep -i crm
```

## Solución 4: Usar el mismo dominio del dashboard

Si `dashboard.checkin24hs.com` funciona, puedes:

1. Configurar `crm.checkin24hs.com` de la misma manera
2. O usar una ruta diferente: `dashboard.checkin24hs.com/crm` (requiere configuración adicional)

## Verificación

Después de configurar el DNS:

1. Espera 5-15 minutos para que el DNS se propague
2. Verifica con: `nslookup crm.checkin24hs.com`
3. Intenta acceder desde el navegador

## Nota Importante

El servicio CRM está funcionando correctamente (vimos los logs). El problema es solo de DNS/dominio. Una vez que configures el DNS, debería funcionar inmediatamente.






