# 🔍 Buscar Código en el Servidor

## EasyPanel generalmente clona el código en:
- `/var/lib/easypanel/projects/`
- `/opt/easypanel/projects/`
- O en el directorio home del usuario

## Comandos para buscar:

```bash
# 1. Buscar el directorio del proyecto
find /var/lib/easypanel -name "dashboard.html" 2>/dev/null | head -5
find /opt/easypanel -name "dashboard.html" 2>/dev/null | head -5
find ~ -name "dashboard.html" 2>/dev/null | head -5

# 2. Buscar por el nombre del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.ContainerSpec.Image}}'

# 3. Verificar la imagen que se está usando
docker images | grep dashboard

# 4. Verificar si EasyPanel está usando una imagen de Docker Hub
# Si es así, el código está en la imagen, no en el servidor
```

## Importante:
Si EasyPanel está usando una imagen de Docker Hub (como `easypanel/checkin24hs/dashboard:latest`), el código está en la imagen, no en el servidor. En ese caso, necesitas:
1. Hacer build de una nueva imagen con el código actualizado
2. Hacer push a Docker Hub
3. Implementar el servicio desde EasyPanel
