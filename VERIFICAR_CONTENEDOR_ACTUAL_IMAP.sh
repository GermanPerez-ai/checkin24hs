#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICACIÓN CONTENEDOR ACTUAL IMAP"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"

# Obtener contenedor actual
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo"
    exit 1
fi

echo "✅ Contenedor actual: $CONTAINER_ID"
echo ""

# 1. Verificar variables de entorno dentro del contenedor
echo "1️⃣ Variables de entorno dentro del contenedor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" env | grep -iE "ROUNDCUBE" | sort
echo ""

# 2. Verificar configuración actual de Roundcube
echo "2️⃣ Configuración actual de Roundcube:"
echo "----------------------------------------"
echo "   Archivo config.docker.inc.php:"
docker exec "$CONTAINER_ID" cat /var/www/html/config/config.docker.inc.php 2>/dev/null | grep -E "imap_host|smtp_host"
echo ""

# 3. Probar conectividad desde el contenedor
echo "3️⃣ Probando conectividad desde el contenedor:"
echo "----------------------------------------"

echo "   Probando mail.checkin24hs.com:993..."
if docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/mail.checkin24hs.com/993" 2>/dev/null; then
    echo "   ✅ Puerto 993 accesible desde el contenedor"
else
    echo "   ❌ Puerto 993 NO accesible desde el contenedor"
fi

echo "   Probando localhost:993..."
if docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/localhost/993" 2>/dev/null; then
    echo "   ✅ Puerto 993 accesible en localhost desde el contenedor"
else
    echo "   ❌ Puerto 993 NO accesible en localhost desde el contenedor"
fi

echo "   Probando 72.61.58.240:993..."
if docker exec "$CONTAINER_ID" timeout 5 bash -c "echo > /dev/tcp/72.61.58.240/993" 2>/dev/null; then
    echo "   ✅ Puerto 993 accesible en IP directa desde el contenedor"
else
    echo "   ❌ Puerto 993 NO accesible en IP directa desde el contenedor"
fi

echo ""

# 4. Verificar resolución DNS desde el contenedor
echo "4️⃣ Verificando resolución DNS desde el contenedor:"
echo "----------------------------------------"
docker exec "$CONTAINER_ID" getent hosts mail.checkin24hs.com 2>/dev/null || docker exec "$CONTAINER_ID" nslookup mail.checkin24hs.com 2>/dev/null || echo "   ⚠️  No se pudo resolver DNS"
echo ""

# 5. Probar conexión SSL directa
echo "5️⃣ Probando conexión SSL directa:"
echo "----------------------------------------"
echo "   mail.checkin24hs.com:993..."
docker exec "$CONTAINER_ID" timeout 5 openssl s_client -connect mail.checkin24hs.com:993 -quiet 2>&1 | head -3 || echo "   ❌ No se pudo conectar con SSL"
echo ""

# 6. Ver logs del contenedor actual (no del servicio completo)
echo "6️⃣ Logs del contenedor actual (últimas 30 líneas):"
echo "----------------------------------------"
docker logs "$CONTAINER_ID" --tail 30 2>&1 | grep -iE "imap|error|failed|connection" || echo "   No se encontraron errores recientes en este contenedor"
echo ""

# 7. Verificar red del contenedor
echo "7️⃣ Información de red del contenedor:"
echo "----------------------------------------"
docker inspect "$CONTAINER_ID" --format 'Redes: {{range $k, $v := .NetworkSettings.Networks}}{{$k}} (IP: {{$v.IPAddress}}) {{end}}' 2>/dev/null
echo ""

# 8. Verificar si puede hacer ping
echo "8️⃣ Probando conectividad de red básica:"
echo "----------------------------------------"
if docker exec "$CONTAINER_ID" ping -c 2 -W 2 mail.checkin24hs.com >/dev/null 2>&1; then
    echo "   ✅ Ping exitoso a mail.checkin24hs.com"
else
    echo "   ❌ Ping fallido a mail.checkin24hs.com"
    echo "   Probando ping a 8.8.8.8 (Google DNS)..."
    if docker exec "$CONTAINER_ID" ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo "   ✅ Ping a 8.8.8.8 exitoso (el contenedor tiene conectividad de red)"
    else
        echo "   ❌ Ping a 8.8.8.8 fallido (problema de red del contenedor)"
    fi
fi
echo ""

# 9. Verificar logs en tiempo real (último intento de login)
echo "9️⃣ Últimos intentos de login (logs del servicio):"
echo "----------------------------------------"
docker service logs "$SERVICE_NAME" --tail 20 2>&1 | grep -iE "login|imap|error" | tail -10
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""

# Verificar si el contenedor puede conectarse
if docker exec "$CONTAINER_ID" timeout 3 bash -c "echo > /dev/tcp/mail.checkin24hs.com/993" 2>/dev/null; then
    echo "✅ El contenedor PUEDE conectarse a mail.checkin24hs.com:993"
    echo ""
    echo "   Si el error persiste, puede ser:"
    echo "   1. Problema de certificados SSL"
    echo "   2. El servidor IMAP rechaza la conexión"
    echo "   3. Credenciales incorrectas"
    echo ""
    echo "   Prueba iniciar sesión de nuevo y revisa los logs:"
    echo "   docker logs $CONTAINER_ID -f"
else
    echo "❌ El contenedor NO PUEDE conectarse a mail.checkin24hs.com:993"
    echo ""
    echo "   SOLUCIÓN: Usa localhost en lugar de mail.checkin24hs.com"
    echo ""
    echo "   En EasyPanel, cambia:"
    echo "   ROUNDCUBEMAIL_DEFAULT_HOST=localhost"
    echo "   ROUNDCUBEMAIL_SMTP_SERVER=localhost"
    echo ""
    echo "   Luego reinicia: docker service update --force $SERVICE_NAME"
fi

echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
