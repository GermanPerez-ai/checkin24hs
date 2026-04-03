#!/bin/bash
# Script para iniciar EasyPanel y verificar su configuración

echo "=========================================="
echo "INICIAR EASYPANEL"
echo "=========================================="
echo ""

# Contenedor de EasyPanel encontrado
EASYPANEL_CONTAINER="1beb93cc85e7"

echo "1. Verificando contenedor de EasyPanel..."
docker ps -a | grep "$EASYPANEL_CONTAINER"
echo ""

# Ver configuración del contenedor (puertos)
echo "2. Verificando configuración de puertos del contenedor..."
docker inspect $EASYPANEL_CONTAINER | grep -A 10 "Ports" | head -15
echo ""

# Ver logs recientes para entender por qué se detuvo
echo "3. Últimos logs del contenedor (para ver errores):"
docker logs $EASYPANEL_CONTAINER --tail 20
echo ""

# Iniciar el contenedor
echo "4. Iniciando contenedor de EasyPanel..."
docker start $EASYPANEL_CONTAINER

if [ $? -eq 0 ]; then
    echo "✅ Contenedor iniciado"
else
    echo "❌ Error al iniciar el contenedor"
    exit 1
fi

# Esperar a que inicie
echo ""
echo "5. Esperando 10 segundos para que EasyPanel inicie..."
sleep 10
echo ""

# Verificar que esté corriendo
echo "6. Verificando estado del contenedor..."
docker ps | grep easypanel
echo ""

# Ver puertos mapeados
echo "7. Puertos mapeados del contenedor:"
docker port $EASYPANEL_CONTAINER 2>/dev/null || echo "No hay puertos mapeados explícitamente"
echo ""

# Ver qué puerto está usando internamente
echo "8. Verificando qué puerto está usando EasyPanel internamente..."
docker logs $EASYPANEL_CONTAINER --tail 5 | grep -i "port\|listen\|3000\|8080" || echo "Revisa los logs completos"
echo ""

# Verificar si está escuchando en algún puerto
echo "9. Verificando puertos en uso después de iniciar:"
for port in 3000 8080 8090; do
    result=$(sudo lsof -i :$port 2>/dev/null | grep -v "COMMAND" || netstat -tulpn | grep :$port)
    if [ ! -z "$result" ]; then
        echo "Puerto $port:"
        echo "$result" | head -3
        echo ""
    fi
done

echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Si EasyPanel está corriendo, verifica en qué puerto está escuchando"
echo "y actualiza la configuración de nginx en consecuencia."
echo ""
