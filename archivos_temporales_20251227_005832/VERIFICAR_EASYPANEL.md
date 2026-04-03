# Verificar y Corregir EasyPanel

## Problema
EasyPanel puede estar usando una versión antigua del archivo desde:
1. GitHub (si está configurado para hacer deploy desde GitHub)
2. Caché de EasyPanel
3. Volumen persistente de Docker

## Soluciones

### Opción 1: Forzar Rebuild en EasyPanel
1. Ve a EasyPanel → Proyecto `checkin24hs` → Servicio `dashboard`
2. Click en **"Rebuild"** o **"Redeploy"**
3. Esto forzará a EasyPanel a reconstruir el contenedor con el archivo actualizado

### Opción 2: Verificar Source en EasyPanel
1. Ve a EasyPanel → Proyecto `checkin24hs` → Servicio `dashboard`
2. Verifica la sección **"Source"**:
   - Si dice **"GitHub"**: Necesitas hacer commit y push del archivo
   - Si dice **"Local"** o **"Volume"**: El archivo debe estar en `/root/checkin24hs/deploy/`

### Opción 3: Verificar Volumen en EasyPanel
1. Ve a EasyPanel → Proyecto `checkin24hs` → Servicio `dashboard`
2. Verifica **"Volumes"**:
   - Debe mapear `/root/checkin24hs/deploy` a `/app` en el contenedor
   - O debe copiar el archivo durante el build

### Opción 4: Actualizar directamente en el contenedor (TEMPORAL)
Si EasyPanel está usando volúmenes, puedes actualizar directamente:
```bash
# En el servidor
cd /root/checkin24hs
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    docker restart $container
done
```

### Opción 5: Si usa GitHub
Si EasyPanel está configurado para usar GitHub:
1. Haz commit del archivo:
```bash
cd C:\Users\German\Downloads\Checkin24hs
git add deploy/dashboard.html
git commit -m "Fix: Corregir errores JavaScript línea 5150 y funciones globales"
git push
```
2. Luego en EasyPanel, haz click en **"Deploy"** o **"Redeploy"**

## Verificar qué está usando EasyPanel

En el servidor, ejecuta:
```bash
# Ver volúmenes del contenedor
docker inspect $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard" | head -1) | grep -A 10 "Mounts"

# Ver de dónde viene el archivo
docker exec $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard" | head -1) ls -la /app/dashboard.html
```

