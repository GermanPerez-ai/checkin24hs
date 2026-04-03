# 🔧 Solución: Timeout en Dashboard - Paso a Paso

## ✅ Lo que SABEMOS que Funciona:

- ✅ Dashboard está corriendo en puerto **3000**
- ✅ Dashboard está "online" en PM2
- ✅ Servidores Baileys funcionando (3001-3004)
- ✅ Archivo dashboard.html actualizado con URLs de Baileys

---

## 🔍 Diagnóstico del Timeout

El timeout puede ser por:

1. **Problema de DNS** - El dominio no resuelve correctamente
2. **Problema de Proxy** - Traefik/Nginx no está enrutando correctamente
3. **Firewall** - El puerto 3000 no está accesible desde fuera
4. **Configuración incorrecta** - El dominio apunta a otro puerto/servicio

---

## 🚀 Solución Rápida: Acceder Directamente por IP

Mientras solucionamos el dominio, puedes acceder directamente:

```
http://72.61.58.240:3000
```

Esto debería funcionar inmediatamente.

---

## 🔧 Verificar Configuración

### Paso 1: Verificar que el Dashboard Responde

```bash
# Localmente (debe funcionar)
curl -I http://localhost:3000

# Desde fuera (con IP)
curl -I http://72.61.58.240:3000
```

### Paso 2: Verificar DNS

```bash
nslookup dashboard.checkin24hs.com
dig dashboard.checkin24hs.com
```

### Paso 3: Verificar Proxy (Traefik/Nginx)

Si el dashboard está detrás de un proxy, verificar la configuración:

```bash
# Ver servicios de Traefik
docker ps | grep traefik

# Ver configuración
# (depende de cómo esté configurado)
```

---

## ✅ Solución Temporal

Mientras solucionamos el dominio:

1. **Accede directamente**: `http://72.61.58.240:3000`
2. **Ve a**: Flor IA → WhatsApp
3. **Verifica**: Que los iframes cargan los QRs de Baileys
4. **Conecta**: Escanea los QRs

---

## 🎯 Próximos Pasos

1. ✅ Verificar acceso directo por IP
2. ⏳ Solucionar configuración del dominio
3. ⏳ Verificar que los QRs aparecen en el dashboard
4. ⏳ Conectar WhatsApp

---

## 📋 Comandos para Ejecutar

```bash
# Verificar que responde
curl -I http://72.61.58.240:3000

# Ver logs del dashboard
pm2 logs dashboard --lines 20 --nostream

# Verificar puerto
netstat -tulpn | grep 3000
```

---

¿Puedes probar acceder directamente a `http://72.61.58.240:3000` en tu navegador y decirme qué ves?


