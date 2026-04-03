# 🔧 Solución: Puerto 3000 Ya Está en Uso

## 🚨 Problema Identificado

```
"no suitable node (host-mode port already in use on 1 node)"
```

El puerto 3000 está configurado en modo **"host"** y **ya está en uso** por otro proceso o servicio.

## 🔍 Verificar Qué Está Usando el Puerto 3000

Ejecuta estos comandos:

```bash
# Ver qué proceso está usando el puerto 3000
sudo netstat -tulpn | grep :3000
# O
sudo ss -tulpn | grep :3000
# O
sudo lsof -i :3000

# Ver todos los servicios de Docker que usan el puerto 3000
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 3000

# Ver servicios de Docker Swarm que publican el puerto 3000
docker service ls | grep 3000
```

## ✅ Soluciones

### Solución 1: Cambiar el Modo de Publicación a "ingress" (Recomendado)

En lugar de usar modo "host", usa el routing mesh de Docker Swarm:

```bash
# Actualizar el servicio para usar modo ingress
docker service update \
  --publish-rm 3000:3000 \
  --publish-add published=3000,target=3000,protocol=tcp,mode=ingress \
  checkin24hs_dashboard
```

**Ventajas:**
- No requiere que el puerto esté libre en el host
- Usa el routing mesh de Docker Swarm
- Funciona mejor con Traefik

### Solución 2: Cambiar el Puerto Publicado

Si prefieres mantener el modo "host", cambia el puerto publicado:

```bash
# Cambiar a puerto 30000 (externo) -> 3000 (interno)
docker service update \
  --publish-rm 3000:3000 \
  --publish-add published=30000,target=3000,protocol=tcp,mode=host \
  checkin24hs_dashboard
```

Luego actualiza la configuración del dominio en EasyPanel para usar el puerto 30000.

### Solución 3: Detener el Proceso que Usa el Puerto 3000

Si hay otro proceso usando el puerto 3000:

```bash
# Ver qué proceso está usando el puerto
sudo lsof -i :3000

# Detener el proceso (reemplaza PID con el número del proceso)
sudo kill <PID>

# O si es un servicio de Docker
docker stop <CONTAINER_NAME>
```

### Solución 4: Configurar desde EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **dashboard**
2. Busca la sección **"Ports"** o **"Puertos"**
3. Cambia la configuración:
   - **Modo**: De "host" a "ingress" (si está disponible)
   - O cambia el **puerto externo** a otro (ej: 30000)
4. **Guarda** y **reinicia** el servicio

## 🎯 Recomendación

**Usa la Solución 1** (modo ingress) porque:
- ✅ No requiere que el puerto esté libre en el host
- ✅ Funciona mejor con Docker Swarm y Traefik
- ✅ Es la forma recomendada para servicios en Swarm

## 📋 Comandos Completos

```bash
# 1. Ver qué está usando el puerto 3000
sudo lsof -i :3000

# 2. Cambiar a modo ingress
docker service update \
  --publish-rm 3000:3000 \
  --publish-add published=3000,target=3000,protocol=tcp,mode=ingress \
  checkin24hs_dashboard

# 3. Verificar que el servicio se actualizó
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 4. Esperar unos segundos y verificar el estado
docker service ps checkin24hs_dashboard

# 5. Probar la conexión
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -20
```

---

**Ejecuta primero el comando para ver qué está usando el puerto 3000, luego aplica la solución 1 (modo ingress).**

