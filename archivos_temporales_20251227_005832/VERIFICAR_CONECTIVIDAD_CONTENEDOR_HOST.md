# 🔍 Verificar Conectividad Contenedor → Host

## Problema

NGINX está configurado correctamente pero sigue dando Bad Gateway. Puede ser un problema de conectividad entre el contenedor y el host.

## Verificaciones Necesarias

### 1. Probar Conectividad desde el Contenedor

```bash
# Probar si el contenedor puede acceder a los puertos del host
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm curl http://172.18.0.1:4001/api/qr?card=1

# Si no funciona, probar con otras IPs
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm curl http://172.17.0.1:4001/api/qr?card=1

# Ver todas las interfaces de red del contenedor
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm ip addr show
```

---

### 2. Ver Logs de NGINX para Ver el Error Específico

```bash
# Ver logs de error de NGINX
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm tail -50 /var/log/nginx/error.log

# Ver logs de acceso
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm tail -20 /var/log/nginx/access.log
```

---

### 3. Verificar IP del Host desde el Contenedor

```bash
# Ver la IP del host desde el contenedor
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm getent hosts host.docker.internal

# O usar la IP de la red Docker
docker network inspect bridge | grep Gateway
```

---

### 4. Probar con Network Mode Host

Si ninguna IP funciona, puede que necesites usar `network_mode: host` en el servicio, pero esto requiere modificar la configuración en EasyPanel.

---

## Solución Alternativa: Usar IP del Host Real

Si los servicios WhatsApp están escuchando en `0.0.0.0` (todas las interfaces), podemos usar la IP real del servidor:

```bash
# Obtener IP del servidor
hostname -I | awk '{print $1}'

# Luego usar esa IP en la configuración NGINX
```

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm curl http://172.18.0.1:4001/api/qr?card=1`
2. `docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm tail -50 /var/log/nginx/error.log`
3. `hostname -I | awk '{print $1}'`

Con esta información podremos identificar el problema exacto.


