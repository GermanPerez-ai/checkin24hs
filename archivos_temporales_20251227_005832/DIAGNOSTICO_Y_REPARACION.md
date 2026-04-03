# 🔧 Diagnóstico y Reparación - Webmail y EasyPanel

## 📋 Paso 1: Diagnosticar Webmail (Bad Gateway)

Ejecuta estos comandos en el servidor:

```bash
# 1. Verificar servicios de webmail
docker ps | grep -i webmail
docker ps | grep -i roundcube

# 2. Ver logs del servicio webmail
docker logs $(docker ps | grep -i webmail | head -1 | awk '{print $1}') --tail 20

# 3. Verificar configuración Traefik para webmail
grep -A 10 -i "webmail\|roundcube" /etc/easypanel/traefik/config/main.yaml

# 4. Verificar que el servicio esté corriendo
docker service ls | grep -i webmail
```

---

## 📋 Paso 2: Diagnosticar EasyPanel

```bash
# 1. Verificar servicio EasyPanel
docker ps | grep -i easypanel

# 2. Ver en qué puerto corre EasyPanel
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -i easypanel

# 3. Verificar configuración de redirección
grep -A 10 -i "easypanel" /etc/easypanel/traefik/config/main.yaml

# 4. Verificar si hay un servicio específico de EasyPanel
docker service ls | grep -i easypanel
```

---

## 🔧 Solución 1: Arreglar Webmail

### Opción A: Si el servicio no está corriendo

```bash
# Ver todos los servicios de Docker Swarm
docker service ls

# Si existe el servicio webmail pero está detenido
docker service ps webmail --no-trunc

# Reiniciar el servicio
docker service update --force webmail
```

### Opción B: Si la configuración de Traefik está mal

```bash
# Ver configuración actual
cat /etc/easypanel/traefik/config/main.yaml | grep -A 15 "webmail"

# Editar configuración (si es necesario)
nano /etc/easypanel/traefik/config/main.yaml

# Después de editar, reiniciar Traefik
docker service update --force traefik
```

---

## 🔧 Solución 2: Arreglar EasyPanel

El problema es que EasyPanel está redirigiendo al puerto 3000 (dashboard) en lugar de su propio puerto.

### Paso 1: Identificar el puerto de EasyPanel

```bash
# Ver puerto de EasyPanel
docker ps | grep easypanel | grep -oP '\d+->\d+' | head -1

# O ver todos los puertos
docker inspect $(docker ps | grep easypanel | head -1 | awk '{print $1}') | grep -i port
```

### Paso 2: Verificar configuración de Hostinger/EasyPanel

EasyPanel normalmente corre en el puerto **8080** o **3000**. El problema es que está apuntando al dashboard.

```bash
# Ver configuración de redirección en Traefik
grep -B 5 -A 15 "easypanel\|3000" /etc/easypanel/traefik/config/main.yaml

# Ver si hay un servicio específico para EasyPanel
docker service ls | grep -i easypanel
```

### Paso 3: Corregir la redirección

Si EasyPanel corre en el puerto 8080, necesitamos:

1. **Verificar que EasyPanel esté accesible en 8080:**
```bash
curl http://localhost:8080
```

2. **Configurar Traefik para que apunte a EasyPanel en 8080:**
```bash
# Editar configuración
nano /etc/easypanel/traefik/config/main.yaml

# Buscar la sección de EasyPanel y cambiar:
# De: url: "http://72.61.58.240:3000"
# A: url: "http://72.61.58.240:8080" (o el puerto correcto)

# Reiniciar Traefik
docker service update --force traefik
```

---

## 📋 Paso 3: Actualizar Dashboard desde GitHub

```bash
# 1. Ir al directorio del dashboard
cd ~/checkin24hs

# 2. Hacer backup del dashboard.html actual
cp dashboard.html dashboard.html.backup.$(date +%Y%m%d_%H%M%S)

# 3. Hacer pull de los cambios desde GitHub
git pull origin main

# 4. Verificar que se actualizó dashboard.html
ls -lh dashboard.html
git log --oneline -5 -- dashboard.html

# 5. Reiniciar el servicio dashboard
pm2 restart dashboard

# 6. Verificar logs
pm2 logs dashboard --lines 20 --nostream
```

---

## ✅ Verificación Final

### Webmail:
```bash
# Probar acceso
curl -I http://localhost:80 -H "Host: webmail.checkin24hs.com"
```

### EasyPanel:
```bash
# Probar acceso local
curl -I http://localhost:8080

# Verificar desde Hostinger
# Ir a: https://hpanel.hostinger.com/vps/1152402/overview
# Hacer clic en "Gestionar panel"
# Debería llevarte a EasyPanel, no al dashboard
```

### Dashboard:
```bash
# Verificar que está corriendo
pm2 status | grep dashboard

# Ver logs
pm2 logs dashboard --lines 10 --nostream
```

