# 🚀 Actualizar Servidor con Cambios de WhatsApp

## ✅ Cambios Realizados (ya en GitHub)

1. **`dashboard.html`** - Build #38
   - Mejoras en configuración de WhatsApp
   - Detección inteligente de subdominios (api1-4.checkin24hs.com)
   - Normalización de URLs mejorada

2. **`ACTUALIZAR_ARCHIVO_SERVIDOR.sh`** - Script mejorado
   - Detección automática de contenedor
   - Soporte para bind mounts
   - Verificación de build number

3. **`.gitignore`** - Actualizado
   - Archivos de sesión WhatsApp excluidos

## 📋 Pasos para Actualizar el Servidor

### Paso 1: Conectarse al Servidor y Actualizar desde GitHub

```bash
# Conectarse al servidor (SSH)
ssh root@srv1152402

# Ir al directorio del proyecto
cd ~/checkin24hs

# Obtener los últimos cambios de GitHub
git pull origin main
```

### Paso 2: Ejecutar el Script de Actualización

```bash
# Hacer el script ejecutable (si no lo es)
chmod +x ACTUALIZAR_ARCHIVO_SERVIDOR.sh

# Ejecutar el script
./ACTUALIZAR_ARCHIVO_SERVIDOR.sh
```

El script hará:
- ✅ Descargar `dashboard.html` desde GitHub
- ✅ Crear backup del archivo actual
- ✅ Detectar el contenedor del dashboard automáticamente
- ✅ Copiar el archivo al bind mount y al contenedor
- ✅ Verificar el build number
- ✅ Preguntar si quieres reiniciar el contenedor

### Paso 3: Verificar la Actualización

```bash
# Verificar que el build number sea #38
grep "DASHBOARD_BUILD_NUMBER" dashboard.html | head -1

# O verificar en el contenedor
docker exec <nombre-contenedor> grep "DASHBOARD_BUILD_NUMBER" /app/dashboard.html | head -1
```

### Paso 4: Probar la Conexión de WhatsApp

1. **Abrir el Dashboard** en el navegador:
   ```
   https://checkin24hs.com
   ```

2. **Ir a la sección de WhatsApp**:
   - Buscar la sección de configuración de WhatsApp
   - Verificar que aparezcan las 4 instancias (WhatsApp 1, 2, 3, 4)

3. **Configurar la URL del servidor**:
   - En el campo "URL del Servidor WhatsApp", ingresar:
     ```
     https://checkin24hs.com
     ```
     O directamente:
     ```
     https://api1.checkin24hs.com
     ```

4. **Conectar una instancia**:
   - Hacer clic en "Conectar" en una de las instancias
   - Debería aparecer un QR code
   - Escanear el QR con WhatsApp desde tu teléfono

## 🔍 Verificación de Funcionamiento

### Verificar que los Servidores WhatsApp Estén Activos

```bash
# Verificar estado de los contenedores WhatsApp
docker ps | grep whatsapp

# Ver logs de una instancia
docker logs whatsapp-server-1 --tail 50
```

### Verificar Endpoints

```bash
# Probar endpoint de estado
curl https://api1.checkin24hs.com/api/status
curl https://api2.checkin24hs.com/api/status
curl https://api3.checkin24hs.com/api/status
curl https://api4.checkin24hs.com/api/status
```

## 🎯 Resumen Rápido

```bash
# 1. Conectarse al servidor
ssh root@srv1152402

# 2. Actualizar desde GitHub
cd ~/checkin24hs
git pull origin main

# 3. Ejecutar script de actualización
chmod +x ACTUALIZAR_ARCHIVO_SERVIDOR.sh
./ACTUALIZAR_ARCHIVO_SERVIDOR.sh

# 4. Cuando el script pregunte, responder "y" para reiniciar el contenedor
```

## ⚠️ Notas Importantes

1. **Backup automático**: El script crea un backup antes de actualizar
2. **Build number**: Verifica que sea #38 después de la actualización
3. **Reinicio del contenedor**: Recomendado para asegurar que los cambios se apliquen
4. **URLs de WhatsApp**: El dashboard ahora detecta automáticamente si usas `checkin24hs.com` o `api1.checkin24hs.com`

## 🐛 Si Algo No Funciona

1. **Verificar logs del contenedor**:
   ```bash
   docker logs <nombre-contenedor-dashboard> --tail 100
   ```

2. **Verificar que el archivo se copió correctamente**:
   ```bash
   # En el bind mount
   ls -lh /root/checkin24hs/dashboard.html
   
   # En el contenedor
   docker exec <nombre-contenedor> ls -lh /app/dashboard.html
   ```

3. **Restaurar backup si es necesario**:
   ```bash
   # El script crea backups con timestamp
   cp dashboard.html.backup.* dashboard.html
   ```
