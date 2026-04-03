# 🔧 SOLUCIÓN ERROR 504 GATEWAY TIMEOUT - WEBMAIL

## 📋 PROBLEMA

```
GET https://webmail.checkin24hs.com/ 504 (Gateway Timeout)
```

**Error 504 Gateway Timeout** significa que:
- Traefik está intentando conectarse al servicio webmail
- El servicio webmail **NO está respondiendo** dentro del tiempo límite
- Traefik espera una respuesta pero el servicio tarda demasiado o no responde

## 🔍 DIAGNÓSTICO RÁPIDO

Ejecuta en el servidor:

```bash
cd ~/checkin24hs
git pull origin main
chmod +x DIAGNOSTICAR_WEBMAIL_504.sh
./DIAGNOSTICAR_WEBMAIL_504.sh
```

Este script verificará:
- ✅ Estado del servicio webmail
- ✅ Logs del servicio
- ✅ Configuración de Traefik
- ✅ Puertos y conectividad

## 🎯 SOLUCIONES COMUNES

### Solución 1: Verificar que el servicio esté corriendo

**En EasyPanel:**
1. Ve a **Servicios** → **webmail**
2. Verifica que el estado sea **🟢 Verde** (corriendo)
3. Si está **🔴 Rojo** o **🟡 Amarillo**, haz clic en **"Iniciar"** o **"Reiniciar"**

**Desde terminal:**
```bash
# Ver estado del servicio
docker service ls | grep webmail

# Ver contenedores
docker ps | grep webmail

# Si no está corriendo, iniciarlo
docker service update --force checkin24hs_webmail
```

### Solución 2: Verificar configuración de Traefik

El servicio webmail debe tener estas labels de Traefik:

```bash
# Verificar labels actuales
docker service inspect checkin24hs_webmail --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep traefik
```

**Si faltan labels, configurar Traefik:**

```bash
cd ~/checkin24hs
chmod +x CONFIGURAR_TRAEFIK_WEBMAIL.sh
./CONFIGURAR_TRAEFIK_WEBMAIL.sh
```

O manualmente:

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.webmail.entrypoints=web" \
  --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
  checkin24hs_webmail
```

### Solución 3: Verificar que el servicio esté en la red de Traefik

```bash
# Verificar red de Traefik
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
echo "Red de EasyPanel: $EASYPANEL_NET"

# Agregar webmail a la red si no está
docker service update --network-add $EASYPANEL_NET checkin24hs_webmail
```

### Solución 4: Verificar puerto interno del servicio

**En EasyPanel:**
1. Ve a **Servicios** → **webmail** → **Dominios**
2. Verifica que el puerto sea **80** (puerto interno de Roundcube)
3. Si el puerto es diferente, cámbialo a **80**

**Desde terminal:**
```bash
# Ver puerto configurado en Traefik
docker service inspect checkin24hs_webmail --format '{{range $k, $v := .Spec.Labels}}{{if eq $k "traefik.http.services.webmail.loadbalancer.server.port"}}{{$v}}{{end}}{{end}}'

# Debe mostrar: 80
```

### Solución 5: Verificar logs del servicio

**En EasyPanel:**
1. Ve a **Servicios** → **webmail** → **Registros**
2. Busca errores como:
   - `Connection refused`
   - `Cannot connect to database`
   - `Permission denied`
   - `Port already in use`

**Desde terminal:**
```bash
# Ver logs recientes
docker service logs checkin24hs_webmail --tail 50

# Ver logs en tiempo real
docker service logs -f checkin24hs_webmail
```

### Solución 6: Reiniciar el servicio

```bash
# Forzar reinicio del servicio
docker service update --force checkin24hs_webmail

# Esperar 30 segundos
sleep 30

# Verificar que esté corriendo
docker service ps checkin24hs_webmail
```

### Solución 7: Verificar recursos (memoria/CPU)

**En EasyPanel:**
1. Ve a **Servicios** → **webmail** → **Recursos**
2. Verifica que tenga:
   - **Memoria**: Al menos 512 MB (mejor 1024 MB)
   - **CPU**: Al menos 0.5 (mejor 1.0)
3. Si están muy bajos, **auméntalos** y guarda

### Solución 8: Verificar que el contenedor esté respondiendo

```bash
# Obtener ID del contenedor
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

# Probar acceso interno
docker exec $WEBMAIL_CONTAINER curl -s -o /dev/null -w "%{http_code}" http://localhost:80

# Debe mostrar: 200
```

## 📊 CHECKLIST DE VERIFICACIÓN

- [ ] Servicio webmail está corriendo (🟢 Verde en EasyPanel)
- [ ] Labels de Traefik están configuradas correctamente
- [ ] Servicio está en la red de Traefik
- [ ] Puerto interno es 80
- [ ] No hay errores en los logs
- [ ] Recursos (memoria/CPU) son suficientes
- [ ] Contenedor responde en puerto 80 internamente

## 🚨 SI NADA FUNCIONA

1. **Reconstruir el servicio desde cero:**
   - En EasyPanel, elimina el servicio webmail
   - Crea un nuevo servicio con la imagen `roundcube/roundcubemail:1.6.11-apache`
   - Configura las variables de entorno necesarias
   - Configura Traefik nuevamente

2. **Verificar que no haya conflictos de puertos:**
   ```bash
   # Ver qué está usando el puerto 80
   docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 80
   ```

3. **Contactar soporte de EasyPanel** si el problema persiste

## 📝 NOTAS IMPORTANTES

- **Puerto interno**: Roundcube usa puerto **80** dentro del contenedor
- **Puerto externo**: Traefik mapea el dominio `webmail.checkin24hs.com` al puerto interno 80
- **Timeout**: Traefik tiene un timeout por defecto de 60 segundos. Si el servicio tarda más, puede dar 504.

## 🔄 DESPUÉS DE APLICAR LA SOLUCIÓN

1. Espera 30-60 segundos para que los cambios se apliquen
2. Prueba acceder a: `https://webmail.checkin24hs.com/`
3. Si sigue dando 504, ejecuta el script de diagnóstico nuevamente
