# 📋 Configurar EasyPanel en Puerto 3006

## 🎯 Objetivo

Configurar EasyPanel para que funcione en el puerto 3006 usando nginx como proxy, dejando el puerto 3000 libre para el dashboard.

---

## ✅ Opción 1: Script Automático (Recomendado)

### Paso 1: Subir script al servidor

**Desde PowerShell local:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp CONFIGURAR_EASYPANEL_PUERTO_3006.sh root@72.61.58.240:/tmp/
```

### Paso 2: Ejecutar en el servidor

**En la terminal SSH del servidor:**

```bash
chmod +x /tmp/CONFIGURAR_EASYPANEL_PUERTO_3006.sh
/tmp/CONFIGURAR_EASYPANEL_PUERTO_3006.sh
```

---

## ✅ Opción 2: Manual (Paso a Paso)

### Paso 1: Instalar nginx (si no está instalado)

```bash
sudo apt update
sudo apt install -y nginx
```

### Paso 2: Crear configuración de nginx

```bash
sudo nano /etc/nginx/sites-available/easypanel-3006
```

**Pega este contenido:**

```nginx
server {
    listen 3006;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts para evitar cortes
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

**Guarda y cierra:** `Ctrl+X`, luego `Y`, luego `Enter`

### Paso 3: Activar el sitio

```bash
sudo ln -s /etc/nginx/sites-available/easypanel-3006 /etc/nginx/sites-enabled/
```

### Paso 4: Verificar configuración

```bash
sudo nginx -t
```

**Debe mostrar:** `nginx: configuration file /etc/nginx/nginx.conf test is successful`

### Paso 5: Recargar nginx

```bash
sudo systemctl reload nginx
```

---

## ✅ Verificar que Funciona

### Verificar que el puerto 3006 esté escuchando:

```bash
netstat -tuln | grep 3006
```

**Debe mostrar algo como:** `tcp 0 0 0.0.0.0:3006 0.0.0.0:* LISTEN`

### Verificar que EasyPanel esté corriendo en 3000:

```bash
curl -I http://127.0.0.1:3000
```

**Debe mostrar:** `HTTP/1.1 200 OK` o similar

### Probar acceso desde navegador:

Abre en tu navegador:
- **EasyPanel:** `http://72.61.58.240:3006`
- **Dashboard:** `http://72.61.58.240:3000` (o `https://dashboard.checkin24hs.com/`)

---

## 🔍 Verificar Estado de Servicios

### Ver si nginx está corriendo:

```bash
sudo systemctl status nginx
```

### Ver si EasyPanel está corriendo:

```bash
docker ps | grep easypanel
```

### Ver logs de nginx si hay problemas:

```bash
sudo tail -f /var/log/nginx/error.log
```

---

## ❌ Si Hay Problemas

### Error: "Address already in use" en puerto 3006

**Verifica qué está usando el puerto:**

```bash
sudo lsof -i :3006
```

**O:**

```bash
sudo netstat -tulpn | grep 3006
```

### Error: nginx no inicia

**Verifica la configuración:**

```bash
sudo nginx -t
```

**Revisa los logs:**

```bash
sudo tail -20 /var/log/nginx/error.log
```

### Error: EasyPanel no responde en 3000

**Verifica que EasyPanel esté corriendo:**

```bash
docker ps | grep easypanel
docker logs <CONTAINER_ID> --tail 20
```

---

## 📝 Resumen

Después de configurar:

- ✅ **EasyPanel:** `http://72.61.58.240:3006`
- ✅ **Dashboard:** `http://72.61.58.240:3000` o `https://dashboard.checkin24hs.com/`

El proxy nginx redirige las peticiones del puerto 3006 al puerto 3000 donde está corriendo EasyPanel internamente.
