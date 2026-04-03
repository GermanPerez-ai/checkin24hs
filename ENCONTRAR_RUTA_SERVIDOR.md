# 🔍 Cómo Encontrar la Ruta del Proyecto en el Servidor

## 📋 Comandos para Ejecutar en el Servidor

Copia y pega estos comandos en tu servidor (vía SSH) para encontrar dónde está el proyecto:

### **Método 1: Buscar por archivo `server.js`**

```bash
find / -name "server.js" -type f 2>/dev/null | grep -v node_modules
```

Este comando busca todos los archivos `server.js` en el servidor (excluyendo node_modules).

### **Método 2: Buscar por archivo `dashboard.html`**

```bash
find / -name "dashboard.html" -type f 2>/dev/null | head -5
```

### **Método 3: Buscar por carpeta `Checkin24hs`**

```bash
find / -type d -name "Checkin24hs" 2>/dev/null
```

### **Método 4: Verificar rutas comunes**

```bash
# Verificar rutas comunes donde suelen estar los proyectos
ls -la /var/www/ 2>/dev/null
ls -la /home/*/ 2>/dev/null | grep -i checkin
ls -la /opt/ 2>/dev/null | grep -i checkin
ls -la /root/ 2>/dev/null | grep -i checkin
```

### **Método 5: Buscar procesos Node.js en ejecución**

Si el servidor está corriendo, puedes encontrar la ruta desde el proceso:

```bash
# Ver procesos de Node.js
ps aux | grep node | grep -v grep

# Ver procesos de PM2 (si usas PM2)
pm2 list
pm2 info server.js  # Reemplaza con el nombre de tu proceso
```

### **Método 6: Buscar por archivo `.git`**

Si el proyecto está versionado con Git:

```bash
find / -name ".git" -type d 2>/dev/null | grep -v ".git/" | head -10
```

---

## 🎯 Una vez que encuentres la ruta

Ejecuta estos comandos en esa ruta:

```bash
cd /ruta/encontrada/aqui

# Verificar que es el proyecto correcto
ls -la server.js dashboard.html package.json

# Si están esos archivos, ¡es el lugar correcto!
```

---

## 💡 Tips

1. **Si usas Docker/EasyPanel:** El proyecto puede estar en:
   - `/var/lib/docker/volumes/`
   - O dentro de un contenedor

2. **Si usas PM2:** Ejecuta `pm2 info all` para ver las rutas de los procesos

3. **Si usas systemd:** Verifica con:
   ```bash
   systemctl status checkin24hs
   # O el nombre de tu servicio
   ```

---

## 📝 Ejemplo de salida esperada

Cuando ejecutes `find / -name "server.js"`, deberías ver algo como:

```
/var/www/checkin24hs/server.js
# O
/home/usuario/checkin24hs/server.js
# O
/opt/checkin24hs/server.js
```

**Esa es la ruta que necesitas.** 📍
