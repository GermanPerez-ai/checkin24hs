# 🔧 Solución: Error del Servidor en Webmail

## 📋 Problema Reportado

1. **Webmail muy lento** después del login
2. **Error 504 Gateway Timeout** - Tuvo que intentar 3 veces
3. **Error del servidor** una vez dentro del webmail (como se ve en la imagen)

## 🔍 Diagnóstico

El error "Error del servidor" dentro de Roundcube puede tener varias causas:

### Causas Comunes:

1. **Base de datos no accesible o lenta**
   - Roundcube no puede conectarse a la BD
   - La BD está respondiendo muy lento
   - La BD está sobrecargada

2. **Recursos insuficientes (CPU/RAM)**
   - El contenedor no tiene suficiente memoria
   - CPU limitado causa lentitud

3. **Timeouts muy cortos**
   - Traefik tiene timeout de 60s por defecto
   - Si el webmail tarda más, da 504

4. **Problemas de conexión al servidor de correo**
   - Roundcube no puede conectarse al servidor IMAP/SMTP
   - Credenciales incorrectas

5. **Problemas con PHP o Apache dentro del contenedor**
   - PHP está sobrecargado
   - Apache no puede procesar las peticiones

## 🎯 Soluciones

### Solución 1: Ejecutar Script de Optimización (RECOMENDADO)

```bash
cd /root/checkin24hs
git pull origin main
chmod +x OPTIMIZAR_WEBMAIL_RENDIMIENTO.sh
./OPTIMIZAR_WEBMAIL_RENDIMIENTO.sh
```

Este script:
- ✅ Aumenta timeouts en Traefik
- ✅ Configura health checks
- ✅ Verifica recursos
- ✅ Revisa logs para errores
- ✅ Reinicia el servicio

### Solución 2: Aumentar Recursos en EasyPanel

1. **Accede a EasyPanel** → Servicios → **webmail**
2. **Ve a "Recursos"** o **"Resources"**
3. **Aumenta:**
   - **CPU**: De 0.5 a **2.0** (o más si es posible)
   - **RAM**: De 512MB a **2048 MB** (o más si es posible)
4. **Guarda** y espera 1-2 minutos

### Solución 3: Verificar Variables de Entorno

1. **En EasyPanel** → Servicios → **webmail** → **Variables de Entorno**
2. **Verifica que tenga:**
   ```
   ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
   ROUNDCUBEMAIL_DB_TYPE=mysql
   ROUNDCUBEMAIL_DB_HOST=db
   ROUNDCUBEMAIL_DB_NAME=roundcube
   ROUNDCUBEMAIL_DB_USER=roundcube
   ROUNDCUBEMAIL_DB_PASSWORD=tu_password
   ```
3. **Si faltan variables**, agrégalas según la documentación de Roundcube

### Solución 4: Verificar Logs para Errores Específicos

```bash
# Ver logs completos
docker service logs checkin24hs_webmail --tail 200

# Buscar errores específicos
docker service logs checkin24hs_webmail --tail 200 | grep -iE "error|database|connection|timeout|fatal"

# Ver logs en tiempo real
docker service logs -f checkin24hs_webmail
```

**Busca errores como:**
- `Database connection failed`
- `Connection timeout`
- `Fatal error`
- `PHP Fatal error`
- `Cannot connect to database`

### Solución 5: Verificar Conexión a Base de Datos

```bash
# Obtener contenedor
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

# Ver variables de entorno
docker exec $WEBMAIL_CONTAINER env | grep -iE "database|db|mysql"

# Probar conexión a BD (si tienes mysql-client)
docker exec $WEBMAIL_CONTAINER mysql -h [DB_HOST] -u [DB_USER] -p[DB_PASSWORD] [DB_NAME] -e "SELECT 1"
```

### Solución 6: Aumentar Timeouts en Traefik Manualmente

```bash
docker service update \
  --label-add "traefik.http.services.webmail.loadbalancer.healthcheck.interval=30s" \
  --label-add "traefik.http.services.webmail.loadbalancer.healthcheck.timeout=10s" \
  checkin24hs_webmail
```

### Solución 7: Reiniciar el Servicio

```bash
# Reiniciar forzando
docker service update --force checkin24hs_webmail

# Esperar 30-60 segundos
sleep 60

# Verificar estado
docker service ps checkin24hs_webmail
```

## 📊 Checklist de Verificación

- [ ] Recursos aumentados (CPU ≥ 2.0, RAM ≥ 2048 MB)
- [ ] Timeouts aumentados en Traefik
- [ ] Variables de entorno correctas
- [ ] Base de datos accesible
- [ ] Servicio reiniciado
- [ ] Logs revisados sin errores críticos
- [ ] Webmail accesible sin errores 504

## 🚨 Si el Error del Servidor Persiste

### Verificar en los Logs de Roundcube:

1. **Accede al contenedor:**
   ```bash
   WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
   docker exec -it $WEBMAIL_CONTAINER bash
   ```

2. **Ver logs de Roundcube:**
   ```bash
   tail -50 /var/www/html/logs/errors
   tail -50 /var/log/apache2/error.log
   ```

3. **Busca el error específico** que aparece cuando haces clic en "Web Check-In"

### Posibles Causas del Error Específico:

El error "Error del servidor" que aparece al hacer clic en el botón "Web Check-In" puede ser:

1. **Problema con el enlace en el email**
   - El enlace puede estar roto
   - El servidor de destino no responde

2. **Problema con PHP/Apache**
   - PHP no puede procesar la petición
   - Apache está sobrecargado

3. **Problema de permisos**
   - Roundcube no tiene permisos para procesar la acción

## 🔄 Después de Aplicar las Soluciones

1. **Espera 1-2 minutos** para que los cambios se apliquen
2. **Prueba acceder** a `https://webmail.checkin24hs.com/`
3. **Limpia la caché** del navegador: `Ctrl+Shift+R`
4. **Intenta hacer login** nuevamente
5. **Si el error persiste**, revisa los logs específicos

## 📝 Notas Importantes

- **Los cambios de recursos** pueden tardar 1-2 minutos en aplicarse
- **Los timeouts aumentados** ayudan con servicios lentos pero no solucionan problemas de BD
- **El error del servidor** dentro de Roundcube suele ser un problema de BD o PHP, no de Traefik
- **Si el problema es específico del botón "Web Check-In"**, puede ser un problema del enlace en el email, no del webmail
