# 🔧 Solución Sin IP Manual

## Problema

EasyPanel solo permite seleccionar servicios desde un dropdown, no ingresar IPs manualmente.

## Soluciones Alternativas

### Opción 1: Verificar Alias del Servicio

El servicio puede tener alias que funcionen mejor. Verifica:

```bash
# Ver alias del servicio en las redes
docker service inspect checkin24hs_whatsapp-api | grep -A 5 Aliases

# Probar acceso usando alias
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://checkin24hs-whatsapp-api:80/api1/api/qr?card=1
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://whatsapp-api:80/api1/api/qr?card=1
```

---

### Opción 2: Verificar Configuración del Servicio

El problema puede ser que el servicio necesita estar configurado de manera específica para que el VIP funcione:

```bash
# Ver configuración completa del servicio
docker service inspect checkin24hs_whatsapp-api | grep -A 30 "Endpoint"

# Ver si el servicio tiene puertos publicados
docker service inspect checkin24hs_whatsapp-api | grep -A 10 "Ports"
```

---

### Opción 3: Recrear el Servicio con Configuración Correcta

Si el VIP no funciona, puede ser necesario recrear el servicio con la configuración correcta para que Docker Swarm configure el VIP adecuadamente.

---

### Opción 4: Usar Nombre Completo del Contenedor

Si EasyPanel permite usar el nombre completo del contenedor en lugar del servicio:

- `checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm`

Pero esto tampoco es ideal porque el nombre cambia.

---

## Verificaciones Necesarias

Ejecuta estos comandos:

1. `docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://checkin24hs-whatsapp-api:80/api1/api/qr?card=1`
2. `docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://whatsapp-api:80/api1/api/qr?card=1`
3. `docker service inspect checkin24hs_whatsapp-api | grep -A 30 "Endpoint"`

Con esta información podremos encontrar una solución alternativa.


