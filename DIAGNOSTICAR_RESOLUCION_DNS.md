# 🔍 Diagnosticar Resolución DNS en Docker Swarm

## 🎯 Problema

Los aliases están configurados pero no se resuelven. Esto puede ser un problema de Docker Swarm y la resolución DNS.

## ✅ Verificaciones

### Paso 1: Probar Acceso Directo por IP

```bash
# Obtener la IP del contenedor
docker inspect fbf8279c5485 | jq '.[0].NetworkSettings.Networks."easypanel-checkin24hs".IPAddress'

# Probar acceso directo por IP
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://<IP>:3000/
```

Si esto funciona, el problema es la resolución DNS, no el servicio.

### Paso 2: Verificar Resolución DNS

```bash
# Probar resolución DNS
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup checkin24hs_dashboard
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup checkin24hs-dashboard
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest nslookup dashboard
```

### Paso 3: Verificar si Traefik Puede Resolverlo

```bash
# Ver logs de Traefik para ver si intenta conectar
docker logs $(docker ps | grep traefik | head -1 | awk '{print $1}') --tail 100 | grep -i dashboard
```

### Paso 4: Verificar Configuración del Dominio en EasyPanel

1. En EasyPanel, ve a "Dominios"
2. Verifica que el dominio `dashboard.checkin24hs.com` tenga:
   - Destino: `http://checkin24hs_dashboard:3000/`
   - Puerto: `3000` (no 80)

---

**Ejecuta primero el Paso 1 para ver si el servicio responde por IP directa. Si funciona, el problema es la resolución DNS.**
