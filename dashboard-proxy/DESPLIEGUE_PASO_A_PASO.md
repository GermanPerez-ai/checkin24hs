# 🚀 Despliegue del Proxy Nginx - Paso a Paso

## 📋 Prerequisitos

- Acceso SSH al servidor
- Acceso a EasyPanel o Docker Swarm
- El servicio `checkin24hs_dashboard` debe estar funcionando

## 🔧 Paso 1: Actualizar Configuración con el Contenedor Actual

En el servidor, ejecuta:

```bash
# Obtener el nombre del contenedor actual
CONTAINER_NAME=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -n 1)
echo "Contenedor actual: $CONTAINER_NAME"
```

Luego actualiza `nginx.conf` con ese nombre.

## 🚀 Paso 2: Desplegar desde EasyPanel

### Opción A: Desplegar como Nuevo Servicio

1. **Sube los archivos a GitHub** (si aún no lo has hecho):
   ```bash
   git add dashboard-proxy/
   git commit -m "Agregar servicio proxy nginx para dashboard"
   git push
   ```

2. **En EasyPanel**:
   - Ve a **Servicios** → **Nuevo Servicio**
   - Configura:
     - **Nombre**: `dashboard-proxy`
     - **Fuente**: GitHub
     - **Repositorio**: `GermanPerez-ai/checkin24hs`
     - **Rama**: `main`
     - **Build Path**: `/dashboard-proxy`
     - **Dockerfile**: `Dockerfile`
     - **Puerto interno**: `80`
     - **Comando**: (dejar vacío)
     - **Variables de entorno**: (ninguna necesaria)

3. **Conectar a la red**:
   - En la configuración del servicio, asegúrate de que esté conectado a la red `easypanel-checkin24hs`

4. **Configurar dominio**:
   - Ve a **Dominios**
   - Edita `dashboard.checkin24hs.com`
   - Cambia el destino a: `http://dashboard-proxy:80/`

### Opción B: Desplegar Manualmente desde el Servidor

```bash
# 1. Clonar o acceder al repositorio
cd /path/to/checkin24hs/dashboard-proxy

# 2. Actualizar configuración con el contenedor actual
chmod +x update-proxy-config.sh
./update-proxy-config.sh

# 3. Construir la imagen
docker build -t dashboard-proxy:latest .

# 4. Crear el servicio en Docker Swarm
docker service create \
  --name dashboard-proxy \
  --network easypanel-checkin24hs \
  --publish published=8080,target=80 \
  dashboard-proxy:latest
```

## ✅ Paso 3: Verificar Funcionamiento

```bash
# Ver logs del proxy
docker service logs dashboard-proxy -f

# Probar conexión local
curl -I http://localhost:8080/

# O si usas EasyPanel
curl -I http://dashboard-proxy:80/
```

## 🔄 Paso 4: Automatizar Actualización (Opcional)

Si el contenedor del dashboard se recrea frecuentemente, puedes automatizar la actualización:

### Crear Script de Actualización Automática

```bash
# Crear script en el servidor
cat > /usr/local/bin/update-dashboard-proxy.sh << 'EOF'
#!/bin/bash
cd /path/to/checkin24hs/dashboard-proxy
./update-proxy-config.sh
docker service update --force dashboard-proxy
EOF

chmod +x /usr/local/bin/update-dashboard-proxy.sh
```

### Agregar a Crontab (ejecutar cada minuto)

```bash
# Editar crontab
crontab -e

# Agregar esta línea (ejecuta cada minuto)
* * * * * /usr/local/bin/update-dashboard-proxy.sh 2>&1 | logger
```

## 🎯 Solución Temporal Rápida

Si necesitas que funcione **AHORA MISMO**, puedes:

1. **Obtener el nombre del contenedor actual**:
   ```bash
   docker ps | grep dashboard | head -1 | awk '{print $NF}'
   ```

2. **Actualizar nginx.conf manualmente**:
   ```bash
   cd dashboard-proxy
   # Edita nginx.conf y reemplaza la línea del server con el nombre obtenido
   nano nginx.conf
   ```

3. **Desplegar**:
   ```bash
   git add dashboard-proxy/nginx.conf
   git commit -m "Actualizar proxy con contenedor actual"
   git push
   # Luego despliega desde EasyPanel
   ```

## ⚠️ Notas Importantes

- El nombre del contenedor cambia cada vez que se recrea el servicio
- Necesitarás actualizar `nginx.conf` cada vez que esto ocurra
- La automatización con cron es recomendada si el contenedor cambia frecuentemente
- El proxy actúa como intermediario y siempre apunta al contenedor activo

---

**¿Necesitas ayuda con algún paso específico?**
