# 🔍 Verificar Contenedor Dashboard

## Paso 1: Encontrar el ID del Contenedor

Ejecuta en el servidor:

```bash
docker ps | grep dashboard
```

O para ver todos los contenedores (incluyendo detenidos):

```bash
docker ps -a | grep dashboard
```

## Paso 2: Probar desde Dentro del Contenedor

Una vez que tengas el ID del contenedor (o el nombre), ejecuta:

```bash
# Reemplaza <container_id> con el ID real o el nombre
docker exec <container_id> curl http://localhost/

# O si el contenedor tiene un nombre:
docker exec checkin24hs_dashboard curl http://localhost/
```

## Paso 3: Verificar Logs del Contenedor

```bash
docker logs <container_id>
# O
docker logs checkin24hs_dashboard
```

## Paso 4: Verificar Archivos Dentro del Contenedor

```bash
docker exec <container_id> ls -la /usr/share/nginx/html/
docker exec <container_id> test -f /usr/share/nginx/html/dashboard.html && echo "✅ dashboard.html existe" || echo "❌ dashboard.html NO existe"
```

## Paso 5: Verificar Configuración de Nginx

```bash
docker exec <container_id> cat /etc/nginx/conf.d/default.conf
docker exec <container_id> nginx -t
```

---

**Ejecuta estos comandos y comparte los resultados.**
