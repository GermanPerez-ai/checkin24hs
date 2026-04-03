# 🔍 Verificar IP del Contenedor Dashboard

## 📊 Estado Actual

- ✅ Alias `checkin24hs_dashboard` se resuelve a `10.0.2.104`
- ❌ Conexión al puerto 3000 falla

## 🔍 Comandos de Diagnóstico

### Paso 1: Verificar qué contenedor tiene la IP 10.0.2.104

```bash
# Ver todos los contenedores del servicio dashboard
docker ps | grep dashboard

# Ver detalles de red de cada contenedor
docker inspect $(docker ps | grep dashboard | awk '{print $1}') | grep -A 20 "Networks"
```

### Paso 2: Verificar si el contenedor con IP 10.0.2.104 está escuchando en puerto 3000

```bash
# Probar conexión directa a la IP
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://10.0.2.104:3000/

# Ver logs del contenedor con esa IP
docker logs $(docker ps | grep dashboard | awk '{print $1}') --tail 50
```

### Paso 3: Verificar configuración del servicio

```bash
# Ver configuración del servicio
docker service inspect checkin24hs_dashboard | grep -A 10 "Ports"
```

---

**Ejecuta estos comandos para identificar el problema.**
