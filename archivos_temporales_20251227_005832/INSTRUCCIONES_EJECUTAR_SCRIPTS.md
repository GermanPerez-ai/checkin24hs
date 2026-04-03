# 📋 Instrucciones para Ejecutar los Scripts

## 📦 Archivos Creados

Se han creado 4 scripts para resolver los problemas:

1. **`arreglar_webmail.sh`** - Diagnostica y arregla webmail.checkin24hs.com
2. **`arreglar_easypanel.sh`** - Diagnostica y arregla la redirección de EasyPanel
3. **`actualizar_dashboard_github.sh`** - Actualiza el dashboard desde GitHub
4. **`ejecutar_todo.sh`** - Ejecuta todos los scripts en orden

---

## 🚀 Opción 1: Ejecutar Todo Automáticamente

### Paso 1: Copiar scripts al servidor

```bash
# Desde tu máquina local (Windows)
scp arreglar_webmail.sh root@72.61.58.240:/tmp/
scp arreglar_easypanel.sh root@72.61.58.240:/tmp/
scp actualizar_dashboard_github.sh root@72.61.58.240:/tmp/
scp ejecutar_todo.sh root@72.61.58.240:/tmp/
```

### Paso 2: Conectar al servidor y ejecutar

```bash
ssh root@72.61.58.240

# Dar permisos de ejecución
chmod +x /tmp/arreglar_webmail.sh
chmod +x /tmp/arreglar_easypanel.sh
chmod +x /tmp/actualizar_dashboard_github.sh
chmod +x /tmp/ejecutar_todo.sh

# Ejecutar todo
bash /tmp/ejecutar_todo.sh
```

---

## 🔧 Opción 2: Ejecutar Scripts Individualmente

### 1. Arreglar Webmail

```bash
ssh root@72.61.58.240
chmod +x /tmp/arreglar_webmail.sh
bash /tmp/arreglar_webmail.sh
```

**El script mostrará:**
- Estado de los servicios webmail
- Logs del servicio
- Configuración de Traefik
- Soluciones sugeridas

**Después del diagnóstico, si es necesario:**
```bash
# Reiniciar servicio webmail
docker restart <nombre_contenedor>

# O si es un servicio Swarm
docker service update --force <nombre_servicio>

# Reiniciar Traefik
docker service update --force traefik
```

---

### 2. Arreglar EasyPanel

```bash
ssh root@72.61.58.240
chmod +x /tmp/arreglar_easypanel.sh
bash /tmp/arreglar_easypanel.sh
```

**El script mostrará:**
- Puerto donde corre EasyPanel
- Configuración actual de Traefik
- Qué está en el puerto 3000 (dashboard)
- Instrucciones para corregir

**Después del diagnóstico, corregir manualmente:**

```bash
# 1. Hacer backup
cp /etc/easypanel/traefik/config/main.yaml /etc/easypanel/traefik/config/main.yaml.backup.$(date +%Y%m%d_%H%M%S)

# 2. Editar configuración
nano /etc/easypanel/traefik/config/main.yaml

# 3. Buscar la sección de EasyPanel que apunta a puerto 3000
# Cambiar de: url: "http://72.61.58.240:3000"
# A: url: "http://72.61.58.240:8080" (o el puerto correcto de EasyPanel)

# 4. Guardar (Ctrl+O, Enter, Ctrl+X)

# 5. Reiniciar Traefik
docker service update --force traefik
```

---

### 3. Actualizar Dashboard desde GitHub

```bash
ssh root@72.61.58.240
chmod +x /tmp/actualizar_dashboard_github.sh
bash /tmp/actualizar_dashboard_github.sh
```

**El script:**
- ✅ Hace backup de dashboard.html
- ✅ Verifica cambios en GitHub
- ✅ Descarga cambios con `git pull`
- ✅ Reinicia el servicio PM2
- ✅ Verifica que todo funciona

**Si hay conflictos:**
```bash
cd ~/checkin24hs
git status
# Resolver conflictos manualmente
git add dashboard.html
git commit -m "Resolve conflicts"
pm2 restart dashboard
```

---

## 📝 Orden Recomendado de Ejecución

1. **Primero: Arreglar Webmail**
   ```bash
   bash /tmp/arreglar_webmail.sh
   ```

2. **Segundo: Arreglar EasyPanel**
   ```bash
   bash /tmp/arreglar_easypanel.sh
   ```
   (Luego editar manualmente la configuración de Traefik)

3. **Tercero: Actualizar Dashboard**
   ```bash
   bash /tmp/actualizar_dashboard_github.sh
   ```

---

## ✅ Verificación Final

Después de ejecutar todos los scripts:

1. **Webmail:**
   - Abrir: https://webmail.checkin24hs.com
   - Debería cargar sin "Bad Gateway"

2. **EasyPanel:**
   - Ir a: https://hpanel.hostinger.com/vps/1152402/overview
   - Clic en "Gestionar panel"
   - Debería llevarte a EasyPanel, NO al dashboard

3. **Dashboard:**
   - Abrir: https://dashboard.checkin24hs.com
   - Debería mostrar el panel de administración
   - Los códigos QR de WhatsApp deberían funcionar

---

## 🆘 Si Algo Sale Mal

### Restaurar backup del dashboard:
```bash
cd ~/checkin24hs
ls -la dashboard.html.backup.*
# Restaurar el más reciente
cp dashboard.html.backup.YYYYMMDD_HHMMSS dashboard.html
pm2 restart dashboard
```

### Restaurar configuración de Traefik:
```bash
cp /etc/easypanel/traefik/config/main.yaml.backup.* /etc/easypanel/traefik/config/main.yaml
docker service update --force traefik
```

### Ver logs de errores:
```bash
# Dashboard
pm2 logs dashboard --err --lines 50

# Docker servicios
docker logs <nombre_contenedor> --tail 50

# Traefik
docker logs traefik --tail 50
```

