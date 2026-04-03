# Solucionar Conflicto de Subred

## Problema

La red `easypanel` existe, pero EasyPanel está intentando crear una subred específica (`10.0.1.0/24`) que está en conflicto.

## Solución

### Opción 1: Eliminar y Recrear la Red con Subred Específica

```bash
# 1. Ver detalles de la red actual
docker network inspect easypanel

# 2. Eliminar servicios que puedan estar usando la red
docker service ls | grep dashboard
docker service rm checkin24hs_dashboard 2>/dev/null || true

# 3. Eliminar la red actual
docker network rm easypanel

# 4. Recrear la red con una subred diferente
docker network create --driver overlay --attachable --subnet=10.11.0.0/16 easypanel

# 5. Verificar que se creó
docker network ls | grep easypanel

# 6. Reiniciar EasyPanel
docker restart easypanel

# 7. Esperar a que EasyPanel se reinicie
sleep 10
```

### Opción 2: Dejar que EasyPanel Cree su Propia Red

Si la opción 1 no funciona, podemos eliminar la red y dejar que EasyPanel la cree automáticamente:

```bash
# 1. Detener servicios relacionados
docker service ls -q | xargs docker service rm 2>/dev/null || true

# 2. Eliminar la red
docker network rm easypanel

# 3. Reiniciar EasyPanel (creará su propia red)
docker restart easypanel

# 4. Esperar y verificar
sleep 15
docker network ls | grep easypanel
```

### Opción 3: Usar una Subred Diferente

Si hay conflictos con múltiples subredes:

```bash
# Eliminar todas las redes overlay de EasyPanel
docker network rm easypanel easypanel-checkin24hs 2>/dev/null || true

# Crear red con subred específica que no esté en uso
docker network create --driver overlay --attachable --subnet=172.20.0.0/16 easypanel

# Reiniciar EasyPanel
docker restart easypanel
```

## Verificar el Estado

Después de aplicar la solución:

```bash
# Ver redes
docker network ls | grep easypanel

# Ver detalles de la red
docker network inspect easypanel

# Ver servicios
docker service ls

# Ver logs de EasyPanel
docker logs easypanel --tail 30
```

## Luego en EasyPanel

1. Espera 1-2 minutos después de recrear la red
2. Recarga la página de EasyPanel (F5)
3. Ve al servicio "dashboard"
4. Haz clic en **"Implementar"** nuevamente

## Notas

- La subred `10.11.0.0/16` es la que EasyPanel usa por defecto
- Si hay conflictos, podemos usar otra subred como `172.20.0.0/16`
- EasyPanel puede crear sus propias redes automáticamente si las eliminamos


