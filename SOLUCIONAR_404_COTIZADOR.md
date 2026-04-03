# 🔧 Solucionar Error 404 en cotizar.checkin24hs.com

## 📋 Problema

Al acceder a `https://cotizar.checkin24hs.com/` después de implementar con EasyPanel, se obtiene error 404:
- `/favicon.ico:1 Failed to load resource: the server responded with a status of 404 ()`
- `(index):1 Failed to load resource: the server responded with a status of 404 ()`

---

## 🔍 Diagnóstico

### Paso 1: Ejecutar Script de Diagnóstico

En el servidor, ejecuta:

```bash
cd /root/checkin24hs
chmod +x DIAGNOSTICAR_404_COTIZADOR.sh
./DIAGNOSTICAR_404_COTIZADOR.sh
```

Este script verificará:
- ✅ Si el servicio existe
- ✅ Si está corriendo
- ✅ Si tiene configuración de Traefik
- ✅ Si tiene los archivos necesarios (`index.html`)
- ✅ Si está en la red `easypanel`

---

## ✅ Soluciones Posibles

### Solución 1: El servicio no tiene `index.html`

**Problema:** El contenedor no tiene el archivo `index.html` en `/usr/share/nginx/html/`

**Solución:**

1. **Verificar el Dockerfile del cotizador:**
   ```bash
   # En el servidor
   cat Dockerfile.cotizador
   # O si está en el repositorio
   cat /root/checkin24hs/Dockerfile.cotizador
   ```

2. **El Dockerfile debe copiar `cotizador-cliente.html` como `index.html`:**
   ```dockerfile
   FROM nginx:alpine
   
   # Copiar el archivo HTML como index.html
   COPY cotizador-cliente.html /usr/share/nginx/html/index.html
   COPY supabase-config.js /usr/share/nginx/html/
   COPY supabase-client.js /usr/share/nginx/html/
   
   EXPOSE 80
   
   CMD ["nginx", "-g", "daemon off;"]
   ```

3. **Si el Dockerfile no copia como `index.html`, corrígelo:**
   ```bash
   # Editar Dockerfile.cotizador
   nano Dockerfile.cotizador
   # Asegúrate de que tenga: COPY cotizador-cliente.html /usr/share/nginx/html/index.html
   ```

4. **Hacer rebuild del servicio en EasyPanel:**
   - Ve a EasyPanel → Servicio `cotizador`
   - Haz clic en **"Rebuild"** o **"Redeploy"**

---

### Solución 2: El servicio no está configurado en Traefik

**Problema:** El servicio existe pero Traefik no lo está enrutando

**Solución:**

1. **Ejecutar script de corrección:**
   ```bash
   cd /root/checkin24hs
   chmod +x CORREGIR_COTIZADOR_TRAEFIK.sh
   ./CORREGIR_COTIZADOR_TRAEFIK.sh
   ```

2. **O configurar manualmente en EasyPanel:**
   - Ve a EasyPanel → Servicio `cotizador`
   - Ve a la pestaña **"Dominios"**
   - Verifica que tenga: `cotizar.checkin24hs.com`
   - Si no está, agrégalo
   - Asegúrate de que **HTTPS** esté habilitado

3. **O configurar manualmente con Docker:**
   ```bash
   # Reemplazar <nombre_servicio> con el nombre real del servicio
   SERVICE_NAME="cotizador"  # o "checkin24hs_cotizador"
   
   docker service update \
     --label-add "traefik.enable=true" \
     --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
     --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
     --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
     --label-add "traefik.http.services.cotizador.loadbalancer.server.port=80" \
     $SERVICE_NAME
   ```

---

### Solución 3: El servicio no está en la red `easypanel`

**Problema:** El servicio no está conectado a la red de Traefik

**Solución:**

```bash
# Reemplazar <nombre_servicio> con el nombre real
SERVICE_NAME="cotizador"

# Agregar a la red easypanel
docker service update --network-add easypanel $SERVICE_NAME

# Esperar 30 segundos
sleep 30

# Verificar
docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'
```

---

### Solución 4: El puerto interno no es 80

**Problema:** El servicio está configurado en un puerto diferente a 80

**Solución:**

1. **Verificar el puerto actual:**
   ```bash
   docker service inspect cotizador --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}'
   ```

2. **Si no es 80, cambiarlo en EasyPanel:**
   - Ve a EasyPanel → Servicio `cotizador`
   - Ve a la pestaña **"Puertos"** o **"Ports"**
   - Cambia el puerto interno a **80**
   - Guarda y reinicia el servicio

---

### Solución 5: Los archivos no están en el servidor

**Problema:** Los archivos `cotizador-cliente.html`, `supabase-config.js`, `supabase-client.js` no están en el servidor

**Solución:**

1. **Copiar archivos al servidor:**
   ```powershell
   # Desde PowerShell en tu computadora
   cd c:\Users\German\Downloads\Checkin24hs
   
   scp cotizador-cliente.html root@TU_SERVIDOR_IP:/root/checkin24hs/
   scp supabase-config.js root@TU_SERVIDOR_IP:/root/checkin24hs/
   scp supabase-client.js root@TU_SERVIDOR_IP:/root/checkin24hs/
   ```

2. **O actualizar desde GitHub:**
   ```bash
   # En el servidor
   cd /root/checkin24hs
   git pull origin main
   ```

3. **Hacer rebuild del servicio en EasyPanel**

---

## 🔄 Proceso Completo de Verificación

### 1. Verificar que el servicio existe y está corriendo

```bash
docker service ls | grep -i cotizador
docker ps | grep -i cotizador
```

### 2. Verificar que tiene los archivos

```bash
# Reemplazar <container_name> con el nombre del contenedor
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep -i cotizador | head -1)

docker exec $CONTAINER_NAME ls -la /usr/share/nginx/html/
docker exec $CONTAINER_NAME cat /usr/share/nginx/html/index.html | head -10
```

### 3. Verificar configuración de Traefik

```bash
SERVICE_NAME="cotizador"  # o el nombre real
docker service inspect $SERVICE_NAME --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik
```

### 4. Verificar que está en la red easypanel

```bash
docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'
```

### 5. Verificar logs de Traefik

```bash
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
docker logs $TRAEFIK_CONTAINER --tail 100 | grep -i cotizar
```

---

## 📝 Checklist de Verificación

Antes de reportar el problema, verifica:

- [ ] El servicio existe en Docker: `docker service ls | grep cotizador`
- [ ] El servicio está corriendo: `docker ps | grep cotizador`
- [ ] El archivo `index.html` existe: `docker exec <container> ls /usr/share/nginx/html/index.html`
- [ ] El puerto interno es 80: `docker service inspect cotizador --format '{{range .Endpoint.Ports}}{{.TargetPort}}{{end}}'`
- [ ] Tiene etiquetas Traefik: `docker service inspect cotizador --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik`
- [ ] Está en la red easypanel: `docker service inspect cotizador --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'`
- [ ] DNS resuelve correctamente: `nslookup cotizar.checkin24hs.com`
- [ ] El dominio está configurado en EasyPanel

---

## 🆘 Si Nada Funciona

1. **Recrear el servicio en EasyPanel:**
   - Elimina el servicio actual
   - Crea uno nuevo siguiendo: `CONFIGURAR_COTIZADOR_EASYPANEL.md`

2. **Verificar logs detallados:**
   ```bash
   docker service logs cotizador --tail 100
   docker logs traefik --tail 200 | grep -i cotizar
   ```

3. **Verificar firewall:**
   ```bash
   sudo ufw status
   # Asegúrate de que los puertos 80 y 443 estén abiertos
   ```

---

**Última actualización:** 2026-01-23
