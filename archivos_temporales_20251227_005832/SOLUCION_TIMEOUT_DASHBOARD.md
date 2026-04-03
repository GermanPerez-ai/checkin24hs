# 🔧 Solución: Timeout en Dashboard

## 🔍 Posibles Causas

1. **Dashboard aún iniciando** - Puede tardar unos segundos después del reinicio
2. **Puerto incorrecto** - El dashboard puede estar en otro puerto
3. **Problema de red/firewall** - El dominio puede no estar resolviendo correctamente
4. **Servicio detenido** - Aunque PM2 muestra "online", puede haber un problema

---

## ✅ Verificaciones

### 1. Verificar que el Dashboard está Escuchando

```bash
# Ver en qué puerto está el dashboard
pm2 info dashboard

# Ver puertos abiertos
netstat -tulpn | grep node
```

### 2. Ver Logs del Dashboard

```bash
# Ver logs recientes
pm2 logs dashboard --lines 50 --nostream

# Ver si hay errores
pm2 logs dashboard --err --lines 50 --nostream
```

### 3. Verificar Acceso Local

```bash
# Si el dashboard está en puerto 3000 (por ejemplo)
curl http://localhost:3000

# O el puerto que muestre pm2 info dashboard
```

### 4. Verificar Dominio

```bash
# Verificar resolución DNS
nslookup dashboard.checkin24hs.com

# O
dig dashboard.checkin24hs.com
```

---

## 🔧 Soluciones

### Si el Dashboard No Responde

1. **Reiniciar completamente**:
   ```bash
   pm2 stop dashboard
   pm2 delete dashboard
   # Luego iniciarlo de nuevo según tu configuración
   ```

2. **Verificar configuración de red**:
   - Verificar que Traefik/Nginx está configurado correctamente
   - Verificar que el dominio apunta al servidor correcto

3. **Verificar firewall**:
   ```bash
   ufw status
   # Asegurarse de que los puertos necesarios están abiertos
   ```

---

## 📋 Checklist

- [ ] Dashboard está corriendo (PM2 status muestra "online")
- [ ] Dashboard está escuchando en un puerto (netstat lo muestra)
- [ ] Logs no muestran errores críticos
- [ ] Dominio resuelve correctamente
- [ ] Firewall permite el tráfico
- [ ] Servidores Baileys responden (3001-3004)

---

## 🎯 Próximo Paso

Una vez que el dashboard responda:
1. Ir a Flor IA → WhatsApp
2. Verificar que los iframes cargan los QRs de Baileys
3. Conectar WhatsApp escaneando los QRs


