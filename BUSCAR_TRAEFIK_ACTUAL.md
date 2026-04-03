# 🔍 Buscar Contenedor Traefik Actual

## Buscar Contenedor Traefik

```bash
# Ver contenedores de Traefik activos
docker ps | grep traefik

# Ver todos los contenedores de Traefik (incluyendo detenidos)
docker ps -a | grep traefik
```

---

## Después de Encontrar el Contenedor

Una vez que encuentres el nombre del contenedor Traefik, ejecuta:

```bash
# Ver si Traefik detecta el servicio whatsapp-api
docker exec [NOMBRE_TRAEFIK] wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i whatsapp-api

# Ver logs de Traefik
docker logs [NOMBRE_TRAEFIK] 2>&1 | tail -50 | grep -i "whatsapp-api\|configwp\|502\|bad\|error"
```

---

## Verificar IP del Contenedor NGINX

El contenedor NGINX tiene estas IPs:
- `10.11.135.101` (red easypanel)
- `10.0.1.101` (red easypanel-checkin24hs)

Traefik debe estar en la misma red para poder acceder al contenedor NGINX.

---

## Próximos Pasos

1. Ejecuta: `docker ps | grep traefik`
2. Comparte el nombre del contenedor Traefik
3. Luego ejecutaremos los comandos de verificación


