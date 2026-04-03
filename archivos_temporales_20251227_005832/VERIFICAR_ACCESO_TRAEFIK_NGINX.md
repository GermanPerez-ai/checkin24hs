# 🔍 Verificar Acceso Traefik → NGINX

## Estado Actual

✅ **Traefik detecta el servicio:** `checkin24hs_whatsapp-api:80` está marcado como "UP"
✅ **Ruta configurada:** `configwp.checkin24hs.com` → `checkin24hs_whatsapp-api:80`
❌ **Bad Gateway:** Traefik no puede acceder al contenedor NGINX

## Verificaciones Necesarias

### 1. Verificar que Traefik Pueda Resolver el Nombre del Servicio

```bash
# Desde Traefik, intentar resolver el nombre del servicio
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 nslookup checkin24hs_whatsapp-api

# O usar getent
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 getent hosts checkin24hs_whatsapp-api
```

---

### 2. Probar Acceso Directo desde Traefik al Contenedor NGINX

```bash
# Probar acceso desde Traefik al contenedor NGINX usando el nombre del servicio
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://checkin24hs_whatsapp-api:80/api1/api/qr?card=1

# O usar la IP directa del contenedor NGINX
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://10.11.135.101:80/api1/api/qr?card=1
```

---

### 3. Ver Logs de Traefik en Tiempo Real

```bash
# Ver logs de Traefik mientras haces una petición
docker logs -f traefik.1.7x4x0qy3w08b8ob9ontssyjb4 2>&1

# En otra terminal, hacer la petición:
curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1
```

**Busca en los logs:**
- Errores de conexión
- Errores de resolución DNS
- Errores 502 o Bad Gateway
- Timeouts

---

### 4. Verificar que Ambos Estén en la Misma Red

```bash
# Ver redes del contenedor NGINX
docker inspect checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm | grep -A 20 Networks

# Verificar que ambos estén en la red "easypanel"
```

---

## Posible Problema: Nombre del Servicio Incorrecto

Traefik está buscando `checkin24hs_whatsapp-api` pero el servicio puede tener un nombre diferente. Verifica:

```bash
# Ver nombre real del servicio Docker Swarm
docker service ls | grep whatsapp-api

# Ver detalles del servicio
docker service inspect checkin24hs_whatsapp-api
```

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://checkin24hs_whatsapp-api:80/api1/api/qr?card=1`
2. `docker service ls | grep whatsapp-api`
3. `docker logs traefik.1.7x4x0qy3w08b8ob9ontssyjb4 2>&1 | tail -30 | grep -i "whatsapp-api\|502\|bad\|error"`

Con esta información podremos identificar exactamente qué está fallando.


