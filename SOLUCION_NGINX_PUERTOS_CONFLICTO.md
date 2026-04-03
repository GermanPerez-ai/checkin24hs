# 🔧 Solución: nginx no puede iniciar - Puertos en uso

## 🐛 Problema

nginx no puede iniciar porque los puertos 80, 443 y 8080 ya están en uso por otros servicios (probablemente Traefik o Docker).

## ✅ Solución

Deshabilitar las configuraciones de nginx que usan esos puertos y dejar solo la configuración del puerto 3006.

---

## 📋 Opción 1: Script Automático (Recomendado)

### Paso 1: Subir script al servidor

**Desde PowerShell local:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp CONFIGURAR_NGINX_SOLO_3006.sh root@72.61.58.240:/tmp/
```

### Paso 2: Ejecutar en el servidor

**En la terminal SSH del servidor:**

```bash
chmod +x /tmp/CONFIGURAR_NGINX_SOLO_3006.sh
/tmp/CONFIGURAR_NGINX_SOLO_3006.sh
```

---

## 📋 Opción 2: Manual (Paso a Paso)

### Paso 1: Ver qué está usando los puertos

```bash
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :8080
```

### Paso 2: Deshabilitar configuraciones conflictivas de nginx

```bash
cd /etc/nginx/sites-enabled

# Ver qué configuraciones están activas
ls -la

# Deshabilitar las que usan puertos 80, 443, 8080
# (Mantener solo easypanel-3006)
sudo rm default 2>/dev/null
sudo rm *80* 2>/dev/null
sudo rm *443* 2>/dev/null
sudo rm *8080* 2>/dev/null
```

### Paso 3: Verificar que solo quede easypanel-3006

```bash
ls -la /etc/nginx/sites-enabled/
```

**Debe mostrar solo:** `easypanel-3006`

### Paso 4: Verificar configuración

```bash
sudo nginx -t
```

### Paso 5: Iniciar nginx

```bash
sudo systemctl start nginx
sudo systemctl status nginx
```

### Paso 6: Verificar puerto 3006

```bash
netstat -tuln | grep 3006
```

---

## 🔍 Verificar que Funciona

### Verificar que nginx esté corriendo:

```bash
sudo systemctl status nginx
```

**Debe mostrar:** `Active: active (running)`

### Verificar que el puerto 3006 esté escuchando:

```bash
netstat -tuln | grep 3006
```

**Debe mostrar:** `tcp 0 0 0.0.0.0:3006 0.0.0.0:* LISTEN`

### Probar acceso:

Abre en tu navegador:
- **EasyPanel:** `http://72.61.58.240:3006`

---

## ❌ Si Aún Hay Problemas

### Ver logs de nginx:

```bash
sudo journalctl -u nginx --no-pager -n 20
```

### Verificar configuración de nginx:

```bash
sudo nginx -t
```

### Ver qué configuraciones están activas:

```bash
ls -la /etc/nginx/sites-enabled/
cat /etc/nginx/sites-enabled/easypanel-3006
```

---

## 📝 Nota Importante

Los puertos 80, 443 y 8080 seguirán siendo usados por otros servicios (Traefik, Docker, etc.). Esto es normal y no afecta la funcionalidad de EasyPanel en el puerto 3006.
