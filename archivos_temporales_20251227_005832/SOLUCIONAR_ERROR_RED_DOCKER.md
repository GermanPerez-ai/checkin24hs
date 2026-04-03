# Solucionar Error de Red Docker en EasyPanel

## Error Detectado

```
network sandbox join failed: subnet sandbox join failed for "10.11.0.0/16": 
error creating vxlan interface: file exists
```

Este error indica un conflicto con la red virtual de Docker Swarm.

## Solución

### Opción 1: Limpiar Redes Docker (Recomendado)

Ejecuta estos comandos en el servidor:

```bash
# 1. Ver redes Docker existentes
docker network ls

# 2. Ver servicios de Docker Swarm
docker service ls

# 3. Detener el servicio dashboard si está corriendo
docker service rm checkin24hs_dashboard 2>/dev/null || true

# 4. Limpiar redes no utilizadas
docker network prune -f

# 5. Verificar redes de Docker Swarm
docker network ls | grep swarm

# 6. Si hay redes conflictivas, eliminarlas manualmente
# (CUIDADO: Solo elimina redes que no estén en uso)
docker network rm <nombre-red-conflictiva> 2>/dev/null || true

# 7. Reiniciar Docker Swarm (si es necesario)
docker swarm leave --force 2>/dev/null || true
docker swarm init 2>/dev/null || true
```

### Opción 2: Reiniciar el Servicio desde EasyPanel

1. En EasyPanel, ve al servicio "dashboard"
2. Haz clic en el botón de **detener** (cuadrado/stop)
3. Espera a que se detenga completamente
4. Haz clic en **"Implementar"** nuevamente

### Opción 3: Eliminar y Recrear el Servicio

1. En EasyPanel, elimina el servicio "dashboard"
2. Crea un nuevo servicio con el mismo nombre
3. Configura la fuente nuevamente
4. Implementa el servicio

### Opción 4: Limpiar Todo Docker (Último Recurso)

⚠️ **CUIDADO**: Esto eliminará todos los contenedores, redes y volúmenes no utilizados.

```bash
# Detener todos los servicios
docker service ls -q | xargs docker service rm 2>/dev/null || true

# Limpiar todo
docker system prune -a --volumes -f

# Reiniciar Docker Swarm
docker swarm leave --force
docker swarm init
```

## Verificar el Estado

Después de aplicar la solución:

```bash
# Ver servicios
docker service ls

# Ver redes
docker network ls

# Ver contenedores
docker ps -a

# Ver logs de EasyPanel
docker logs easypanel --tail 50
```

## Prevenir el Error en el Futuro

1. Siempre detén los servicios antes de eliminarlos
2. Limpia redes no utilizadas periódicamente: `docker network prune -f`
3. Evita crear múltiples servicios con el mismo nombre


