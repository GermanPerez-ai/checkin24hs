# 🔧 SOLUCIÓN: Bad Gateway en Dashboard

## 🎯 Problema

El dashboard muestra **"Bad Gateway"**, lo que significa que Traefik no puede comunicarse con el contenedor del dashboard.

---

## 🔍 Diagnóstico Rápido

### Verificar que el contenedor esté corriendo:

```bash
docker ps | grep dashboard
```

Si no aparece, el contenedor está detenido. Inícialo desde EasyPanel.

---

## ✅ Solución Automática (Recomendada)

Usa el script `corregir_bad_gateway.sh` que:

1. ✅ Verifica que el contenedor esté corriendo
2. ✅ Obtiene la IP correcta del contenedor
3. ✅ Detecta el puerto correcto
4. ✅ Hace backup de la configuración de Traefik
5. ✅ Actualiza la configuración con la IP correcta
6. ✅ Reinicia Traefik
7. ✅ Verifica que todo funcione

### Cómo usar:

```bash
# En el servidor (SSH)
bash corregir_bad_gateway.sh
```

---

## 🔧 Solución Manual (Paso a Paso)

### Paso 1: Verificar el contenedor

```bash
# Ver contenedores del dashboard
docker ps | grep dashboard

# Si no aparece, ver todos (incluyendo detenidos)
docker ps -a | grep dashboard
```

### Paso 2: Obtener la IP del contenedor

```bash
DASHBOARD_CONTAINER=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
DASHBOARD_IP=$(docker inspect $DASHBOARD_CONTAINER | grep -A 10 '"Networks"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP: $DASHBOARD_IP"
```

### Paso 3: Verificar el puerto

```bash
# Ver puertos expuestos
docker port $DASHBOARD_CONTAINER

# O verificar en la configuración del contenedor
docker inspect $DASHBOARD_CONTAINER | grep -A 10 '"ExposedPorts"'
```

### Paso 4: Hacer backup de Traefik

```bash
cp /etc/easypanel/traefik/config/main.yaml /etc/easypanel/traefik/config/main.yaml.backup.$(date +%Y%m%d_%H%M%S)
```

### Paso 5: Actualizar configuración de Traefik

```bash
TRAEFIK_CONFIG="/etc/easypanel/traefik/config/main.yaml"
sed -i "s|\"url\": \"http://10\.[0-9]*\.[0-9]*\.[0-9]*:[0-9]*/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" "$TRAEFIK_CONFIG"
sed -i "s|\"url\": \"http://checkin24hs_dashboard:[0-9]*/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" "$TRAEFIK_CONFIG"
```

### Paso 6: Reiniciar Traefik

```bash
# Opción A: Si está en modo Docker Swarm
docker service ls | grep traefik
TRAEFIK_SERVICE=$(docker service ls | grep traefik | awk '{print $2}' | head -1)
docker service update --force "$TRAEFIK_SERVICE"

# Opción B: Si es un contenedor normal
docker restart $(docker ps | grep traefik | awk '{print $1}' | head -1)
```

### Paso 7: Esperar y verificar

```bash
# Esperar 15-20 segundos
sleep 15

# Verificar logs
docker logs $DASHBOARD_CONTAINER --tail 20
docker logs $(docker ps | grep traefik | awk '{print $1}' | head -1) --tail 20
```

---

## 🔍 Verificación

Después de aplicar la solución:

1. **Abre:** `https://dashboard.checkin24hs.com`
2. **Espera:** 15-30 segundos para que Traefik se reinicie
3. **Recarga:** La página con Ctrl+F5
4. **Verifica:** Que ya no aparezca "Bad Gateway"

---

## ⚠️ Problemas Comunes

### Problema: "No se encontró el contenedor"

**Solución:**
- Ve a EasyPanel
- Verifica que el servicio "dashboard" esté activo
- Si está detenido, inícialo desde EasyPanel

### Problema: "El contenedor no responde"

**Solución:**
- Verifica los logs: `docker logs $DASHBOARD_CONTAINER`
- Verifica que el servicio esté escuchando en el puerto correcto
- Espera unos segundos más (el servicio puede estar iniciando)

### Problema: "No se encontró el archivo de configuración de Traefik"

**Solución:**
- Verifica la ruta: `ls -la /etc/easypanel/traefik/config/`
- Busca archivos de configuración: `find /etc/easypanel -name "*.yaml" -o -name "*.yml"`

### Problema: "Bad Gateway persiste después de 30 segundos"

**Solución:**
1. Verifica los logs del dashboard: `docker logs $DASHBOARD_CONTAINER --tail 50`
2. Verifica los logs de Traefik: `docker logs $(docker ps | grep traefik | awk '{print $1}' | head -1) --tail 50`
3. Verifica que la IP sea correcta: `docker inspect $DASHBOARD_CONTAINER | grep -A 10 '"Networks"'`
4. Verifica que el puerto sea correcto: `docker port $DASHBOARD_CONTAINER`

---

## 📋 Checklist

- [ ] Contenedor del dashboard está corriendo
- [ ] IP del contenedor obtenida correctamente
- [ ] Puerto del contenedor verificado
- [ ] Backup de configuración de Traefik creado
- [ ] Configuración de Traefik actualizada
- [ ] Traefik reiniciado
- [ ] Esperado 15-30 segundos
- [ ] Dashboard carga correctamente (sin Bad Gateway)

---

**¡Listo! Después de seguir estos pasos, el Bad Gateway debería estar resuelto.**

