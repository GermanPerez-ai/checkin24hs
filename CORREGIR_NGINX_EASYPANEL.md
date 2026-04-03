# 🔧 Corregir nginx para que apunte a EasyPanel correcto

## 🐛 Problema

El puerto 3006 está mostrando el dashboard en lugar de EasyPanel. Esto significa que nginx está redirigiendo al puerto incorrecto.

---

## ✅ Solución

### Paso 1: Verificar dónde está corriendo EasyPanel

**Ejecuta en el servidor:**

```bash
# Ver contenedores de Docker
docker ps | grep -i easypanel

# Ver todos los contenedores y sus puertos
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}"

# Ver qué está escuchando en diferentes puertos
sudo lsof -i :3000
sudo lsof -i :8080
sudo lsof -i :8090
```

**O usa el script:**

```bash
chmod +x /tmp/VERIFICAR_EASYPANEL_PUERTO.sh
/tmp/VERIFICAR_EASYPANEL_PUERTO.sh
```

---

### Paso 2: Identificar el puerto correcto de EasyPanel

EasyPanel puede estar corriendo en:
- Puerto 8080 (puerto por defecto de EasyPanel)
- Puerto 8090
- Otro puerto (verificar en los resultados del Paso 1)

---

### Paso 3: Corregir configuración de nginx

Una vez que identifiques el puerto correcto de EasyPanel, actualiza la configuración:

```bash
# Editar configuración de nginx
sudo nano /etc/nginx/sites-available/easypanel-3006
```

**Cambia la línea `proxy_pass` de:**
```nginx
proxy_pass http://127.0.0.1:3000;
```

**A (por ejemplo, si EasyPanel está en 8080):**
```nginx
proxy_pass http://127.0.0.1:8080;
```

**Guarda y cierra:** `Ctrl+X`, luego `Y`, luego `Enter`

---

### Paso 4: Recargar nginx

```bash
# Verificar configuración
sudo nginx -t

# Recargar nginx
sudo systemctl reload nginx
```

---

## 🔍 Verificar que Funciona

### Probar acceso:

- **EasyPanel:** `http://72.61.58.240:3006` (debe mostrar EasyPanel, no el dashboard)
- **Dashboard:** `http://72.61.58.240:3000` (debe seguir mostrando el dashboard)

---

## 📝 Nota

Si EasyPanel está corriendo en un contenedor Docker, puede que necesites usar la IP del contenedor o el nombre del servicio en lugar de `127.0.0.1`.
