#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICACIÓN CONFIGURACIÓN CONTENEDOR"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"

# 1. Verificar variables de entorno del servicio
echo "1️⃣ Variables de entorno del servicio:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{printf "%s\n" .}}{{end}}' 2>/dev/null | grep -iE "ROUNDCUBE|IMAP|SMTP|HOST|PORT|SSL" | sort
echo ""

# 2. Verificar contenedor activo
echo "2️⃣ Contenedor activo:"
echo "----------------------------------------"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    echo "   Verifica que el servicio esté corriendo: docker service ps $SERVICE_NAME"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"
echo ""

# 3. Verificar variables de entorno dentro del contenedor
echo "3️⃣ Variables de entorno dentro del contenedor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" env | grep -iE "ROUNDCUBE|IMAP|SMTP|HOST|PORT|SSL" | sort
echo ""

# 4. Verificar archivo de configuración config.docker.inc.php
echo "4️⃣ Archivo config.docker.inc.php (configuración IMAP):"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" cat /var/www/html/config/config.docker.inc.php 2>/dev/null | grep -iE "imap_host|smtp_host|default_host" || echo "No se encontró configuración IMAP"
echo ""

# 5. Verificar archivo config.inc.php completo
echo "5️⃣ Archivo config.inc.php (buscando configuración IMAP):"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" grep -iE "imap_host|smtp_host|default_host|imap_port" /var/www/html/config/config.inc.php 2>/dev/null | head -20 || echo "No se encontró configuración IMAP"
echo ""

# 6. Probar conectividad desde el contenedor
echo "6️⃣ Probando conectividad IMAP desde el contenedor:"
echo "----------------------------------------"

echo "   Probando mail.checkin24hs.com:993 desde el contenedor..."
docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/mail.checkin24hs.com/993" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Puerto 993 accesible desde el contenedor"
else
    echo "   ❌ Puerto 993 NO accesible desde el contenedor"
fi

echo "   Probando localhost:993 desde el contenedor..."
docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/localhost/993" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Puerto 993 accesible en localhost desde el contenedor"
else
    echo "   ❌ Puerto 993 NO accesible en localhost desde el contenedor"
fi

echo ""

# 7. Verificar resolución DNS desde el contenedor
echo "7️⃣ Verificando resolución DNS desde el contenedor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" nslookup mail.checkin24hs.com 2>/dev/null || docker exec "$CONTAINER_ID" getent hosts mail.checkin24hs.com 2>/dev/null || echo "   ⚠️  No se pudo verificar DNS"
echo ""

# 8. Verificar logs recientes del contenedor
echo "8️⃣ Logs recientes del contenedor (últimas 20 líneas con errores IMAP):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 50 2>&1 | grep -iE "imap|error|failed|connection" | tail -20 || echo "No se encontraron errores recientes"
echo ""

# 9. Verificar si hay problemas de red Docker
echo "9️⃣ Verificando red del contenedor:"
echo "----------------------------------------"
docker inspect "$CONTAINER_ID" --format '{{range .NetworkSettings.Networks}}{{.NetworkID}} - {{.IPAddress}}{{end}}' 2>/dev/null
echo ""

# 10. Intentar conexión IMAP directa desde el contenedor
echo "🔟 Intentando conexión IMAP directa (openssl):"
echo "----------------------------------------"
echo "   Probando mail.checkin24hs.com:993..."
docker exec "$CONTAINER_ID" timeout 5 openssl s_client -connect mail.checkin24hs.com:993 -quiet 2>&1 | head -5 || echo "   ❌ No se pudo conectar con openssl"
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""

# Comparar variables de servicio vs contenedor
SERVICE_HOST=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{if eq (index (split . "=") 0) "ROUNDCUBEMAIL_DEFAULT_HOST"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null)
CONTAINER_HOST=$(docker exec "$CONTAINER_ID" env | grep "ROUNDCUBEMAIL_DEFAULT_HOST" | cut -d= -f2)

if [ "$SERVICE_HOST" != "$CONTAINER_HOST" ]; then
    echo "⚠️  ADVERTENCIA: Las variables del servicio y del contenedor no coinciden"
    echo "   Servicio: $SERVICE_HOST"
    echo "   Contenedor: $CONTAINER_HOST"
    echo ""
    echo "   SOLUCIÓN: Reinicia el servicio para aplicar los cambios:"
    echo "   docker service update --force $SERVICE_NAME"
    echo ""
else
    echo "✅ Las variables del servicio y del contenedor coinciden"
    echo ""
fi

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
