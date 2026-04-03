# 🔍 Verificar Detección de Servicio en Traefik

## Contenedor Traefik Encontrado

El contenedor es: `traefik.1.7x4x0qy3w08b8ob9ontssyjb4`

## Verificaciones Necesarias

### 1. Verificar si Traefik Detecta el Servicio

```bash
# Ver rutas que Traefik tiene configuradas
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i "whatsapp-api\|configwp"

# Ver servicios que Traefik detecta
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://localhost:8080/api/http/services 2>/dev/null | grep -i "whatsapp-api"

# Ver todas las rutas (para ver qué está configurado)
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | python3 -m json.tool | grep -A 10 -i "whatsapp\|configwp"
```

---

### 2. Ver Logs de Traefik en Tiempo Real

```bash
# Ver logs de Traefik mientras haces una petición
docker logs -f traefik.1.7x4x0qy3w08b8ob9ontssyjb4 2>&1

# En otra terminal, hacer la petición:
curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1
```

**Busca en los logs:**
- Errores relacionados con `whatsapp-api`
- Errores de conexión
- Mensajes sobre rutas no encontradas
- Errores 502 o Bad Gateway

---

### 3. Verificar Configuración del Dominio en EasyPanel

**CRÍTICO:** El dominio debe estar configurado correctamente.

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api** → **Dominios**
2. Edita el dominio `https://configwp.checkin24hs.com/`
3. Verifica que el **Destino** sea:
   - Protocolo: HTTP
   - Puerto: 80
   - **Servicio:** `checkin24hs_whatsapp-api` (debe aparecer en un dropdown)
   - Ruta: `/`

**Si el campo "Servicio" tiene una IP o nombre incorrecto:**
- Cámbialo al nombre del servicio: `checkin24hs_whatsapp-api`
- Guarda

---

### 4. Verificar Redes Docker

```bash
# Ver en qué red está Traefik
docker inspect traefik.1.7x4x0qy3w08b8ob9ontssyjb4 | grep -A 20 Networks

# Ver en qué red está el contenedor NGINX
docker inspect checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm | grep -A 20 Networks

# Verificar que estén en la misma red (deben estar en "easypanel" o "easypanel-checkin24hs")
```

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i "whatsapp-api\|configwp"`
2. `docker inspect traefik.1.7x4x0qy3w08b8ob9ontssyjb4 | grep -A 20 Networks`
3. Verifica en EasyPanel que el dominio apunte al **nombre del servicio** `checkin24hs_whatsapp-api`

Con esta información podremos identificar exactamente qué está fallando.


