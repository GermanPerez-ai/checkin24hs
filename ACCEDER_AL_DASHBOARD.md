# Acceder al Dashboard

## ✅ Estado Actual

El dashboard está corriendo correctamente según los logs de EasyPanel:
- ✅ Servidor iniciado en http://0.0.0.0:3000
- ✅ API disponible
- ✅ Frontend disponible

## Problema

El dominio `dashboard.checkin24hs.com` no está respondiendo (timeout).

## Soluciones

### Opción 1: Acceder Directamente por IP (Más Rápido)

Accede directamente usando la IP del servidor:

```
http://72.61.58.240:3000
```

O si el dashboard está en otro puerto configurado por EasyPanel, verifica en la pestaña "Dominios" de EasyPanel.

### Opción 2: Verificar Configuración de Dominio en EasyPanel

1. En EasyPanel, ve al servicio "dashboard"
2. Ve a la pestaña **"Dominios"**
3. Verifica que `dashboard.checkin24hs.com` esté configurado
4. Si no está, agrégalo:
   - Haz clic en "Agregar dominio"
   - Ingresa: `dashboard.checkin24hs.com`
   - Guarda los cambios

### Opción 3: Verificar Configuración DNS

El dominio necesita apuntar a la IP del servidor:

```bash
# Verificar resolución DNS desde el servidor
nslookup dashboard.checkin24hs.com

# O con dig
dig dashboard.checkin24hs.com

# Debería resolver a: 72.61.58.240
```

**Configuración DNS necesaria:**
- Tipo: A
- Nombre: dashboard (o @)
- Valor: 72.61.58.240
- TTL: 3600 (o el que prefieras)

### Opción 4: Verificar Servicio en Docker Swarm

```bash
# Ver servicios corriendo
docker service ls | grep dashboard

# Ver detalles del servicio
docker service ps checkin24hs_dashboard

# Ver logs del servicio
docker service logs checkin24hs_dashboard --tail 50
```

### Opción 5: Verificar Puerto del Servicio

El dashboard puede estar corriendo en un puerto diferente al 3000. Verifica:

1. En EasyPanel, ve a la pestaña **"Dominios"**
2. Verifica qué puerto está configurado para el servicio
3. O ve a **"Recursos"** para ver la configuración del servicio

## Acceso Directo Temporal

Mientras configuras el dominio, puedes acceder directamente:

```
http://72.61.58.240:PUERTO
```

Donde `PUERTO` es el puerto configurado en EasyPanel para el servicio dashboard.

## Verificar que el Dashboard Funciona

Una vez que accedas (por IP o dominio):

1. El dashboard debería aparecer **sin login**
2. Deberías ver la interfaz completa del dashboard
3. Todas las funcionalidades deberían estar disponibles

## Notas Importantes

- El servicio está corriendo correctamente según los logs
- El problema es solo de acceso/red, no del servicio en sí
- Puedes usar la IP directamente mientras configuras el dominio
- El dominio necesita estar configurado tanto en EasyPanel como en DNS


