# 🔧 Solución: Recrear Servicio con Puerto Diferente

## 🚨 Problema

El puerto 3000 no se puede eliminar correctamente y sigue en modo "host". Además, hay instancias antiguas corriendo.

## ✅ Solución: Usar Puerto 30000 (Externo) -> 3000 (Interno)

Como el puerto 3000 está ocupado por EasyPanel, usaremos el puerto 30000 externamente pero el servicio seguirá escuchando en 3000 internamente.

### Opción 1: Actualizar el Servicio (Sin Eliminarlo)

```bash
# 1. Escalar a 0 para detener todas las instancias
docker service scale checkin24hs_dashboard=0
sleep 10

# 2. Verificar que se detuvo
docker service ps checkin24hs_dashboard

# 3. Intentar eliminar el puerto con formato completo
docker service update \
  --publish-rm published=3000,target=3000,protocol=tcp \
  checkin24hs_dashboard 2>/dev/null || echo "Puerto no existe o ya fue eliminado"

# 4. Esperar
sleep 5

# 5. Agregar puerto 30000 (externo) -> 3000 (interno) en modo ingress
docker service update \
  --publish-add published=30000,target=3000,protocol=tcp,mode=ingress \
  checkin24hs_dashboard

# 6. Esperar
sleep 5

# 7. Verificar
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 8. Escalar de nuevo
docker service scale checkin24hs_dashboard=1
sleep 15

# 9. Verificar estado
docker service ps checkin24hs_dashboard

# 10. Ver logs
docker service logs checkin24hs_dashboard --tail 10

# 11. Probar conexión (usando el puerto 30000)
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:30000 2>&1 | head -20
```

### Opción 2: Eliminar y Recrear el Servicio (Desde EasyPanel)

Si la opción 1 no funciona, la mejor solución es recrear el servicio desde EasyPanel:

1. **Ve a EasyPanel** → **Servicios** → **dashboard**
2. **Elimina el servicio** (o haz clic en "Eliminar" o "Delete")
3. **Crea un nuevo servicio** con el nombre `checkin24hs_dashboard`
4. **Configura**:
   - **Puerto**: `30000:3000` (externo:interno) o solo `3000` si hay opción de modo ingress
   - **Modo**: `ingress` (si está disponible)
5. **Guarda** y **reinicia**

### Opción 3: Actualizar Configuración del Dominio

Si usas el puerto 30000, necesitas actualizar la configuración del dominio en EasyPanel:

1. **Ve a EasyPanel** → **Servicios** → **dashboard** → **Dominios**
2. **Edita el dominio** del dashboard
3. **Cambia el puerto** de `3000` a `30000`
4. **Guarda** los cambios

## 🎯 Recomendación

**Usa la Opción 1 primero**. Si no funciona, usa la Opción 2 (recrear desde EasyPanel) que es más limpia y confiable.

