# 🚀 Crear Servicio Cotizador por SSH (Alternativa a EasyPanel)

Si no puedes acceder a EasyPanel o prefieres hacerlo por SSH, puedes crear el servicio directamente con Docker.

---

## 📤 PASO 1: Subir archivos al servidor

**Desde PowerShell en tu computadora:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Subir archivos necesarios
scp cotizador-cliente.html root@72.61.58.240:/root/checkin24hs/
scp supabase-config.js root@72.61.58.240:/root/checkin24hs/
scp supabase-client.js root@72.61.58.240:/root/checkin24hs/
scp Dockerfile.cotizador root@72.61.58.240:/root/checkin24hs/
```

---

## 🔍 PASO 2: Conectarse al servidor y verificar

```bash
ssh root@72.61.58.240
cd /root/checkin24hs

# Verificar que los archivos estén
ls -la cotizador-cliente.html
ls -la supabase-config.js
ls -la supabase-client.js
ls -la Dockerfile.cotizador
```

---

## 🐳 PASO 3: Construir la imagen Docker

```bash
cd /root/checkin24hs

# Construir la imagen
docker build -f Dockerfile.cotizador -t cotizador:latest .

# Verificar que se construyó
docker images | grep cotizador
```

---

## 🚀 PASO 4: Crear servicio Docker Swarm

```bash
# Verificar que estás en modo Swarm
docker info | grep Swarm

# Si no está activo, inicializar (solo si es necesario)
# docker swarm init

# Crear el servicio
docker service create \
  --name cotizador \
  --network easypanel \
  --replicas 1 \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label "traefik.http.routers.cotizador.entrypoints=web" \
  --label "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label "traefik.http.services.cotizador.loadbalancer.server.port=80" \
  cotizador:latest
```

---

## ✅ PASO 5: Verificar que funciona

```bash
# Ver el servicio
docker service ls | grep cotizador

# Ver logs
docker service logs cotizador --tail 50

# Verificar que Traefik detectó el dominio
docker logs traefik --tail 100 | grep cotizar

# Probar desde el servidor
curl -I http://localhost:80
```

---

## 🌐 PASO 6: Verificar desde el navegador

1. **Espera 2-3 minutos** para que Traefik actualice la configuración
2. **Accede a:** `https://cotizar.checkin24hs.com`
3. **Verifica:**
   - ✅ El formulario se carga correctamente
   - ✅ Los hoteles se cargan desde Supabase
   - ✅ El teléfono se autocompleta desde URL

---

## 🔄 Si necesitas actualizar el servicio

```bash
# Reconstruir la imagen
cd /root/checkin24hs
docker build -f Dockerfile.cotizador -t cotizador:latest .

# Actualizar el servicio
docker service update --force cotizador
```

---

## 🆘 Solución de problemas

### El servicio no se crea:
```bash
# Ver errores
docker service ps cotizador --no-trunc

# Ver logs detallados
docker service logs cotizador
```

### Traefik no detecta el dominio:
```bash
# Verificar que el servicio está en la red correcta
docker service inspect cotizador | grep -A 5 Networks

# Verificar logs de Traefik
docker logs traefik --tail 200 | grep -i cotizar
```

### Error 404:
```bash
# Verificar que el contenedor está corriendo
docker ps | grep cotizador

# Verificar logs del contenedor
docker logs $(docker ps | grep cotizador | awk '{print $1}') --tail 50
```

---

## 📝 Resumen de comandos

```bash
# 1. Construir imagen
docker build -f Dockerfile.cotizador -t cotizador:latest .

# 2. Crear servicio
docker service create \
  --name cotizador \
  --network easypanel \
  --replicas 1 \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label "traefik.http.routers.cotizador.entrypoints=web" \
  --label "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label "traefik.http.services.cotizador.loadbalancer.server.port=80" \
  cotizador:latest

# 3. Verificar
docker service ls | grep cotizador
docker service logs cotizador --tail 50
```

---

**Última actualización:** 2025-01-27
