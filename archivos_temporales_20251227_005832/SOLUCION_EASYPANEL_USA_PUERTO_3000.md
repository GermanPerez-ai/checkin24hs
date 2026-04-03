# 🔧 Solución: EasyPanel Usa el Puerto 3000

## 🚨 Problema Identificado

El servicio **easypanel** está usando el puerto 3000 para su interfaz web:
```
easypanel.1.srrwqonusubgujq9vthkshjjs   0.0.0.0:3000->3000/tcp
```

Por eso el servicio `checkin24hs_dashboard` no puede iniciar en modo **host** (el puerto ya está ocupado).

## ✅ Solución: Usar Modo Ingress

El modo **ingress** permite que múltiples servicios usen el mismo puerto porque Docker Swarm hace el routing internamente.

### Pasos:

```bash
# 1. Ver la configuración actual del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 2. Eliminar TODOS los puertos actuales (sin especificar modo)
docker service update --publish-rm 3000 checkin24hs_dashboard

# 3. Esperar a que se complete
sleep 5

# 4. Verificar que se eliminó
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 5. Agregar puerto en modo ingress (esto permite compartir el puerto 3000)
docker service update \
  --publish-add published=3000,target=3000,protocol=tcp,mode=ingress \
  checkin24hs_dashboard

# 6. Esperar a que se complete
sleep 5

# 7. Verificar la nueva configuración
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 8. Escalar el servicio
docker service scale checkin24hs_dashboard=1

# 9. Esperar a que inicie
sleep 15

# 10. Verificar el estado
docker service ps checkin24hs_dashboard

# 11. Probar la conexión desde Traefik
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -20
```

## 🔍 Si el Modo Ingress No Funciona

Si el modo ingress no está disponible o no funciona, podemos usar un puerto diferente:

```bash
# 1. Eliminar puerto actual
docker service update --publish-rm 3000 checkin24hs_dashboard
sleep 5

# 2. Agregar puerto 30000 (externo) -> 3000 (interno) en modo ingress
docker service update \
  --publish-add published=30000,target=3000,protocol=tcp,mode=ingress \
  checkin24hs_dashboard

# 3. Escalar
docker service scale checkin24hs_dashboard=1
sleep 15

# 4. Verificar
docker service ps checkin24hs_dashboard
```

**Nota**: Si usas el puerto 30000, necesitarás actualizar la configuración del dominio en EasyPanel para usar ese puerto.

## 🎯 Explicación

- **Modo host**: El puerto se publica directamente en el host. Solo un servicio puede usar el puerto.
- **Modo ingress**: El puerto se publica a través del routing mesh de Docker Swarm. Múltiples servicios pueden usar el mismo puerto porque Swarm hace el routing basado en el servicio de destino.

Como EasyPanel ya usa el puerto 3000 en modo host, el dashboard debe usar modo ingress para poder compartir el puerto.

