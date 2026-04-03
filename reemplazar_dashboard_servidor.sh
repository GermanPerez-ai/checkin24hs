#!/bin/bash

# ============================================
# SCRIPT: Reemplazar dashboard.html en Servidor
# ============================================
# Este script reemplaza dashboard.html en el contenedor
# con el archivo que está en /tmp/dashboard.html

echo "🔧 REEMPLAZANDO dashboard.html EN EL SERVIDOR"
echo "=============================================="
echo ""

# 1. Encontrar contenedor
echo "📋 Paso 1: Buscando contenedor del dashboard..."
CONTAINER_ID=$(docker ps | grep dashboard | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ ERROR: No se encontró el contenedor del dashboard"
    echo ""
    echo "💡 Intentando buscar por otros nombres..."
    CONTAINER_ID=$(docker ps | grep -i "checkin24hs" | awk '{print $1}' | head -1)
    
    if [ -z "$CONTAINER_ID" ]; then
        echo "❌ No se encontró ningún contenedor relacionado"
        echo ""
        echo "📋 Contenedores disponibles:"
        docker ps
        exit 1
    fi
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 2. Verificar que el archivo existe en /tmp
echo "📋 Paso 2: Verificando archivo en /tmp/dashboard.html..."
if [ ! -f "/tmp/dashboard.html" ]; then
    echo "❌ ERROR: No se encontró /tmp/dashboard.html"
    echo ""
    echo "💡 INSTRUCCIONES:"
    echo "   1. Desde tu máquina local (Windows), ejecuta:"
    echo "      scp dashboard.html root@$(hostname -I | awk '{print $1}'):/tmp/dashboard.html"
    echo ""
    echo "   2. O usa WinSCP para subir el archivo a /tmp/dashboard.html"
    echo ""
    echo "   3. Luego ejecuta este script nuevamente"
    exit 1
fi

echo "✅ Archivo encontrado: /tmp/dashboard.html"
FILE_SIZE=$(ls -lh /tmp/dashboard.html | awk '{print $5}')
echo "   Tamaño: $FILE_SIZE"
echo ""

# 3. Hacer backup
echo "📋 Paso 3: Haciendo backup del archivo actual..."
BACKUP_FILE="/app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)"
docker exec $CONTAINER_ID cp /app/dashboard.html "$BACKUP_FILE" 2>/dev/null || \
docker exec $CONTAINER_ID cp dashboard.html "$BACKUP_FILE" 2>/dev/null || \
echo "⚠️  No se pudo hacer backup (continuando de todas formas)"

if [ $? -eq 0 ]; then
    echo "✅ Backup creado: $BACKUP_FILE"
else
    echo "⚠️  Backup no creado (continuando)"
fi
echo ""

# 4. Copiar al contenedor
echo "📋 Paso 4: Copiando archivo al contenedor..."

# Intentar diferentes rutas comunes
if docker cp /tmp/dashboard.html "$CONTAINER_ID:/app/dashboard.html" 2>/dev/null; then
    echo "✅ Archivo copiado a /app/dashboard.html"
elif docker cp /tmp/dashboard.html "$CONTAINER_ID:/dashboard.html" 2>/dev/null; then
    echo "✅ Archivo copiado a /dashboard.html"
elif docker cp /tmp/dashboard.html "$CONTAINER_ID:./dashboard.html" 2>/dev/null; then
    echo "✅ Archivo copiado a ./dashboard.html"
else
    echo "❌ ERROR: No se pudo copiar el archivo al contenedor"
    echo ""
    echo "💡 Intentando método alternativo..."
    
    # Método alternativo: usar docker exec con cat
    docker exec -i $CONTAINER_ID sh -c "cat > /app/dashboard.html" < /tmp/dashboard.html 2>/dev/null || \
    docker exec -i $CONTAINER_ID sh -c "cat > dashboard.html" < /tmp/dashboard.html 2>/dev/null || {
        echo "❌ No se pudo copiar el archivo con ningún método"
        exit 1
    }
    echo "✅ Archivo copiado usando método alternativo"
fi
echo ""

# 5. Verificar que se copió
echo "📋 Paso 5: Verificando que el archivo se copió..."
if docker exec $CONTAINER_ID test -f /app/dashboard.html 2>/dev/null || \
   docker exec $CONTAINER_ID test -f dashboard.html 2>/dev/null; then
    echo "✅ Archivo verificado en el contenedor"
else
    echo "⚠️  No se pudo verificar el archivo (continuando)"
fi
echo ""

# 6. Reiniciar el contenedor
echo "📋 Paso 6: Reiniciando contenedor..."
docker restart $CONTAINER_ID
echo "✅ Contenedor reiniciado"
echo ""

# 7. Esperar a que el servicio se inicie
echo "📋 Paso 7: Esperando a que el servicio se inicie..."
echo "   ⏳ Espera 15 segundos..."
sleep 15
echo ""

# 8. Verificar logs
echo "📋 Paso 8: Verificando logs del contenedor..."
docker logs $CONTAINER_ID --tail 20
echo ""

# 9. Limpiar archivo temporal (opcional)
read -p "¿Eliminar /tmp/dashboard.html? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    rm -f /tmp/dashboard.html
    echo "✅ Archivo temporal eliminado"
else
    echo "ℹ️  Archivo temporal conservado en /tmp/dashboard.html"
fi
echo ""

echo "=============================================="
echo "✅ PROCESO COMPLETADO"
echo "=============================================="
echo ""
echo "📋 Resumen:"
echo "   - Contenedor: $CONTAINER_ID"
echo "   - Archivo reemplazado: dashboard.html"
echo "   - Contenedor reiniciado"
echo ""
echo "🔍 Próximos pasos:"
echo "   1. Abre https://dashboard.checkin24hs.com"
echo "   2. Presiona Ctrl+F5 (limpiar caché)"
echo "   3. Abre la consola (F12)"
echo "   4. Verifica que NO hay errores"
echo "   5. Prueba navegar entre las pestañas"
echo ""

