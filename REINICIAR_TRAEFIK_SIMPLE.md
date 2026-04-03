# 🔄 Reiniciar Traefik - Guía Rápida

## 📋 Problema

Estás viendo errores 404:
- `/favicon.ico:1 Failed to load resource: the server responded with a status of 404`
- `(index):1 Failed to load resource: the server responded with a status of 404`

Esto significa que Traefik no está enrutando correctamente las solicitudes al servicio del dashboard.

---

## ✅ Solución: Reiniciar Traefik

### Opción 1: Si Traefik es un Servicio de Docker Swarm (Recomendado)

**Conéctate al servidor por SSH y ejecuta:**

```bash
# 1. Ver si Traefik es un servicio
docker service ls | grep traefik

# 2. Reiniciar el servicio de Traefik
docker service update --force traefik

# 3. Esperar 30 segundos
sleep 30

# 4. Verificar que se reinició
docker service ps traefik
```

### Opción 2: Si Traefik es un Contenedor

```bash
# 1. Ver contenedores de Traefik
docker ps | grep traefik

# 2. Reiniciar el contenedor (reemplaza <nombre> con el nombre real)
docker restart traefik

# O si tiene otro nombre
docker restart $(docker ps | grep traefik | awk '{print $1}' | head -1)
```

### Opción 3: Desde EasyPanel (Si está configurado)

1. Ve a EasyPanel: `http://72.61.58.240:3000`
2. Busca el servicio **"traefik"** o **"proxy"**
3. Haz clic en **"Restart"** o **"Reiniciar"**
4. Espera 1-2 minutos

---

## 🔍 Verificar que Funciona

Después de reiniciar Traefik:

```bash
# 1. Ver logs de Traefik
docker service logs traefik --tail 50

# O si es un contenedor
docker logs traefik --tail 50

# 2. Verificar que no hay errores
# Busca mensajes como "dashboard.checkin24hs.com" en los logs

# 3. Probar acceso (desde el servidor)
curl -I http://dashboard.checkin24hs.com
curl -I https://dashboard.checkin24hs.com
```

---

## ⏱️ Tiempo de Espera

**Importante:** Después de reiniciar Traefik, espera **1-2 minutos** antes de probar el acceso, ya que Traefik necesita:
- Inicializar completamente
- Detectar los servicios
- Configurar las rutas

---

## 🆘 Si Sigue Sin Funcionar

Si después de reiniciar Traefik aún ves 404:

1. **Verifica que el servicio del dashboard esté corriendo:**
   ```bash
   docker service ps checkin24hs_dashboard
   # O
   docker ps | grep dashboard
   ```

2. **Verifica las etiquetas de Traefik del servicio:**
   ```bash
   docker service inspect checkin24hs_dashboard | grep -A 30 Labels
   ```

3. **Verifica los logs de Traefik para errores:**
   ```bash
   docker service logs traefik --tail 100 | grep -i error
   ```

---

## 📝 Nota

Si estás usando EasyPanel y el dashboard está configurado correctamente, EasyPanel debería gestionar Traefik automáticamente. En ese caso, solo necesitas:
1. Ir a EasyPanel
2. Buscar el servicio "dashboard"
3. Hacer clic en "Deploy" o "Redeploy"
4. Esperar que se despliegue

Esto debería actualizar Traefik automáticamente.
