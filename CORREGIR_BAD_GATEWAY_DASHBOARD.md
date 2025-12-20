# 🔧 Corregir Bad Gateway del Dashboard - Guía Rápida

## 🎯 Dónde Corregir

El Bad Gateway del dashboard se corrige en **dos lugares**:

1. **En el servidor (SSH)**: Actualizar la configuración de Traefik
2. **En EasyPanel**: Verificar que el servicio esté corriendo correctamente

---

## ✅ Solución Rápida: Usar el Script Automático

### En el Servidor (SSH):

```bash
# Conectarse al servidor
ssh root@72.61.58.240

# Ejecutar el script
bash actualizar_dashboard_traefik.sh
```

El script:
- ✅ Obtiene la IP actual del contenedor dashboard
- ✅ Actualiza la configuración de Traefik automáticamente
- ✅ Verifica que Traefik pueda alcanzar el dashboard

---

## ✅ Solución Manual: Actualizar Traefik Directamente

### Paso 1: Conectarse al Servidor

```bash
ssh root@72.61.58.240
```

### Paso 2: Obtener la IP Actual del Dashboard

```bash
# Obtener IP del contenedor dashboard
DASHBOARD_IP=$(docker inspect $(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1) | grep -A 5 '"Networks"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4)

# Verificar la IP
echo "IP del dashboard: $DASHBOARD_IP"
```

### Paso 3: Hacer Backup de la Configuración

```bash
# Crear backup
cp /etc/easypanel/traefik/config/main.yaml /etc/easypanel/traefik/config/main.yaml.backup.$(date +%Y%m%d_%H%M%S)
```

### Paso 4: Actualizar la Configuración de Traefik

```bash
# Reemplazar la IP en la configuración
sed -i "s|\"url\": \"http://10.11.132.[0-9]*:3000/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" /etc/easypanel/traefik/config/main.yaml

# O si usa el nombre del servicio
sed -i "s|\"url\": \"http://checkin24hs_dashboard:3000/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" /etc/easypanel/traefik/config/main.yaml
```

### Paso 5: Verificar que se Actualizó

```bash
# Ver la configuración actualizada
grep -A 5 '"checkin24hs_dashboard-1":' /etc/easypanel/traefik/config/main.yaml | grep "url"
```

Debe mostrar: `"url": "http://10.11.132.XX:3000/"` (con la IP actual)

### Paso 6: Esperar y Probar

```bash
# Esperar 10-15 segundos para que Traefik recargue
sleep 15

# Probar acceso
curl -I http://localhost/dashboard.html
```

---

## 🔍 Verificar en EasyPanel

### Paso 1: Verificar que el Servicio Esté Corriendo

1. **Abre EasyPanel**
2. **Ve al servicio** `checkin24hs_dashboard` (o `dashboard`)
3. **Verifica el estado**:
   - 🟢 **Verde** = Servicio corriendo ✅
   - 🟡 **Amarillo** = Servicio iniciando (espera 2-3 minutos)
   - 🔴 **Rojo** = Servicio detenido (inícialo)

### Paso 2: Verificar el Puerto

1. **Ve a "Puertos"** o **"Ports"** del servicio
2. **Verifica**:
   - Puerto interno: `3000` (o el que usa el servicio)
   - Protocolo: `HTTP` o `TCP`

### Paso 3: Verificar Variables de Entorno

1. **Ve a "Variables de Entorno"**
2. **Verifica** que exista:
   ```
   PORT=3000
   ```

---

## 🆘 Si el Script No Funciona

### Problema 1: No Encuentra el Contenedor

**Solución**:
```bash
# Ver todos los contenedores
docker ps | grep dashboard

# Si no aparece, verificar servicios Docker Swarm
docker service ls | grep dashboard
```

### Problema 2: El Archivo de Configuración No Existe

**Solución**:
```bash
# Verificar que existe
ls -la /etc/easypanel/traefik/config/main.yaml

# Si no existe, buscar en otra ubicación
find /etc -name "main.yaml" 2>/dev/null
```

### Problema 3: Traefik No Recarga la Configuración

**Solución**:
```bash
# Reiniciar Traefik
docker service update --force traefik

# O reiniciar el contenedor
docker restart $(docker ps | grep traefik | awk '{print $1}' | head -1)
```

---

## 📋 Checklist de Verificación

Después de actualizar, verifica:

- [ ] El servicio dashboard está en verde (Running)
- [ ] La IP se actualizó en `/etc/easypanel/traefik/config/main.yaml`
- [ ] Traefik puede alcanzar el dashboard (verificado con el script)
- [ ] Pasaron 10-15 segundos desde la actualización
- [ ] El dashboard responde en `https://dashboard.checkin24hs.com`

---

## 🎯 Resumen

**Dónde corregir**:
1. **En el servidor (SSH)**: `/etc/easypanel/traefik/config/main.yaml`
2. **En EasyPanel**: Verificar que el servicio esté corriendo

**Cómo corregir**:
1. **Opción rápida**: Ejecutar `actualizar_dashboard_traefik.sh` en el servidor
2. **Opción manual**: Actualizar la IP en `main.yaml` manualmente

**Tiempo**: 10-15 segundos después de actualizar, el dashboard debería funcionar.

---

## 📖 Archivos Relacionados

- `actualizar_dashboard_traefik.sh` - Script automático
- `SOLUCION_BAD_GATEWAY_DASHBOARD.md` - Guía completa de solución

