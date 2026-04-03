# 🔍 Buscar Contenedor Actual

## Problema

El contenedor cambió de nombre o se recreó después de cambiar el modo del servicio.

## Buscar Contenedor Actual

```bash
# Ver contenedores activos del servicio whatsapp-api
docker ps | grep whatsapp-api

# Ver todos los contenedores (incluyendo detenidos)
docker ps -a | grep whatsapp-api
```

---

## Después de Encontrar el Contenedor

Una vez que encuentres el nombre del contenedor activo, ejecuta:

```bash
# Ver configuración NGINX
docker exec [NOMBRE_CONTENEDOR_ACTUAL] cat /etc/nginx/conf.d/default.conf

# Ver si existen las rutas
docker exec [NOMBRE_CONTENEDOR_ACTUAL] cat /etc/nginx/conf.d/default.conf | grep -A 5 "location /api"

# Ver logs de acceso
docker exec [NOMBRE_CONTENEDOR_ACTUAL] tail -20 /var/log/nginx/access.log
```

---

## Próximos Pasos

1. Ejecuta: `docker ps | grep whatsapp-api`
2. Comparte el nombre del contenedor activo
3. Luego verificaremos la configuración NGINX


