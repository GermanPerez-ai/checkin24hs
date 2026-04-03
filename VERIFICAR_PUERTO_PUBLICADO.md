# 🔍 Verificar Puerto Publicado

## ✅ Servicio Funcionando

- ✅ Node.js corriendo: `node server.js`
- ✅ Escuchando en puerto 3000: `tcp 0.0.0.0:3000 LISTEN`

## 🔍 Verificar Puerto Publicado

Si hay un puerto publicado, podríamos acceder directamente:

```bash
# Ver puertos del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# O ver todos los servicios y sus puertos
docker service ls
docker service ps checkin24hs_dashboard
```

## 🔍 Probar desde Dentro de la Red Docker

Los aliases solo funcionan dentro de la red Docker. Probemos desde otro contenedor en la misma red:

```bash
# Ver qué redes tiene el servicio
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq -r '.[].Target'

# Ver contenedores en esas redes
docker network inspect <network_id> | jq '.[0].Containers'
```

## 🎯 Próximo Paso

El servicio está funcionando correctamente. El problema es solo el alias en el proxy de EasyPanel.

**Opción 1:** Enviar el mensaje al soporte de EasyPanel explicando el problema del alias.

**Opción 2:** Verificar si hay un puerto publicado que podamos usar temporalmente.

---

**Ejecuta el comando para ver los puertos del servicio y comparte el resultado.**
