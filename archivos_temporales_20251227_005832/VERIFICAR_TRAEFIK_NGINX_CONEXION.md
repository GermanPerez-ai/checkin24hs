# 🔍 Verificar Conexión Traefik → NGINX

## Verificaciones Necesarias

### 1. Verificar que Solo Exista el Dominio Principal

**IMPORTANTE:** Asegúrate de que solo exista este dominio:
- `https://configwp.checkin24hs.com/` → `http://checkin24hs_whatsapp-api:80/`

**NO deben existir:**
- `https://configwp.checkin24hs.com/api1/` → `checkin24hs_whatsapp-api:4001`
- `https://configwp.checkin24hs.com/api2/` → `checkin24hs_whatsapp-api:4002`
- etc.

---

### 2. Ver Logs de NGINX Mientras Haces una Petición

```bash
# En una terminal, ver logs de NGINX en tiempo real
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm tail -f /var/log/nginx/access.log

# En otra terminal (o después de unos segundos), hacer la petición:
curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1
```

**¿Aparece algo en los logs de NGINX?**
- Si **SÍ aparece**: NGINX está recibiendo las peticiones, el problema está en el proxy a los servicios WhatsApp
- Si **NO aparece**: Traefik no está enrutando al contenedor NGINX

---

### 3. Ver Logs de Traefik

```bash
# Ver logs de Traefik mientras haces la petición
docker logs -f traefik.1.l3jle8lgzwo2qxrktvclbdbpy 2>&1 | grep -i "whatsapp-api\|configwp\|502\|bad"
```

---

### 4. Verificar Configuración del Dominio Principal

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api** → **Dominios**
2. Edita el dominio `https://configwp.checkin24hs.com/`
3. Verifica que esté así:
   - **Host:** `configwp.checkin24hs.com`
   - **Ruta:** `/` (o vacío)
   - **Destino:**
     - Protocolo: **HTTP**
     - Puerto: **80**
     - Ruta: `/`
4. **Guarda**

---

### 5. Verificar que el Contenedor NGINX Esté Escuchando

```bash
# Ver si NGINX está escuchando en el puerto 80 dentro del contenedor
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm netstat -tlnp | grep :80

# Ver procesos de NGINX
docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm ps aux | grep nginx
```

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm tail -20 /var/log/nginx/access.log`
2. `docker exec checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm netstat -tlnp | grep :80`
3. Verifica en EasyPanel que solo exista el dominio principal `configwp.checkin24hs.com/` apuntando a puerto 80

Con esta información podremos identificar exactamente dónde está el problema.


