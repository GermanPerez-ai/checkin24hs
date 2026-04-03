# Verificar Versión del Dashboard en el Servidor

## Versión Actual en GitHub (Local)
- **DASHBOARD_VERSION**: 2.1.0 (2025-01-27)
- **supabase-client.js**: v=3.1.1

## Comandos para Verificar en el Servidor

### 1. Conectarse al Servidor
```bash
ssh root@srv1152402
```

### 2. Buscar el Contenedor del Dashboard
```bash
docker ps | grep dashboard | grep -v proxy
```

### 3. Verificar la Versión en el Contenedor
```bash
CONTAINER_ID=$(docker ps | grep dashboard | grep -v proxy | awk '{print $1}' | head -1)
echo "Contenedor: $CONTAINER_ID"

# Verificar versión de supabase-client.js
docker exec $CONTAINER_ID grep -oE 'supabase-client\.js\?v=[0-9.]+' /app/dashboard.html | head -1

# Verificar versión del dashboard
docker exec $CONTAINER_ID grep -oE "DASHBOARD_VERSION = '[0-9.]+'" /app/dashboard.html | head -1
```

### 4. Verificar Qué Está Sirviendo el Servidor
```bash
# Verificar versión en HTTP directo
curl -s http://localhost:3000 | grep -oE 'supabase-client\.js\?v=[0-9.]+' | head -1

# Verificar versión a través del dominio
curl -s https://dashboard.checkin24hs.com | grep -oE 'supabase-client\.js\?v=[0-9.]+' | head -1
```

## Posibles Causas si la Versión es Antigua

1. **EasyPanel no ha redesplegado**: Necesitas redesplegar en EasyPanel
2. **Caché del navegador**: El navegador está usando una versión en caché
3. **Contenedor no se ha actualizado**: El contenedor Docker tiene una versión antigua
4. **Docker image no se ha reconstruido**: La imagen Docker tiene código antiguo

## Solución

1. **Redesplegar en EasyPanel**: Ve a EasyPanel y haz redeploy del servicio dashboard
2. **Forzar reconstrucción**: Si el redeploy no funciona, puede necesitar forzar la reconstrucción de la imagen
3. **Limpiar caché del navegador**: Ctrl+Shift+Delete o Ctrl+F5 para forzar recarga
