# 🚀 Actualizar Dashboard Directamente desde el Servidor

## 📋 Opción 1: Usar el Script Automático

### Paso 1: Conectarse al Servidor

```bash
ssh root@72.61.58.240
```

### Paso 2: Ejecutar el Script

```bash
# Descargar el script
curl -o /tmp/actualizar_dashboard_desde_servidor.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/actualizar_dashboard_desde_servidor.sh

# Dar permisos de ejecución
chmod +x /tmp/actualizar_dashboard_desde_servidor.sh

# Ejecutar el script
/tmp/actualizar_dashboard_desde_servidor.sh
```

El script:
1. ✅ Descarga el código actualizado de GitHub
2. ✅ Encuentra el contenedor del dashboard
3. ✅ Copia el archivo `dashboard.html` actualizado
4. ✅ Verifica que el código esté actualizado
5. ✅ Opcionalmente reinicia el contenedor

## 📋 Opción 2: Actualización Manual

### Paso 1: Conectarse al Servidor

```bash
ssh root@72.61.58.240
```

### Paso 2: Encontrar el Contenedor

```bash
docker ps | grep dashboard
```

### Paso 3: Encontrar la Ruta del Archivo

```bash
CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
docker exec $CONTAINER_ID find / -name "dashboard.html" -type f 2>/dev/null | head -1
```

### Paso 4: Descargar y Copiar el Archivo

```bash
# Crear directorio temporal
mkdir -p /tmp/dashboard_update
cd /tmp/dashboard_update

# Clonar o actualizar el repositorio
if [ -d "Checkin24hs" ]; then
    cd Checkin24hs
    git pull origin main
else
    git clone https://github.com/GermanPerez-ai/checkin24hs.git Checkin24hs
    cd Checkin24hs
fi

# Copiar al contenedor (reemplaza CONTAINER_ID y RUTA con los valores encontrados)
docker cp deploy/dashboard.html $CONTAINER_ID:/app/dashboard.html

# O si está en otra ruta:
# docker cp deploy/dashboard.html $CONTAINER_ID:/ruta/completa/dashboard.html
```

### Paso 5: Verificar

```bash
# Verificar que el código esté actualizado
docker exec $CONTAINER_ID grep -q "checkWhatsAppConnection BLOQUEADO" /app/dashboard.html && echo "✅ Código actualizado" || echo "❌ Código NO actualizado"
```

### Paso 6: Reiniciar (Opcional)

```bash
docker restart $CONTAINER_ID
```

## 🔍 Verificar que Funcionó

Después de actualizar, abre el dashboard en el navegador y ejecuta en la consola (F12):

```javascript
// Verificar que checkWhatsAppConnection esté bloqueada
const funcCode = window.checkWhatsAppConnection.toString();
console.log('Función:', funcCode);

// Debería contener "BLOQUEADO"
// NO debería contener "fetch" ni "http://72.61.58.240"
if (funcCode.includes('fetch') || funcCode.includes('http://72.61.58.240')) {
    console.error('❌ CÓDIGO ANTIGUO - El servidor no está actualizado');
} else {
    console.log('✅ CÓDIGO ACTUALIZADO - Función bloqueada correctamente');
}

// Verificar que la sincronización no se ejecute múltiples veces
// Deberías ver solo UN mensaje "🔄 Sincronización automática..." cada 30 segundos
```

## ⚠️ Solución de Problemas

### Si el script no encuentra el contenedor:

```bash
# Listar todos los contenedores
docker ps -a | grep dashboard

# Verificar el nombre exacto del servicio
docker service ls | grep dashboard
```

### Si el archivo no se encuentra en el contenedor:

```bash
# Listar archivos en /app
docker exec $CONTAINER_ID ls -la /app

# Buscar en otras rutas comunes
docker exec $CONTAINER_ID find / -name "*.html" -type f 2>/dev/null | grep -i dashboard
```

### Si el código no se actualiza:

1. **Verifica que el archivo se copió correctamente**:
   ```bash
   docker exec $CONTAINER_ID cat /app/dashboard.html | grep -A 5 "checkWhatsAppConnection BLOQUEADO"
   ```

2. **Reinicia el contenedor**:
   ```bash
   docker restart $CONTAINER_ID
   ```

3. **Limpia el caché del navegador** (Ctrl+F5)

## 📝 Notas

- El script automático es más seguro y verifica todo automáticamente
- La actualización manual te da más control pero requiere más pasos
- Siempre verifica después de actualizar para asegurarte de que funcionó
- Si el problema persiste, puede ser caché del navegador (usa Ctrl+F5)

