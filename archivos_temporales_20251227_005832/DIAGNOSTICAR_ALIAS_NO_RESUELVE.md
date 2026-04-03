# 🔍 Diagnosticar: Alias No Se Resuelve desde Traefik

## 🚨 Error
```
wget: bad address 'checkin24hs-dashboard:3000'
```

Esto significa que Traefik no puede resolver el nombre `checkin24hs-dashboard`.

## ✅ Pasos de Diagnóstico

### 1. Verificar en qué red está el servicio

```bash
# Ver las redes del servicio dashboard
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' | xargs -I {} docker network inspect {} --format '{{.Name}}'
```

**Debe mostrar:** `easypanel` (la misma red que Traefik)

### 2. Verificar en qué red está Traefik

```bash
# Ver las redes de Traefik
docker inspect $(docker ps | grep traefik | awk '{print $1}') --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}'
```

**Debe mostrar:** `easypanel`

### 3. Verificar el alias real del servicio

```bash
# Ver los alias del servicio en la red
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

O verificar directamente desde un contenedor del servicio:

```bash
# Obtener el ID del contenedor del servicio
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)

# Ver los alias del contenedor
docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{range $value.Aliases}}{{.}} {{end}}{{end}}'
```

### 4. Probar con el nombre del servicio Docker Swarm

El nombre del servicio en Docker Swarm puede ser diferente al alias. Prueba:

```bash
# Probar con el nombre del servicio (con guión bajo)
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs_dashboard:3000 2>&1 | head -20
```

### 5. Verificar la IP del servicio directamente

```bash
# Obtener la IP del servicio
docker service inspect checkin24hs_dashboard --format '{{range .Endpoint.VirtualIPs}}{{.Addr}} {{end}}'
```

Luego probar con la IP:

```bash
# Probar con la IP (reemplaza 10.x.x.x con la IP obtenida)
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://10.x.x.x:3000 2>&1 | head -20
```

### 6. Verificar que el servicio esté en la red easypanel

```bash
# Ver todas las redes y sus servicios
docker network inspect easypanel --format '{{range .Containers}}{{.Name}} {{end}}'
```

**Debe incluir:** Un contenedor relacionado con `checkin24hs_dashboard`

---

## 🎯 Solución Más Común

Si el servicio no está en la red `easypanel`:

1. **En EasyPanel:**
   - Ve al servicio `checkin24hs-dashboard`
   - Pestaña **Networking** o **Red**
   - Asegúrate de que esté en la red `easypanel`
   - Si no está, agrégala

2. **O desde SSH:**
```bash
# Agregar el servicio a la red easypanel
docker service update --network-add easypanel checkin24hs_dashboard
```

---

## 📝 Si el Alias es Diferente

Si el alias real es `checkin24hs_dashboard` (con guión bajo) en lugar de `checkin24hs-dashboard` (con guión):

1. **En EasyPanel, al configurar el dominio:**
   - Usa `checkin24hs_dashboard:3000` en lugar de `checkin24hs-dashboard:3000`

2. **O renombra el servicio para que coincida:**
   - El nombre del servicio debe ser `checkin24hs-dashboard` (con guión)

