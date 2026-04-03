# 🌐 Cómo Acceder a Baileys desde el Navegador

## ❌ Problema

Estás intentando acceder a `localhost:3001` desde tu computadora, pero el servidor está en el servidor remoto (`srv1152402`).

## ✅ Solución

### Paso 1: Obtener la IP del Servidor

En el servidor, ejecuta:

```bash
# Ver IP del servidor
hostname -I

# O
ip addr show | grep "inet " | grep -v 127.0.0.1
```

### Paso 2: Acceder desde el Navegador

En tu computadora, abre en el navegador:

```
http://IP_DEL_SERVIDOR:3001
http://IP_DEL_SERVIDOR:3002
http://IP_DEL_SERVIDOR:3003
http://IP_DEL_SERVIDOR:3004
```

**Ejemplo**: Si la IP es `72.61.58.240`:
- `http://72.61.58.240:3001`
- `http://72.61.58.240:3002`
- `http://72.61.58.240:3003`
- `http://72.61.58.240:3004`

---

## 🔒 Si No Funciona: Verificar Firewall

### En el Servidor:

```bash
# Verificar que los puertos están abiertos
netstat -tulpn | grep -E "3001|3002|3003|3004"

# Si usas UFW (firewall)
ufw status
ufw allow 3001/tcp
ufw allow 3002/tcp
ufw allow 3003/tcp
ufw allow 3004/tcp

# Si usas iptables
iptables -L -n | grep 3001
```

---

## 🔧 Verificar que el Servidor Está Escuchando

En el servidor:

```bash
# Verificar que está escuchando en todas las interfaces (0.0.0.0)
netstat -tulpn | grep -E "3001|3002|3003|3004"

# Debería mostrar algo como:
# tcp  0  0  0.0.0.0:3001  0.0.0.0:*  LISTEN  ...
```

Si muestra `127.0.0.1:3001` en lugar de `0.0.0.0:3001`, el servidor solo está escuchando localmente.

---

## ✅ Verificar desde el Servidor Primero

Antes de acceder desde fuera, verifica que funciona localmente en el servidor:

```bash
# En el servidor
curl http://localhost:3001/api/status
curl http://localhost:3001/api/qr

# Ver estado de PM2
pm2 status

# Ver logs
pm2 logs whatsapp-1 --lines 20 --nostream
```

---

## 📋 Checklist

- [ ] Servidor está corriendo (PM2 status muestra "online")
- [ ] Puertos están abiertos en el firewall
- [ ] Servidor escucha en 0.0.0.0 (no solo 127.0.0.1)
- [ ] Tienes la IP correcta del servidor
- [ ] Accedes con `http://IP:3001` (no localhost)

---

## 🆘 Si Sigue Sin Funcionar

1. **Verificar PM2**:
   ```bash
   pm2 status
   pm2 logs whatsapp-1 --lines 50 --nostream
   ```

2. **Verificar que el código está escuchando en 0.0.0.0**:
   El servidor debe estar configurado para escuchar en `0.0.0.0`, no solo en `localhost`.

3. **Verificar firewall del servidor**:
   Los puertos 3001-3004 deben estar abiertos.

4. **Verificar firewall de tu red**:
   Puede que tu red bloquee esos puertos.


