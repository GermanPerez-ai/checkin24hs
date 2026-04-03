# Eliminar Todas las Interfaces VXLAN

## Problema Persistente

EasyPanel está intentando crear la subred `10.0.1.0/24` pero hay interfaces VXLAN existentes causando conflicto.

## Solución: Eliminación Completa de VXLAN

### Paso 1: Ver y Eliminar Todas las Interfaces VXLAN

```bash
# Ver todas las interfaces VXLAN
ip link show type vxlan

# Eliminar TODAS las interfaces VXLAN usando un bucle
for iface in $(ip link show type vxlan | grep -o "vxlan[0-9]*"); do 
    ip link delete $iface 2>/dev/null || true
done

# Verificar que se eliminaron (debería estar vacío)
ip link show type vxlan
```

### Paso 2: Reiniciar Docker Completamente

```bash
# Reiniciar Docker (esto limpiará todas las referencias)
systemctl restart docker

# Esperar a que Docker se reinicie
sleep 10

# Verificar que Docker está corriendo
docker ps
```

### Paso 3: Reiniciar Docker Swarm

```bash
# Reiniciar Docker Swarm
docker swarm leave --force 2>/dev/null || true
docker swarm init

# Esperar
sleep 5
```

### Paso 4: Recrear la Red y Reiniciar EasyPanel

```bash
# Recrear la red easypanel
docker network create --driver overlay --attachable easypanel 2>/dev/null || true

# Reiniciar EasyPanel
docker restart easypanel

# Esperar
sleep 15

# Verificar
docker ps | grep easypanel
docker logs easypanel --tail 30
```

### Paso 5: Verificar que No Hay Interfaces VXLAN

```bash
# Verificar que no hay interfaces VXLAN
ip link show type vxlan

# Si aparece algo, eliminarlo manualmente
ip link delete vxlan0 2>/dev/null || true
ip link delete vxlan1 2>/dev/null || true
ip link delete vxlan2 2>/dev/null || true
# ... etc para cada una que aparezca
```

## Alternativa: Usar Subred Diferente

Si el problema persiste, podemos forzar a EasyPanel a usar una subred diferente eliminando y recreando la red con una subred específica:

```bash
# Eliminar la red actual
docker network rm easypanel 2>/dev/null || true

# Crear con subred diferente (por ejemplo, 172.20.0.0/16)
docker network create --driver overlay --attachable --subnet=172.20.0.0/16 easypanel

# Reiniciar EasyPanel
docker restart easypanel
sleep 15
```

## Verificar el Estado

Después de aplicar la solución:

```bash
# Ver interfaces VXLAN (debería estar vacío)
ip link show type vxlan

# Ver redes Docker
docker network ls | grep easypanel

# Ver servicios
docker service ls

# Ver logs de EasyPanel
docker logs easypanel --tail 50
```

## Luego en EasyPanel

1. Espera 2-3 minutos después de reiniciar Docker
2. Recarga la página de EasyPanel (F5)
3. Ve al servicio "dashboard"
4. Haz clic en **"Implementar"** nuevamente

## Notas Importantes

- Reiniciar Docker eliminará todas las referencias a interfaces VXLAN
- Docker Swarm se reiniciará y creará nuevas interfaces limpias
- EasyPanel debería poder crear servicios sin conflictos después de esto


