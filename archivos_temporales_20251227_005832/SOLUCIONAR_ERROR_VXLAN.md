# Solucionar Error de VXLAN Interface

## Error Detectado

```
network sandbox join failed: subnet sandbox join failed for "10.0.1.0/24": 
error creating vxlan interface: file exists
```

Este error indica que hay una interfaz VXLAN existente que está causando conflicto.

## Solución

### Opción 1: Limpiar Interfaces VXLAN (Recomendado)

```bash
# Ver interfaces de red
ip link show type vxlan

# Eliminar interfaces VXLAN existentes
ip link show type vxlan | grep -o 'vxlan[0-9]*' | xargs -I {} ip link delete {} 2>/dev/null || true

# Verificar que se eliminaron
ip link show type vxlan
```

### Opción 2: Limpiar Redes Docker y Recrear

```bash
# Detener todos los servicios de Swarm
docker service ls -q | xargs docker service rm 2>/dev/null || true

# Eliminar todas las redes overlay
docker network ls --filter driver=overlay -q | xargs docker network rm 2>/dev/null || true

# Limpiar interfaces VXLAN
ip link show type vxlan | grep -o 'vxlan[0-9]*' | xargs -I {} ip link delete {} 2>/dev/null || true

# Recrear la red de EasyPanel
docker network create --driver overlay --attachable easypanel

# Verificar
docker network ls | grep easypanel
```

### Opción 3: Reiniciar Docker (Último Recurso)

```bash
# Reiniciar Docker
systemctl restart docker

# Esperar a que Docker se inicie
sleep 10

# Verificar que Docker está corriendo
docker ps

# Recrear la red
docker network create --driver overlay --attachable easypanel

# Reiniciar EasyPanel
docker restart easypanel
```

## Verificar el Estado

Después de aplicar la solución:

```bash
# Ver interfaces VXLAN
ip link show type vxlan

# Ver redes Docker
docker network ls

# Ver servicios de Swarm
docker service ls

# Ver logs de EasyPanel
docker logs easypanel --tail 30
```

## Luego en EasyPanel

1. Espera 1-2 minutos después de limpiar
2. Recarga la página de EasyPanel (F5)
3. Ve al servicio "dashboard"
4. Haz clic en **"Implementar"** nuevamente

## Prevenir el Error

Para evitar este problema en el futuro:

1. Siempre detén los servicios antes de eliminarlos
2. Limpia interfaces VXLAN periódicamente
3. Evita crear múltiples redes con el mismo rango de subred


