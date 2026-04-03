# 🔧 Agregar Alias con Guión Bajo al Servicio Docker

## 🎯 Problema Final

- EasyPanel genera: `http://checkin24hs_dashboard:80/` (guión bajo)
- Alias real: `checkin24hs-dashboard` (guión)
- Necesitamos agregar: `checkin24hs_dashboard` (guión bajo)

## ✅ Solución: Modificar el Servicio Docker Directamente

Necesitamos actualizar el servicio para agregar el alias con guión bajo. Esto requiere modificar la configuración de red del servicio.

### Paso 1: Obtener la Configuración Actual del Servicio

En el servidor, ejecuta:

```bash
# Obtener la configuración completa del servicio
docker service inspect checkin24hs_dashboard > service_config.json
cat service_config.json | jq '.Spec.TaskTemplate.Networks'
```

### Paso 2: Actualizar el Servicio con el Alias Correcto

Necesitamos remover las redes actuales y agregarlas de nuevo con todos los aliases, incluyendo el que falta.

Ejecuta estos comandos (reemplaza los IDs de red con los que obtuviste):

```bash
# Para la primera red (xmv09tpxwryie79b0jv531623)
docker service update \
  --network-rm xmv09tpxwryie79b0jv531623 \
  --network-add target=xmv09tpxwryie79b0jv531623,aliases=checkin24hs-dashboard,aliases=checkin24hs_dashboard \
  checkin24hs_dashboard

# Para la segunda red (nvhtv52umzihypz8u7adejvpo)
docker service update \
  --network-rm nvhtv52umzihypz8u7adejvpo \
  --network-add target=nvhtv52umzihypz8u7adejvpo,aliases=checkin24hs-dashboard,aliases=dashboard,aliases=checkin24hs_dashboard \
  checkin24hs_dashboard
```

**Nota**: La sintaxis puede variar. Si estos comandos no funcionan, necesitamos usar un enfoque diferente.

### Paso 3: Verificar que el Alias se Agregó

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Deberías ver `checkin24hs_dashboard` (con guión bajo) en la lista de aliases.

### Paso 4: Probar el Dominio

1. Espera 30-60 segundos para que el servicio se actualice
2. Prueba acceder a: `https://dashboard.checkin24hs.com/`
3. **¿Funciona?**

---

## 🔄 Alternativa: Si los Comandos No Funcionan

Si los comandos de `docker service update` no funcionan con la sintaxis de aliases, podemos intentar:

1. **Recrear el servicio** con la configuración correcta desde el inicio
2. O **contactar soporte de EasyPanel** para que permitan especificar el alias manualmente

---

**Ejecuta primero el comando para obtener la configuración y luego intenta actualizar el servicio con los aliases correctos.**
