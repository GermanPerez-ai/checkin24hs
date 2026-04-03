# 🔧 Solución Rápida: Timeout en Dashboard

## 🚨 Problema
El dashboard en `dashboard.checkin24hs.com` muestra `ERR_CONNECTION_TIMED_OUT` - el servidor no responde.

## ✅ Solución Rápida (3 Pasos)

### Paso 1: Conectar al Servidor
```bash
ssh root@72.61.58.240
```

### Paso 2: Verificar y Reiniciar el Dashboard
```bash
cd ~/checkin24hs

# Ver estado actual
pm2 status

# Si está corriendo pero no responde, reiniciar:
pm2 restart dashboard

# Si NO está corriendo, iniciarlo:
pm2 start server.js --name dashboard
pm2 save
```

### Paso 3: Verificar que Funciona
```bash
# Esperar 5 segundos
sleep 5

# Verificar que está escuchando en puerto 3000
netstat -tulpn | grep 3000

# Probar acceso local
curl -I http://localhost:3000
```

---

## 🔍 Si Sigue Sin Funcionar

### Verificar Logs
```bash
pm2 logs dashboard --lines 50 --nostream
```

### Verificar que el Archivo Existe
```bash
cd ~/checkin24hs
ls -la server.js dashboard.html
```

### Verificar Proxy Reverso (Traefik/Nginx)
Si usas un proxy reverso (Traefik o Nginx), verificar que está corriendo:
```bash
# Traefik
docker ps | grep traefik

# Nginx
systemctl status nginx
```

---

## 📋 Checklist Rápido

- [ ] Servidor accesible por SSH
- [ ] Dashboard corriendo en PM2 (`pm2 status` muestra "online")
- [ ] Puerto 3000 abierto (`netstat -tulpn | grep 3000`)
- [ ] Acceso local funciona (`curl http://localhost:3000`)
- [ ] Proxy reverso corriendo (si aplica)
- [ ] Firewall permite puerto 3000 (`ufw status`)

---

## 🎯 Próximo Paso

Una vez que el dashboard responda localmente:
1. Verificar que el dominio `dashboard.checkin24hs.com` apunta al servidor correcto
2. Verificar configuración de Traefik/Nginx para redirigir al puerto 3000
3. Probar acceso desde el navegador

