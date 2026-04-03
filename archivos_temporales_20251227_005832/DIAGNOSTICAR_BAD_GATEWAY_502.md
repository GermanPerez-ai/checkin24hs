# 🔍 Diagnosticar Bad Gateway (502) - WhatsApp API

## Problema
El error **502 Bad Gateway** significa que NGINX recibe la petición pero no puede conectar con el backend (puertos 3001-3004).

## Pasos para Diagnosticar

### 1. Verificar que los Servicios WhatsApp Estén Corriendo

Ejecuta estos comandos en el servidor:

```bash
# Verificar si hay procesos escuchando en los puertos 3001-3004
netstat -tlnp | grep -E ':(3001|3002|3003|3004)'

# O usar ss (más moderno)
ss -tlnp | grep -E ':(3001|3002|3003|3004)'

# Verificar procesos de Node.js relacionados con WhatsApp
ps aux | grep -i whatsapp
ps aux | grep -i node
```

**Resultado esperado:**
- Deberías ver procesos escuchando en los puertos 3001, 3002, 3003, 3004
- Si no ves nada, los servicios WhatsApp no están corriendo

---

### 2. Verificar Supervisor (Gestor de Procesos)

```bash
# Ver estado de todos los servicios gestionados por supervisor
supervisorctl status

# Ver logs de un servicio específico (si existe)
supervisorctl tail -f whatsapp-1
supervisorctl tail -f whatsapp-2
supervisorctl tail -f whatsapp-3
supervisorctl tail -f whatsapp-4
```

**Resultado esperado:**
- Deberías ver servicios `whatsapp-1`, `whatsapp-2`, `whatsapp-3`, `whatsapp-4` con estado `RUNNING`
- Si están `STOPPED` o `FATAL`, necesitas iniciarlos

---

### 3. Verificar Configuración NGINX en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Busca la sección **"Rutas"** o **"Proxy Routes"** o **"NGINX Routes"**
3. Verifica que existan estas rutas:
   - `/api1/` → `127.0.0.1:3001`
   - `/api2/` → `127.0.0.1:3002`
   - `/api3/` → `127.0.0.1:3003`
   - `/api4/` → `127.0.0.1:3004`

**Si las rutas no existen:**
- Necesitas agregarlas siguiendo el paso 5 de la guía

---

### 4. Verificar Logs de NGINX

```bash
# Ver logs de error de NGINX
tail -f /var/log/nginx/error.log

# O si está en otro lugar
docker logs [NOMBRE_CONTENEDOR_NGINX] 2>&1 | grep -i error
```

**Busca errores como:**
- `connect() failed (111: Connection refused)` → El puerto no está escuchando
- `upstream timed out` → El servicio no responde
- `no live upstreams` → No hay servicios disponibles

---

### 5. Probar Conexión Directa a los Puertos

```bash
# Probar si los puertos responden directamente
curl http://127.0.0.1:3001/api/qr?card=1
curl http://127.0.0.1:3002/api/qr?card=2
curl http://127.0.0.1:3003/api/qr?card=3
curl http://127.0.0.1:3004/api/qr?card=4
```

**Resultado esperado:**
- Deberías recibir una respuesta JSON con el QR code
- Si recibes `Connection refused`, el servicio no está corriendo
- Si recibes timeout, el servicio está corriendo pero no responde

---

### 6. Verificar Estado del Servicio en EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Verifica que el estado sea **"Running"** (verde)
3. Si está **"Stopped"** (rojo) o **"Restarting"** (amarillo), hay un problema

---

## Soluciones Comunes

### Si los Servicios WhatsApp NO Están Corriendo

**Opción A: Iniciarlos Manualmente**
```bash
# Si están gestionados por supervisor
supervisorctl start whatsapp-1
supervisorctl start whatsapp-2
supervisorctl start whatsapp-3
supervisorctl start whatsapp-4

# O si están en procesos separados
cd /ruta/a/whatsapp-api
node server.js --port 3001 --card 1 &
node server.js --port 3002 --card 2 &
node server.js --port 3003 --port 3003 --card 3 &
node server.js --port 3004 --card 4 &
```

**Opción B: Verificar Configuración de Supervisor**
```bash
# Ver configuración de supervisor
cat /etc/supervisor/conf.d/whatsapp.conf
# O buscar archivos de configuración
find /etc/supervisor -name "*whatsapp*"
```

---

### Si las Rutas NGINX NO Están Configuradas

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Busca **"Rutas"** o **"Proxy Routes"**
3. Agrega las 4 rutas según el paso 5 de la guía

---

### Si el Servicio en EasyPanel NO Está Funcionando

1. Ve a **EasyPanel** → **Servicios** → **whatsapp-api**
2. Haz clic en **"Reconstruir"** o **"Redeploy"**
3. Espera a que termine el despliegue
4. Verifica los logs del servicio

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `netstat -tlnp | grep -E ':(3001|3002|3003|3004)'`
2. `supervisorctl status`
3. Estado del servicio `whatsapp-api` en EasyPanel

Con esta información podremos identificar exactamente qué está fallando.


