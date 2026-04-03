# 🔍 Verificar IP Correcta del Contenedor

## Problema Identificado

✅ **Nombre se resuelve:** `checkin24hs_whatsapp-api` → `10.11.135.100`
❌ **IP incorrecta:** Traefik está usando `10.11.135.100` pero el contenedor está en `10.11.135.101`
✅ **Acceso por IP correcta funciona:** `10.11.135.101:80` funciona

## Verificaciones Necesarias

### 1. Verificar IP Real del Contenedor

```bash
# Ver IP del contenedor en la red easypanel
docker inspect checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm | grep -A 10 '"easypanel"' | grep IPAddress

# Ver todas las IPs del contenedor
docker inspect checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm | grep -A 5 IPAddress
```

---

### 2. Verificar VIP del Servicio Docker Swarm

```bash
# Ver VIP (Virtual IP) del servicio
docker service inspect checkin24hs_whatsapp-api --format '{{json .Endpoint.VirtualIPs}}' | python3 -m json.tool
```

El VIP es la IP que Docker Swarm usa para balancear carga entre múltiples réplicas del servicio.

---

### 3. Probar Acceso desde Traefik al VIP

```bash
# Probar acceso al VIP del servicio
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://10.11.135.100:80/api1/api/qr?card=1

# Si no funciona, probar con la IP del contenedor
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://10.11.135.101:80/api1/api/qr?card=1
```

---

## Solución: Usar VIP del Servicio

Docker Swarm usa un VIP (Virtual IP) para balancear carga. Traefik debe usar el VIP, no la IP del contenedor individual.

El VIP debería ser `10.11.135.100` (la IP que resuelve el nombre). Si esa IP no responde, puede ser que:

1. El VIP no esté configurado correctamente
2. El servicio tenga múltiples réplicas y el VIP esté balanceando a otro contenedor
3. Haya un problema de red

---

## Próximos Pasos

Ejecuta estos comandos:

1. `docker service inspect checkin24hs_whatsapp-api --format '{{json .Endpoint.VirtualIPs}}' | python3 -m json.tool`
2. `docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://10.11.135.100:80/api1/api/qr?card=1`
3. `docker inspect checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm | grep -A 10 '"easypanel"' | grep IPAddress`

Con esta información podremos identificar exactamente qué está fallando.


