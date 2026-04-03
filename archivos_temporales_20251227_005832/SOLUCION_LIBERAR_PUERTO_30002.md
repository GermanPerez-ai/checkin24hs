# 🔧 Solución: Puerto 30002 Ya Está en Uso

## 🔍 Problema Identificado

El servicio está en estado **"Pending"** porque el puerto 30002 ya está siendo usado por otro proceso. El error dice:
```
"no suitable node (host-mode port already in use on 1 node)"
```

---

## ✅ Solución 1: Identificar y Eliminar el Proceso que Usa el Puerto

### Paso 1: Identificar qué está usando el puerto

Ejecuta este comando:

```bash
echo "🔍 Identificando qué usa el puerto 30002..." && sudo lsof -i :30002 || sudo netstat -tulpn | grep 30002
```

### Paso 2: Ver si es un contenedor antiguo

```bash
docker ps -a | grep 30002
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 30002
```

### Paso 3: Ver si es otro servicio Docker

```bash
docker service ls --format "table {{.Name}}\t{{.Ports}}" | grep 30002
```

### Paso 4: Eliminar el proceso o contenedor

**Si es un contenedor:**
```bash
# Ver todos los contenedores (incluyendo detenidos)
docker ps -a | grep dashboard

# Eliminar contenedores antiguos
docker rm -f $(docker ps -a | grep dashboard | awk '{print $1}')
```

**Si es un proceso docker-proxy:**
```bash
# Encontrar el PID
ps aux | grep docker-proxy | grep 30002

# Matar el proceso (reemplaza PID con el número real)
sudo kill -9 <PID>
```

---

## ✅ Solución 2: Cambiar a Modo Ingress (RECOMENDADO)

En lugar de usar modo `host` (que requiere que el puerto esté libre), usa modo `ingress`:

```bash
# 1. Escalar a 0
docker service scale checkin24hs_checkin24hs-dashboard=0
sleep 5

# 2. Eliminar puerto en modo host
docker service update --publish-rm 30002 checkin24hs_checkin24hs-dashboard
sleep 3

# 3. Agregar puerto en modo ingress
docker service update --publish-add published=30002,target=3000,protocol=tcp,mode=ingress checkin24hs_checkin24hs-dashboard
sleep 5

# 4. Escalar a 1
docker service scale checkin24hs_checkin24hs-dashboard=1
sleep 10

# 5. Verificar
docker service ps checkin24hs_checkin24hs-dashboard
```

---

## ✅ Solución 3: Usar un Puerto Diferente

Si prefieres mantener el modo `host`, usa un puerto diferente:

```bash
# 1. Escalar a 0
docker service scale checkin24hs_checkin24hs-dashboard=0
sleep 5

# 2. Eliminar puerto 30002
docker service update --publish-rm 30002 checkin24hs_checkin24hs-dashboard
sleep 3

# 3. Agregar puerto 30003 (o cualquier otro libre)
docker service update --publish-add published=30003,target=3000,protocol=tcp,mode=host checkin24hs_checkin24hs-dashboard
sleep 5

# 4. Escalar a 1
docker service scale checkin24hs_checkin24hs-dashboard=1
sleep 10

# 5. Verificar
docker service ps checkin24hs_checkin24hs-dashboard
```

**Luego actualiza en EasyPanel:**
- Cambia el puerto publicado de `30002` a `30003`
- Accede con: `http://72.61.58.240:30003`

---

## ✅ Solución 4: Limpiar Todo y Recrear

Si nada funciona, limpia todo y recrea:

```bash
# 1. Escalar a 0
docker service scale checkin24hs_checkin24hs-dashboard=0
sleep 10

# 2. Eliminar todos los puertos
docker service update --publish-rm 30002 checkin24hs_checkin24hs-dashboard
sleep 5

# 3. Eliminar contenedores antiguos
docker ps -a | grep dashboard | awk '{print $1}' | xargs -r docker rm -f

# 4. Matar procesos docker-proxy en puerto 30002
sudo lsof -ti :30002 | xargs -r sudo kill -9

# 5. Esperar
sleep 5

# 6. Verificar que el puerto está libre
sudo netstat -tuln | grep 30002 || echo "✅ Puerto 30002 está libre"

# 7. Agregar puerto de nuevo
docker service update --publish-add published=30002,target=3000,protocol=tcp,mode=host checkin24hs_checkin24hs-dashboard
sleep 5

# 8. Escalar a 1
docker service scale checkin24hs_checkin24hs-dashboard=1
sleep 15

# 9. Verificar
docker service ps checkin24hs_checkin24hs-dashboard
docker service logs checkin24hs_checkin24hs-dashboard --tail 10
```

---

## 🎯 Recomendación

**Usa la Solución 2 (modo ingress)** porque:
- No requiere que el puerto esté libre en el host
- Es más compatible con Docker Swarm
- Funciona mejor con Traefik

---

## ✅ Verificación Final

Después de aplicar la solución:

```bash
# 1. Estado del servicio (debe estar "Running")
docker service ps checkin24hs_checkin24hs-dashboard

# 2. Puerto publicado
docker service inspect checkin24hs_checkin24hs-dashboard --format '{{json .Endpoint.Ports}}' | jq

# 3. Conexión local
curl -I http://localhost:30002

# 4. Logs
docker service logs checkin24hs_checkin24hs-dashboard --tail 5
```

---

## 🆘 Si Sigue Sin Funcionar

1. **Verifica en EasyPanel:**
   - Ve al servicio → Pestaña "Puertos"
   - Elimina el puerto 30002
   - Créalo de nuevo con modo "Ingress" (si hay opción)

2. **O usa un puerto completamente diferente:**
   - Usa 30003, 30004, o 30005
   - Configúralo en EasyPanel
   - Prueba `http://72.61.58.240:30003`


