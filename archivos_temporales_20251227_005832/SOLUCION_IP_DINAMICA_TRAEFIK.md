# 🔧 Solución para IP Dinámica en Traefik

## 📋 Problema

Cada vez que reinicias o reimplementas un servicio en EasyPanel (como `webmail` o `dashboard`), el contenedor puede obtener una nueva IP. Esto causa errores de "Bad Gateway" porque Traefik sigue apuntando a la IP anterior.

## ✅ Solución: Scripts de Actualización

He creado dos scripts que puedes ejecutar en el servidor cada vez que reinicies un servicio:

### 1. Script para Webmail

**Archivo:** `actualizar_webmail_traefik.sh`

**Uso:**
```bash
# Subir el script al servidor (desde tu computadora)
scp actualizar_webmail_traefik.sh root@72.61.58.240:/root/

# En el servidor, hacer ejecutable y ejecutar
ssh root@72.61.58.240
chmod +x /root/actualizar_webmail_traefik.sh
/root/actualizar_webmail_traefik.sh
```

### 2. Script para Dashboard

**Archivo:** `actualizar_dashboard_traefik.sh`

**Uso:**
```bash
# Subir el script al servidor
scp actualizar_dashboard_traefik.sh root@72.61.58.240:/root/

# En el servidor, hacer ejecutable y ejecutar
ssh root@72.61.58.240
chmod +x /root/actualizar_dashboard_traefik.sh
/root/actualizar_dashboard_traefik.sh
```

## 🔄 Proceso Completo

### Cuando reinicies el servicio Webmail:

1. **En EasyPanel:**
   - Ve al servicio `webmail`
   - Haz clic en "Implementar" o reinicia el servicio
   - Espera 1-2 minutos

2. **En el servidor (SSH):**
   ```bash
   /root/actualizar_webmail_traefik.sh
   ```

3. **Espera 10-15 segundos** para que Traefik recargue

4. **Prueba:** `http://webmail.checkin24hs.com`

### Cuando reinicies el servicio Dashboard:

1. **En EasyPanel:**
   - Ve al servicio `dashboard`
   - Haz clic en "Implementar" o reinicia el servicio
   - Espera 1-2 minutos

2. **En el servidor (SSH):**
   ```bash
   /root/actualizar_dashboard_traefik.sh
   ```

3. **Espera 10-15 segundos** para que Traefik recargue

4. **Prueba:** `http://dashboard.checkin24hs.com`

## 📝 Comandos Manuales (Alternativa)

Si prefieres ejecutar los comandos manualmente:

### Para Webmail:
```bash
# Obtener IP actual
WEBMAIL_IP=$(docker inspect $(docker ps | grep webmail | awk '{print $1}' | head -1) | grep -A 5 '"Networks"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4)

# Actualizar Traefik
sed -i "s|\"url\": \"http://10.11.132.[0-9]*:80/\"|\"url\": \"http://${WEBMAIL_IP}:80/\"|g" /etc/easypanel/traefik/config/main.yaml
sed -i "s|\"url\": \"http://checkin24hs_webmail:80/\"|\"url\": \"http://${WEBMAIL_IP}:80/\"|g" /etc/easypanel/traefik/config/main.yaml
```

### Para Dashboard:
```bash
# Obtener IP actual
DASHBOARD_IP=$(docker inspect $(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1) | grep -A 5 '"Networks"' | grep '"IPv4Address"' | head -1 | cut -d'"' -f4)

# Actualizar Traefik
sed -i "s|\"url\": \"http://10.11.132.[0-9]*:3000/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" /etc/easypanel/traefik/config/main.yaml
sed -i "s|\"url\": \"http://checkin24hs_dashboard:3000/\"|\"url\": \"http://${DASHBOARD_IP}:3000/\"|g" /etc/easypanel/traefik/config/main.yaml
```

## 🔍 Verificar que Funcionó

Después de ejecutar el script, verifica:

```bash
# Para webmail
grep -A 5 '"checkin24hs_webmail-1":' /etc/easypanel/traefik/config/main.yaml | grep "url"

# Para dashboard
grep -A 5 '"checkin24hs_dashboard-1":' /etc/easypanel/traefik/config/main.yaml | grep "url"
```

Deberías ver la IP actual del contenedor.

## ⚠️ Nota Importante

Este es un **workaround temporal** para el problema de red de Docker Swarm. La solución permanente requeriría:

1. Configurar correctamente la red de Docker Swarm
2. O usar nombres de servicio en lugar de IPs directas (si Docker Swarm funcionara correctamente)
3. O configurar Traefik para que use el provider de Docker Swarm correctamente

Por ahora, estos scripts te permiten solucionar el problema rápidamente cada vez que reinicies un servicio.

## 📦 Instalación de los Scripts en el Servidor

1. **Desde tu computadora Windows:**
   ```powershell
   # Usar SCP o WinSCP para subir los archivos
   # O copiar y pegar el contenido en el servidor
   ```

2. **En el servidor (SSH):**
   ```bash
   # Crear los archivos
   nano /root/actualizar_webmail_traefik.sh
   # Pegar el contenido y guardar (Ctrl+X, Y, Enter)
   
   nano /root/actualizar_dashboard_traefik.sh
   # Pegar el contenido y guardar
   
   # Hacer ejecutables
   chmod +x /root/actualizar_webmail_traefik.sh
   chmod +x /root/actualizar_dashboard_traefik.sh
   ```

## ✅ Checklist

- [ ] Scripts subidos al servidor
- [ ] Scripts con permisos de ejecución (`chmod +x`)
- [ ] Probar ejecutando uno de los scripts
- [ ] Verificar que Traefik se actualiza correctamente
- [ ] Documentar el proceso para futuras referencias

