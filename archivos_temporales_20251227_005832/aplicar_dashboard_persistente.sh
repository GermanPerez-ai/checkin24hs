#!/bin/bash

echo "=========================================="
echo "Aplicar dashboard.html de forma persistente"
echo "=========================================="
echo ""

# Este script copia el archivo al contenedor cada vez que se ejecuta
# Puedes ejecutarlo después de cada reinicio del servicio

# 1. Verificar que el archivo existe
if [ ! -f "dashboard.html" ]; then
    echo "❌ Error: dashboard.html no existe en el directorio actual"
    exit 1
fi

echo "✅ Archivo dashboard.html encontrado ($(ls -lh dashboard.html | awk '{print $5}'))"
echo ""

# 2. Esperar a que el servicio esté corriendo
echo "2. Esperando a que el servicio esté corriendo..."
for i in {1..30}; do
    CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
    if [ ! -z "$CONTAINER_ID" ]; then
        echo "   ✅ Contenedor encontrado: $CONTAINER_ID"
        break
    fi
    echo "   Intento $i/30..."
    sleep 2
done

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Error: No se encontró contenedor después de 60 segundos"
    exit 1
fi

echo ""

# 3. Copiar el archivo
echo "3. Copiando dashboard.html al contenedor..."
docker cp dashboard.html ${CONTAINER_ID}:/app/dashboard.html

if [ $? -eq 0 ]; then
    echo "✅ Archivo copiado exitosamente"
else
    echo "❌ Error al copiar el archivo"
    exit 1
fi

echo ""

# 4. Verificar
echo "4. Verificando archivo en el contenedor:"
docker exec $CONTAINER_ID ls -lh /app/dashboard.html
REMOTE_SIZE=$(docker exec $CONTAINER_ID wc -c < /app/dashboard.html 2>/dev/null || echo "0")
LOCAL_SIZE=$(wc -c < dashboard.html)

echo "   Tamaño local: $LOCAL_SIZE bytes"
echo "   Tamaño remoto: $REMOTE_SIZE bytes"

if [ "$LOCAL_SIZE" -eq "$REMOTE_SIZE" ]; then
    echo "✅ Tamaños coinciden"
else
    echo "⚠️  Los tamaños no coinciden"
fi

echo ""

# 5. Probar acceso
echo "5. Probando acceso HTTP:"
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
HTML_SIZE=$(curl -s http://localhost:3000 | wc -c)

echo "   Código HTTP: $HTTP_CODE"
echo "   Tamaño HTML servido: $HTML_SIZE bytes"

if [ "$HTML_SIZE" -gt "1000000" ]; then
    echo "✅ El HTML servido tiene el tamaño correcto (>1MB)"
else
    echo "⚠️  El HTML servido es muy pequeño, puede que no se haya aplicado correctamente"
fi

echo ""
echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "Nota: Si reinicias el servicio, necesitarás ejecutar este script de nuevo."
echo "Para una solución permanente, actualiza el archivo en GitHub y reconstruye la imagen."
echo ""

