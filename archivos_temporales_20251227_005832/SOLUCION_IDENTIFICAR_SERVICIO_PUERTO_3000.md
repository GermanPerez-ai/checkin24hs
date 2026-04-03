# 🔍 Identificar Qué Servicio Usa el Puerto 3000

## 🚨 Problema

Los procesos `docker-pr` siguen usando el puerto 3000 incluso después de escalar el servicio a 0. Esto significa que hay **otro servicio o contenedor** usando ese puerto.

## 🔍 Comandos para Identificar

```bash
# 1. Ver qué contenedor está usando el puerto 3000
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 3000

# 2. Ver todos los servicios que publican el puerto 3000
docker service ls --format "table {{.Name}}\t{{.Ports}}" | grep 3000

# 3. Ver el PID del proceso y encontrar el contenedor
sudo docker inspect $(sudo docker ps -q) --format '{{.Name}} {{.State.Pid}}' | while read name pid; do
  if sudo lsof -p $pid 2>/dev/null | grep -q ":3000"; then
    echo "Contenedor: $name (PID: $pid)"
  fi
done

# 4. Ver todos los contenedores corriendo
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"

# 5. Verificar si hay otro servicio de dashboard
docker service ls | grep -i dashboard
```

## ✅ Soluciones

### Opción 1: Detener el Otro Servicio/Contenedor

Una vez identificado qué está usando el puerto 3000:

```bash
# Si es un contenedor:
docker stop <CONTAINER_NAME>

# Si es un servicio:
docker service scale <SERVICE_NAME>=0
```

### Opción 2: Cambiar el Puerto del Dashboard

Si no puedes detener el otro servicio, cambia el puerto del dashboard:

```bash
# 1. Escalar a 0
docker service scale checkin24hs_dashboard=0
sleep 10

# 2. Eliminar TODOS los puertos primero
docker service update --publish-rm 3000:3000 checkin24hs_dashboard

# 3. Agregar puerto diferente (30000 externo -> 3000 interno)
docker service update \
  --publish-add published=30000,target=3000,protocol=tcp,mode=ingress \
  checkin24hs_dashboard

# 4. Escalar de nuevo
docker service scale checkin24hs_dashboard=1
sleep 10

# 5. Verificar
docker service ps checkin24hs_dashboard
```

**Nota**: Si usas esta opción, necesitarás actualizar la configuración del dominio en EasyPanel para usar el puerto 30000.

### Opción 3: Usar un Puerto Interno Diferente

Si prefieres mantener el puerto externo 3000 pero cambiar el interno:

```bash
# 1. Escalar a 0
docker service scale checkin24hs_dashboard=0
sleep 10

# 2. Eliminar puerto actual
docker service update --publish-rm 3000:3000 checkin24hs_dashboard

# 3. Cambiar el puerto interno del servidor a 3001
# (Necesitarías modificar server.js o usar variable de entorno PORT=3001)

# 4. Agregar puerto 3000 externo -> 3001 interno
docker service update \
  --publish-add published=3000,target=3001,protocol=tcp,mode=ingress \
  checkin24hs_dashboard

# 5. Escalar de nuevo
docker service scale checkin24hs_dashboard=1
```

## 🎯 Recomendación

**Primero identifica qué está usando el puerto 3000**, luego decide:
- Si es un servicio que no necesitas, deténlo
- Si es un servicio que necesitas, cambia el puerto del dashboard

