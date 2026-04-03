# 🔐 Cómo Acceder a EasyPanel

## 🎯 Opciones de Acceso

EasyPanel puede estar configurado de diferentes formas. Prueba estas opciones:

### Opción 1: Acceso por IP y Puerto

EasyPanel generalmente corre en el puerto **3000** o **8080**. Prueba estas URLs:

```
http://72.61.58.240:3000
http://72.61.58.240:8080
http://72.61.58.240:3001
```

### Opción 2: Acceso por Subdominio

Si tienes un subdominio configurado:

```
http://panel.checkin24hs.com
http://easypanel.checkin24hs.com
http://admin.checkin24hs.com
```

### Opción 3: Acceso Local (si estás en el servidor)

Si estás conectado por SSH al servidor:

```bash
# Desde el servidor
curl http://localhost:3000
# O
curl http://localhost:8080
```

## 🔍 Diagnóstico

### Paso 1: Verificar si EasyPanel está corriendo

**Si tienes acceso SSH al servidor** (72.61.58.240):

```bash
# Conectarte por SSH
ssh root@72.61.58.240

# Verificar si EasyPanel está corriendo
ps aux | grep easypanel
# O
docker ps | grep easypanel
# O
pm2 list | grep easypanel
```

### Paso 2: Verificar puertos abiertos

```bash
# Ver qué puertos están escuchando
sudo netstat -tulpn | grep LISTEN
# O
sudo ss -tulpn | grep LISTEN
```

Busca puertos como `3000`, `8080`, `3001`, etc.

### Paso 3: Verificar si hay un servicio de EasyPanel

```bash
# Ver servicios de sistema
systemctl status easypanel
# O
docker ps -a | grep easypanel
```

## 🚀 Soluciones

### Solución 1: EasyPanel no está instalado

Si EasyPanel no está instalado, necesitas instalarlo primero:

```bash
# Instalar EasyPanel (si no está instalado)
curl -fsSL https://get.easypanel.io | sh
```

### Solución 2: EasyPanel está detenido

Si EasyPanel está instalado pero no corre:

```bash
# Iniciar EasyPanel
sudo systemctl start easypanel
# O si es Docker
docker start easypanel
# O si es PM2
pm2 start easypanel
```

### Solución 3: Acceder por SSH y usar terminal

Si no puedes acceder por web, puedes usar la terminal del servidor:

```bash
# Conectarte por SSH
ssh root@72.61.58.240

# Una vez conectado, puedes:
# - Ver servicios PM2
pm2 list

# - Ver logs
pm2 logs

# - Reiniciar servicios
pm2 restart all

# - Ver estado de servicios
pm2 status
```

### Solución 4: Verificar firewall

El firewall puede estar bloqueando el acceso:

```bash
# Verificar firewall
sudo ufw status
# O
sudo iptables -L

# Si está bloqueado, abrir el puerto
sudo ufw allow 3000/tcp
sudo ufw allow 8080/tcp
```

## 📋 Información que Necesito

Para ayudarte mejor, necesito saber:

1. **¿Tienes acceso SSH al servidor?** (72.61.58.240)
   - Si sí, podemos trabajar desde la terminal
   - Si no, necesitamos otra forma de acceso

2. **¿Qué error ves cuando intentas acceder?**
   - "No se puede conectar"
   - "Tiempo de espera agotado"
   - "Página no encontrada"
   - Otro error

3. **¿Recuerdas la URL que usabas antes para acceder a EasyPanel?**
   - ¿Era una IP con puerto?
   - ¿Era un subdominio?

4. **¿Tienes las credenciales de acceso?**
   - Usuario
   - Contraseña

## 🔧 Acceso Alternativo: Usar SSH para Gestionar Servicios

Si no puedes acceder a EasyPanel por web, puedes gestionar los servicios directamente por SSH:

### Conectarse por SSH

```bash
ssh root@72.61.58.240
```

### Ver servicios PM2

```bash
pm2 list
```

### Ver logs de un servicio

```bash
pm2 logs whatsapp-1
pm2 logs whatsapp-2
pm2 logs whatsapp-3
pm2 logs whatsapp-4
```

### Reiniciar servicios

```bash
pm2 restart all
# O individualmente
pm2 restart whatsapp-1
```

### Ver estado de servicios

```bash
pm2 status
```

### Editar configuración

```bash
# Editar ecosystem.config.js
nano ~/checkin24hs/whatsapp-server/ecosystem.config.js

# Editar whatsapp-server.js
nano ~/checkin24hs/whatsapp-server/whatsapp-server.js
```

## 🆘 Si Nada Funciona

1. **Contacta al proveedor del servidor** (si es un VPS gestionado)
2. **Verifica el panel de control del proveedor** (Hostinger, DigitalOcean, etc.)
   - Puede tener acceso a EasyPanel desde ahí
3. **Reinstala EasyPanel** si es necesario

## 💡 Nota Importante

Si estás usando **PM2 directamente** (como vimos en los logs anteriores), es posible que:
- EasyPanel no esté instalado
- Estés gestionando los servicios directamente con PM2
- No necesites EasyPanel si ya tienes PM2 funcionando

En ese caso, puedes gestionar todo desde SSH con PM2.

