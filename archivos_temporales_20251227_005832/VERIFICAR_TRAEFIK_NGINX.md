# 🔍 Verificar Traefik → NGINX

## Estado Actual

✅ **Contenedor puede acceder a servicios:** `172.18.0.1:4001` funciona desde dentro del contenedor
✅ **NGINX configurado correctamente:** Las rutas están bien configuradas
❌ **Bad Gateway desde fuera:** Traefik no está enrutando correctamente al contenedor NGINX

## Verificaciones Necesarias

### 1. Ver Logs de NGINX para Ver Qué Está Recibiendo

```bash
# Ver logs de acceso de NGINX
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm tail -20 /var/log/nginx/access.log

# Ver logs de error
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm tail -20 /var/log/nginx/error.log
```

---

### 2. Verificar Dominio en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Ve a la pestaña **"Dominios"**
3. Verifica que `configwp.checkin24hs.com` esté configurado:
   - **Host:** `configwp.checkin24hs.com`
   - **Ruta:** `/` (o `/api1/`, `/api2/`, etc.)
   - **Destino:** Protocolo HTTP, Puerto 80, Ruta `/`

---

### 3. Probar Acceso Directo al Contenedor NGINX

```bash
# Probar acceso directo al contenedor NGINX (sin Traefik)
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm curl http://localhost/api1/api/qr?card=1

# O desde el host, acceder directamente al puerto del contenedor
# Primero ver qué puerto está expuesto
docker ps | grep whatsapp-api
```

---

### 4. Verificar Configuración de Traefik

```bash
# Ver logs de Traefik relacionados con whatsapp-api
docker logs traefik.1.l3jle8lgzwo2qxrktvclbdbpy 2>&1 | grep -i "whatsapp-api\|configwp" | tail -30

# Ver configuración de Traefik para el servicio
docker inspect checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm | grep -A 50 Labels | grep -i traefik
```

---

## Posible Solución

Si Traefik está enviando las peticiones pero NGINX no las recibe correctamente, puede ser que:

1. **El dominio no esté configurado correctamente** en EasyPanel
2. **Traefik esté usando una ruta diferente** que no coincide con las rutas NGINX
3. **El contenedor NGINX no esté escuchando en el puerto correcto** que Traefik espera

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm curl http://localhost/api1/api/qr?card=1`
2. `docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm tail -20 /var/log/nginx/access.log`
3. Verifica en EasyPanel que el dominio `configwp.checkin24hs.com` esté configurado en la pestaña "Dominios"

Con esta información podremos identificar exactamente qué está fallando.


