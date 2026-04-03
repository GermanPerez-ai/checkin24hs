#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 SOLUCIONANDO: WEBMAIL NO RESPONDE"
echo "=========================================="
echo ""

# 1. Verificar logs del webmail
echo "=== 1. LOGS DEL WEBMAIL (últimas 30 líneas) ==="
WEBMAIL_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
if [ -n "$WEBMAIL_CONTAINER" ]; then
    echo "Contenedor: $WEBMAIL_CONTAINER"
    echo ""
    docker logs $WEBMAIL_CONTAINER --tail 30 2>&1
else
    echo "❌ No se encontró contenedor del webmail"
    exit 1
fi
echo ""

# 2. Verificar procesos dentro del contenedor
echo "=== 2. PROCESOS DENTRO DEL CONTENEDOR ==="
docker exec $WEBMAIL_CONTAINER ps aux 2>&1 | head -10
echo ""

# 3. Verificar si Apache está corriendo
echo "=== 3. VERIFICANDO SI APACHE ESTÁ CORRIENDO ==="
APACHE_STATUS=$(docker exec $WEBMAIL_CONTAINER ps aux 2>&1 | grep -i apache | grep -v grep | wc -l)
if [ "$APACHE_STATUS" -gt "0" ]; then
    echo "✅ Apache está corriendo"
else
    echo "❌ Apache NO está corriendo"
    echo "Intentando iniciar Apache..."
    docker exec $WEBMAIL_CONTAINER apache2ctl start 2>&1 || docker exec $WEBMAIL_CONTAINER service apache2 start 2>&1
    sleep 3
    APACHE_STATUS=$(docker exec $WEBMAIL_CONTAINER ps aux 2>&1 | grep -i apache | grep -v grep | wc -l)
    if [ "$APACHE_STATUS" -gt "0" ]; then
        echo "✅ Apache iniciado"
    else
        echo "❌ No se pudo iniciar Apache"
    fi
fi
echo ""

# 4. Verificar puertos que está escuchando el contenedor
echo "=== 4. PUERTOS QUE ESTÁ ESCUCHANDO ==="
docker exec $WEBMAIL_CONTAINER netstat -tlnp 2>&1 | grep LISTEN || docker exec $WEBMAIL_CONTAINER ss -tlnp 2>&1 | grep LISTEN
echo ""

# 5. Verificar configuración de Apache
echo "=== 5. VERIFICANDO CONFIGURACIÓN DE APACHE ==="
docker exec $WEBMAIL_CONTAINER apache2ctl -S 2>&1 | head -20 || docker exec $WEBMAIL_CONTAINER httpd -S 2>&1 | head -20
echo ""

# 6. Probar respuesta HTTP directamente
echo "=== 6. PROBANDO RESPUESTA HTTP ==="
echo "Probando http://localhost:80..."
RESPONSE=$(docker exec $WEBMAIL_CONTAINER wget -q -O- --timeout=5 http://localhost:80 2>&1 | head -5)
if [ -n "$RESPONSE" ]; then
    echo "✅ Webmail responde:"
    echo "$RESPONSE" | head -3
else
    echo "❌ Webmail NO responde"
    echo ""
    echo "Probando http://127.0.0.1:80..."
    docker exec $WEBMAIL_CONTAINER wget -q -O- --timeout=5 http://127.0.0.1:80 2>&1 | head -5 || echo "❌ Tampoco responde en 127.0.0.1"
fi
echo ""

# 7. Reiniciar el servicio si es necesario
echo "=== 7. REINICIANDO SERVICIO WEBMAIL ==="
echo "Reiniciando contenedor del webmail..."
docker service update --force checkin24hs_webmail
echo "⏳ Esperando 30 segundos para que el servicio se reinicie..."
sleep 30

# 8. Verificar nuevamente
echo ""
echo "=== 8. VERIFICANDO DESPUÉS DEL REINICIO ==="
NEW_CONTAINER=$(docker ps --filter "name=webmail" --format "{{.Names}}" | head -1)
if [ -n "$NEW_CONTAINER" ]; then
    echo "Nuevo contenedor: $NEW_CONTAINER"
    echo "Esperando 10 segundos más para que Apache inicie..."
    sleep 10
    RESPONSE=$(docker exec $NEW_CONTAINER wget -q -O- --timeout=5 http://localhost:80 2>&1 | head -5)
    if [ -n "$RESPONSE" ]; then
        echo "✅ Webmail ahora responde correctamente"
    else
        echo "❌ Webmail aún NO responde"
        echo ""
        echo "Revisando logs del nuevo contenedor..."
        docker logs $NEW_CONTAINER --tail 20 2>&1
    fi
else
    echo "⚠️ No se encontró el nuevo contenedor"
fi
echo ""

echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo ""
echo "Si el webmail aún no responde, puede ser:"
echo "  1. Problema de configuración de Roundcube"
echo "  2. Problema con la base de datos"
echo "  3. Problema con permisos de archivos"
echo "  4. El contenedor necesita más tiempo para iniciar"
echo ""
echo "Para ver logs en tiempo real:"
echo "  docker service logs checkin24hs_webmail -f"
echo ""





