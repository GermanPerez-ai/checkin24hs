# 🔍 Diagnóstico Completo Bad Gateway

## Verificaciones Necesarias

### 1. Verificar que los Servicios WhatsApp Respondan Directamente

Ejecuta estos comandos en el servidor:

```bash
# Probar cada puerto directamente
curl http://127.0.0.1:4001/api/qr?card=1
curl http://127.0.0.1:4002/api/qr?card=2
curl http://127.0.0.1:4003/api/qr?card=3
curl http://127.0.0.1:4004/api/qr?card=4
```

**Resultado esperado:** Deberías recibir respuestas JSON con QR codes.

**Si fallan:** Los servicios WhatsApp no están respondiendo correctamente.

---

### 2. Verificar Configuración NGINX en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Verifica que las rutas estén configuradas así:
   - `/api1/` → `127.0.0.1:4001`
   - `/api2/` → `127.0.0.1:4002`
   - `/api3/` → `127.0.0.1:4003`
   - `/api4/` → `127.0.0.1:4004`

**Si están en 3001-3004:** Necesitas cambiarlas a 4001-4004.

---

### 3. Verificar Logs de NGINX

```bash
# Ver logs de error de NGINX
tail -f /var/log/nginx/error.log

# O si NGINX está en un contenedor Docker
docker logs [NOMBRE_CONTENEDOR_NGINX] 2>&1 | tail -50
```

**Busca errores como:**
- `connect() failed (111: Connection refused)` → El puerto no está escuchando
- `upstream timed out` → El servicio no responde
- `no live upstreams` → No hay servicios disponibles

---

### 4. Verificar que NGINX se Recargó

Después de cambiar las rutas en EasyPanel, NGINX debería recargarse automáticamente. Si no, puedes:

1. En EasyPanel, busca un botón **"Reconstruir"** o **"Redeploy"** del servicio `whatsapp-api`
2. O reiniciar el servicio manualmente

---

### 5. Verificar desde el Servidor

```bash
# Probar las rutas NGINX desde el servidor
curl http://localhost/api1/api/qr?card=1
curl http://localhost/api2/api/qr?card=2
curl http://localhost/api3/api/qr?card=3
curl http://localhost/api4/api/qr?card=4

# O probar con el dominio
curl http://configwp.checkin24hs.com/api1/api/qr?card=1
```

---

## Posibles Problemas

### Problema 1: Rutas NGINX No Actualizadas

**Solución:** Verifica en EasyPanel que las rutas apunten a 4001-4004, no a 3001-3004.

### Problema 2: NGINX No se Recargó

**Solución:** Reinicia el servicio `whatsapp-api` en EasyPanel.

### Problema 3: Servicios WhatsApp No Responden

**Solución:** Verifica que los servicios estén funcionando correctamente con `curl`.

### Problema 4: Configuración NGINX Incorrecta

**Solución:** Verifica que la configuración NGINX tenga el formato correcto (ver archivo `configuracion-nginx-rutas.txt`).

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `curl http://127.0.0.1:4001/api/qr?card=1`
2. `curl http://127.0.0.1:4002/api/qr?card=2`
3. `curl http://127.0.0.1:4003/api/qr?card=3`
4. `curl http://127.0.0.1:4004/api/qr?card=4`
5. Verifica en EasyPanel que las rutas estén en 4001-4004

Con esta información podremos identificar exactamente qué está fallando.
