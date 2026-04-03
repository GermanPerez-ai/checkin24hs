# 🔍 Verificar Logs de NGINX

## Problema

El archivo `site.conf` existe y está correcto, pero sigue dando Bad Gateway.

## Verificaciones Necesarias

### 1. Ver Logs de NGINX

Ejecuta estos comandos para ver qué error específico está ocurriendo:

```bash
# Ver logs de error de NGINX
tail -100 /var/log/nginx/error.log

# O si NGINX está en un contenedor Docker
docker ps | grep nginx
docker logs [NOMBRE_CONTENEDOR_NGINX] 2>&1 | tail -50

# Ver si hay un contenedor de EasyPanel para whatsapp-api
docker ps | grep whatsapp-api
docker logs [NOMBRE_CONTENEDOR_WHATSAPP_API] 2>&1 | tail -50
```

**Busca errores como:**
- `connect() failed (111: Connection refused)` → El puerto no está escuchando
- `upstream timed out` → El servicio no responde
- `no live upstreams` → No hay servicios disponibles
- `bind() failed` → Puerto en uso
- `permission denied` → Problema de permisos

---

### 2. Verificar que el Servicio se Reinició

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Verifica que el error rojo haya desaparecido
3. Si sigue el error, haz clic en **"Reconstruir"** o **"Redeploy"** completo

---

### 3. Verificar Contenedor Docker

```bash
# Ver contenedores relacionados con whatsapp-api
docker ps -a | grep whatsapp-api

# Ver logs del contenedor
docker logs [NOMBRE_CONTENEDOR] 2>&1 | tail -50

# Ver si el archivo está montado correctamente
docker exec [NOMBRE_CONTENEDOR] ls -la /etc/nginx/conf.d/
docker exec [NOMBRE_CONTENEDOR] cat /etc/nginx/conf.d/site.conf
```

---

### 4. Verificar que NGINX Esté Escuchando

```bash
# Ver si NGINX está escuchando en el puerto 80
netstat -tlnp | grep :80
ss -tlnp | grep :80

# Ver procesos de NGINX
ps aux | grep nginx
```

---

### 5. Probar Conexión Directa desde el Contenedor

Si el servicio está en un contenedor Docker:

```bash
# Entrar al contenedor
docker exec -it [NOMBRE_CONTENEDOR] bash

# Desde dentro del contenedor, probar conexión
curl http://127.0.0.1:4001/api/qr?card=1
curl http://host.docker.internal:4001/api/qr?card=1
```

---

## Posibles Soluciones

### Solución 1: Reconstruir el Servicio Completo

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Haz clic en **"Reconstruir"** o **"Redeploy"**
3. Espera a que termine completamente
4. Prueba de nuevo

### Solución 2: Verificar Configuración de Rutas en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Ve a la sección **"Rutas"** o **"Proxy Routes"**
3. Verifica que las rutas estén configuradas correctamente
4. Si están vacías, agrégalas manualmente desde la interfaz

### Solución 3: Verificar Permisos del Archivo

```bash
# Verificar permisos
ls -la /etc/easypanel/projects/checkin24hs/whatsapp-api/generated/site.conf

# Si es necesario, ajustar permisos
chmod 644 /etc/easypanel/projects/checkin24hs/whatsapp-api/generated/site.conf
chown root:root /etc/easypanel/projects/checkin24hs/whatsapp-api/generated/site.conf
```

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `tail -100 /var/log/nginx/error.log`
2. `docker ps | grep whatsapp-api`
3. `docker logs [NOMBRE_CONTENEDOR] 2>&1 | tail -50`

Con esta información podremos identificar exactamente qué está fallando.


