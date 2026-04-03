# 🔧 Verificar y Configurar Traefik para Dashboard

## 🔍 Comandos para Verificar Traefik

### 1. Ver servicios de Docker Swarm

```bash
docker service ls | grep dashboard
```

### 2. Ver labels de Traefik del servicio

```bash
docker service inspect checkin24hs_dashboard --pretty | grep -i traefik
```

O más detallado:

```bash
docker service inspect checkin24hs_dashboard | grep -A 5 "Labels"
```

### 3. Verificar configuración de Traefik

```bash
# Ver configuración de Traefik
docker service ls | grep traefik

# Ver logs de Traefik
docker service logs checkin24hs_traefik --tail 50 | grep dashboard
```

### 4. Verificar si el servicio está en la red correcta

```bash
docker service inspect checkin24hs_dashboard | grep -i network
```

---

## 🔧 Solución: Configurar Labels de Traefik

Si faltan los labels de Traefik, necesitas agregarlos. En EasyPanel:

1. Ve a EasyPanel en tu navegador
2. Abre el servicio **"dashboard"**
3. Busca la sección **"Labels"** o **"Etiquetas"**
4. Agrega estas labels (si no existen):

```
traefik.enable=true
traefik.http.routers.dashboard.rule=Host(`dashboard.checkin24hs.com`)
traefik.http.routers.dashboard.entrypoints=websecure
traefik.http.routers.dashboard.tls.certresolver=letsencrypt
traefik.http.services.dashboard.loadbalancer.server.port=3000
```

5. **Guarda** y **reinicia** el servicio

---

## 📋 Verificar desde SSH

Si prefieres hacerlo desde SSH, verifica primero qué labels tiene:

```bash
docker service inspect checkin24hs_dashboard --pretty
```

Luego, si faltan labels, puedes actualizar el servicio (pero es mejor hacerlo desde EasyPanel).

---

**Ejecuta primero los comandos de verificación para ver qué está pasando con Traefik.**
