# 🔧 Configuración Manual de WhatsApp - Comandos Paso a Paso

## 📋 Instrucciones

Ejecuta estos comandos **uno por uno** en el servidor para configurar WhatsApp manualmente.

---

## 🔍 Paso 1: Verificar Estado Actual

```bash
# Ver servicios en PM2
pm2 list | grep whatsapp

# Ver puertos en uso
netstat -tulpn | grep -E '3001|3002|3003|3004' || ss -tulpn | grep -E '3001|3002|3003|3004'

# Ver logs de whatsapp-1
pm2 logs whatsapp-1 --lines 20 --nostream
```

---

## 🛑 Paso 2: Detener Servicios Existentes

```bash
# Detener todos los servicios de WhatsApp
pm2 stop whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4

# Eliminar de PM2
pm2 delete whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4
```

---

## 🔧 Paso 3: Corregir Configuración del Servidor

```bash
cd ~/checkin24hs/whatsapp-server

# Verificar que el servidor escuche en 0.0.0.0
grep -n "server.listen" whatsapp-server.js

# Si NO dice "server.listen(CONFIG.PORT, '0.0.0.0'", corregirlo:
sed -i "s/server.listen(CONFIG.PORT/server.listen(CONFIG.PORT, '0.0.0.0'/g" whatsapp-server.js

# Verificar el cambio
grep -n "server.listen" whatsapp-server.js
```

---

## 📦 Paso 4: Verificar Dependencias

```bash
cd ~/checkin24hs/whatsapp-server

# Si no existe node_modules, instalar dependencias
if [ ! -d "node_modules" ]; then
    npm install
fi
```

---

## 🚀 Paso 5: Iniciar Servicios Manualmente

```bash
cd ~/checkin24hs/whatsapp-server

# Iniciar cada servicio uno por uno
pm2 start ecosystem.config.js --only whatsapp-1
sleep 3

pm2 start ecosystem.config.js --only whatsapp-2
sleep 3

pm2 start ecosystem.config.js --only whatsapp-3
sleep 3

pm2 start ecosystem.config.js --only whatsapp-4
sleep 3
```

---

## ✅ Paso 6: Verificar Estado

```bash
# Ver estado de PM2
pm2 list

# Ver logs en tiempo real (Ctrl+C para salir)
pm2 logs whatsapp-1

# Verificar puertos
netstat -tulpn | grep -E '3001|3002|3003|3004' || ss -tulpn | grep -E '3001|3002|3003|3004'
```

---

## 🌐 Paso 7: Probar Acceso

```bash
# Obtener IP del servidor
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "IP del servidor: $HOST_IP"

# Probar cada puerto
curl -s "http://$HOST_IP:3001/api/status" | head -5
curl -s "http://$HOST_IP:3002/api/status" | head -5
curl -s "http://$HOST_IP:3003/api/status" | head -5
curl -s "http://$HOST_IP:3004/api/status" | head -5
```

---

## 💾 Paso 8: Guardar Configuración

```bash
# Guardar configuración de PM2 para que persista después de reiniciar
pm2 save
```

---

## 🔍 Paso 9: Ver Logs Detallados

```bash
# Ver logs de un servicio específico
pm2 logs whatsapp-1 --lines 50

# Ver logs de todos los servicios de WhatsApp
pm2 logs --lines 50 | grep -E "whatsapp|WhatsApp|QR|connected"
```

---

## 🆘 Solución de Problemas

### Si un servicio no inicia:

```bash
# Ver logs de error
pm2 logs whatsapp-1 --err --lines 50

# Verificar que el puerto no esté ocupado
lsof -i :3001 || netstat -tulpn | grep 3001

# Reiniciar un servicio específico
pm2 restart whatsapp-1
```

### Si el puerto está ocupado:

```bash
# Ver qué proceso está usando el puerto
lsof -i :3001 || netstat -tulpn | grep 3001

# Matar el proceso (reemplaza PID con el número que aparece)
# kill -9 PID
```

### Si no se muestra el QR:

```bash
# Verificar que el servicio esté corriendo
pm2 list | grep whatsapp-1

# Ver logs en tiempo real
pm2 logs whatsapp-1

# Verificar que el puerto responda
curl http://localhost:3001/api/qr
```

---

## 📱 Configuración en el Dashboard

Una vez que los servicios estén corriendo:

1. **Abre el Dashboard**: `https://dashboard.checkin24hs.com`
2. **Ve a Flor IA** → **WhatsApp**
3. **Configura la URL del servidor**: `http://72.61.58.240`
4. **Abre el modal**: "Conectar Múltiples WhatsApp (hasta 4)"
5. **Conecta cada instancia**: Haz clic en "🔗 Conectar" en cada tarjeta
6. **Escanear QR**: Escanea cada QR con WhatsApp desde tu teléfono

---

## ✅ Verificación Final

```bash
# Verificar que todos los servicios estén corriendo
pm2 list | grep whatsapp

# Verificar que todos los puertos estén activos
for port in 3001 3002 3003 3004; do
    echo -n "Puerto $port: "
    if netstat -tulpn 2>/dev/null | grep -q ":$port " || ss -tulpn 2>/dev/null | grep -q ":$port "; then
        echo "✅ Activo"
    else
        echo "❌ Inactivo"
    fi
done

# Verificar que respondan
HOST_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
for port in 3001 3002 3003 3004; do
    echo -n "Puerto $port responde: "
    if curl -s --max-time 3 "http://$HOST_IP:$port/api/status" > /dev/null 2>&1; then
        echo "✅ Sí"
    else
        echo "❌ No"
    fi
done
```

---

## 📝 Notas Importantes

- **Los servicios deben escuchar en `0.0.0.0`** para ser accesibles desde fuera del servidor
- **Los logs se guardan en**: `~/.pm2/logs/`
- **Para ver logs en tiempo real**: `pm2 logs whatsapp-1` (Ctrl+C para salir)
- **Para reiniciar un servicio**: `pm2 restart whatsapp-1`
- **Para detener un servicio**: `pm2 stop whatsapp-1`
- **Para eliminar un servicio**: `pm2 delete whatsapp-1`

