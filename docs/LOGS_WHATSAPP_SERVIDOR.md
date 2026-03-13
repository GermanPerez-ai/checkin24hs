# Ver logs del servidor WhatsApp

Para revisar si hay errores o seguir la actividad del servicio WhatsApp en el servidor.

## Docker Swarm (EasyPanel)

Si el WhatsApp corre como servicio Swarm (ej. `checkin24hs_whatsapp`):

```bash
# Últimas 200 líneas y seguir en vivo
docker service logs checkin24hs_whatsapp -f --tail 200

# Solo últimas 500 líneas (sin seguir)
docker service logs checkin24hs_whatsapp --tail 500

# Ver desde hace 10 minutos
docker service logs checkin24hs_whatsapp --since 10m
```

## Por nombre del servicio

Si el nombre del servicio es otro, listar servicios:

```bash
docker service ls | grep -i whatsapp
```

Luego usar el nombre que aparezca, por ejemplo:

```bash
docker service logs NOMBRE_DEL_SERVICIO -f --tail 200
```

## Contenedor directo (sin Swarm)

Si usás un contenedor suelto en lugar de servicio:

```bash
# Listar contenedores con "whatsapp" en el nombre
docker ps | grep -i whatsapp

# Logs del contenedor (reemplazá CONTAINER_ID o NOMBRE por el que aparezca)
docker logs CONTAINER_ID -f --tail 200
# Ejemplo por nombre:
docker logs checkin24hs_whatsapp.1.xxx -f --tail 200
```

## Buscar errores en los logs

```bash
docker service logs checkin24hs_whatsapp --tail 1000 2>&1 | grep -i -E "error|fail|exception|❌"
```

## Resumen rápido

| Objetivo              | Comando |
|-----------------------|--------|
| Ver logs en vivo      | `docker service logs checkin24hs_whatsapp -f --tail 200` |
| Últimas 500 líneas    | `docker service logs checkin24hs_whatsapp --tail 500` |
| Solo errores          | `docker service logs checkin24hs_whatsapp --tail 1000 2>&1 \| grep -i error` |
