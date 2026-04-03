#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICACIÓN ERROR CONEXIÓN IMAP"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"
IMAP_HOST="mail.checkin24hs.com"
IMAP_IP="72.61.58.240"

# 1. Verificar variables de entorno del servicio
echo "1️⃣ Variables de entorno del servicio webmail:"
echo "----------------------------------------"
ENV_VARS=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{printf "%s\n" .}}{{end}}' 2>/dev/null)

if [ -z "$ENV_VARS" ]; then
    echo "❌ No se pudo obtener las variables de entorno"
    echo "   Verifica que el servicio '$SERVICE_NAME' exista"
else
    echo "Variables relacionadas con IMAP/SMTP:"
    echo "$ENV_VARS" | grep -iE "ROUNDCUBE|IMAP|SMTP|MAIL|HOST|PORT|SSL" | sort
    
    # Verificar configuración específica
    echo ""
    echo "📋 Configuración actual:"
    DEFAULT_HOST=$(echo "$ENV_VARS" | grep "ROUNDCUBEMAIL_DEFAULT_HOST" | cut -d= -f2)
    DEFAULT_PORT=$(echo "$ENV_VARS" | grep "ROUNDCUBEMAIL_DEFAULT_PORT" | cut -d= -f2)
    DEFAULT_SSL=$(echo "$ENV_VARS" | grep "ROUNDCUBEMAIL_DEFAULT_HOST_SSL" | cut -d= -f2)
    SMTP_SERVER=$(echo "$ENV_VARS" | grep "ROUNDCUBEMAIL_SMTP_SERVER" | cut -d= -f2)
    
    if [ -n "$DEFAULT_HOST" ]; then
        echo "   ROUNDCUBEMAIL_DEFAULT_HOST: $DEFAULT_HOST"
    else
        echo "   ❌ ROUNDCUBEMAIL_DEFAULT_HOST: NO CONFIGURADO"
    fi
    
    if [ -n "$DEFAULT_PORT" ]; then
        echo "   ROUNDCUBEMAIL_DEFAULT_PORT: $DEFAULT_PORT"
    else
        echo "   ❌ ROUNDCUBEMAIL_DEFAULT_PORT: NO CONFIGURADO"
    fi
    
    if [ -n "$DEFAULT_SSL" ]; then
        echo "   ROUNDCUBEMAIL_DEFAULT_HOST_SSL: $DEFAULT_SSL"
    else
        echo "   ⚠️  ROUNDCUBEMAIL_DEFAULT_HOST_SSL: NO CONFIGURADO (por defecto: false)"
    fi
    
    if [ -n "$SMTP_SERVER" ]; then
        echo "   ROUNDCUBEMAIL_SMTP_SERVER: $SMTP_SERVER"
    else
        echo "   ⚠️  ROUNDCUBEMAIL_SMTP_SERVER: NO CONFIGURADO"
    fi
    
    # Verificar si está usando IP en lugar de dominio
    if [ "$DEFAULT_HOST" = "$IMAP_IP" ]; then
        echo ""
        echo "   ⚠️  ADVERTENCIA: Está usando IP directa ($IMAP_IP) en lugar del dominio"
        echo "      Debería usar: mail.checkin24hs.com"
    fi
fi
echo ""

# 2. Verificar contenedor y configuración interna
echo "2️⃣ Configuración dentro del contenedor:"
echo "----------------------------------------"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró contenedor activo de webmail"
    echo "   Verifica que el servicio esté corriendo: docker service ps $SERVICE_NAME"
else
    echo "✅ Contenedor encontrado: $CONTAINER_ID"
    echo ""
    
    # Verificar archivo de configuración principal
    echo "   Archivo config.inc.php (buscando configuración IMAP):"
    docker exec "$CONTAINER_ID" grep -iE "default_host|imap_host|imap_port|imap_conn_options" /var/www/html/config/config.inc.php 2>/dev/null | head -10 || echo "   No se pudo leer config.inc.php"
    
    echo ""
    echo "   Archivo config.docker.inc.php (últimas 30 líneas):"
    docker exec "$CONTAINER_ID" tail -30 /var/www/html/config/config.docker.inc.php 2>/dev/null | grep -v "^$" || echo "   No se pudo leer config.docker.inc.php"
fi
echo ""

# 3. Verificar conectividad con el servidor IMAP
echo "3️⃣ Verificando conectividad con el servidor IMAP:"
echo "----------------------------------------"

# Probar con el dominio
echo "   Probando mail.checkin24hs.com:993 (IMAP SSL)..."
if timeout 5 bash -c "echo > /dev/tcp/$IMAP_HOST/993" 2>/dev/null; then
    echo "   ✅ Puerto 993 accesible en $IMAP_HOST"
else
    echo "   ❌ Puerto 993 NO accesible en $IMAP_HOST"
fi

echo "   Probando mail.checkin24hs.com:143 (IMAP sin SSL)..."
if timeout 5 bash -c "echo > /dev/tcp/$IMAP_HOST/143" 2>/dev/null; then
    echo "   ✅ Puerto 143 accesible en $IMAP_HOST"
else
    echo "   ❌ Puerto 143 NO accesible en $IMAP_HOST"
fi

# Probar con la IP (por si el dominio no resuelve)
echo ""
echo "   Probando $IMAP_IP:993 (IMAP SSL)..."
if timeout 5 bash -c "echo > /dev/tcp/$IMAP_IP/993" 2>/dev/null; then
    echo "   ✅ Puerto 993 accesible en $IMAP_IP"
else
    echo "   ❌ Puerto 993 NO accesible en $IMAP_IP"
fi

echo "   Probando $IMAP_IP:143 (IMAP sin SSL)..."
if timeout 5 bash -c "echo > /dev/tcp/$IMAP_IP/143" 2>/dev/null; then
    echo "   ✅ Puerto 143 accesible en $IMAP_IP"
else
    echo "   ❌ Puerto 143 NO accesible en $IMAP_IP"
fi

# Verificar resolución DNS
echo ""
echo "   Verificando resolución DNS:"
DNS_RESULT=$(dig +short "$IMAP_HOST" 2>/dev/null | head -1)
if [ -n "$DNS_RESULT" ]; then
    echo "   ✅ $IMAP_HOST resuelve a: $DNS_RESULT"
else
    echo "   ❌ No se pudo resolver $IMAP_HOST"
fi
echo ""

# 4. Verificar si hay un servidor de correo corriendo
echo "4️⃣ Verificando servicios de correo en el servidor:"
echo "----------------------------------------"
echo "   Servicios Docker relacionados con correo:"
DOCKER_MAIL=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -iE "mail|postfix|dovecot|imap|smtp")
if [ -n "$DOCKER_MAIL" ]; then
    echo "$DOCKER_MAIL"
else
    echo "   ⚠️  No se encontraron servicios de correo en Docker"
fi

echo ""
echo "   Servicios del sistema relacionados con correo:"
SYSTEM_MAIL=$(systemctl list-units --type=service --state=running 2>/dev/null | grep -iE "postfix|dovecot|imap|smtp")
if [ -n "$SYSTEM_MAIL" ]; then
    echo "$SYSTEM_MAIL"
else
    echo "   ⚠️  No se encontraron servicios de correo del sistema"
fi
echo ""

# 5. Verificar logs del webmail para errores IMAP
echo "5️⃣ Logs del webmail (buscando errores IMAP):"
echo "----------------------------------------"
echo "   Últimas 50 líneas de logs:"
docker service logs "$SERVICE_NAME" --tail 50 2>&1 | grep -iE "imap|error|failed|connection|authentication" | tail -20 || echo "   No se encontraron errores IMAP en los logs recientes"
echo ""

# 6. Verificar puertos abiertos en el servidor
echo "6️⃣ Verificando puertos abiertos en el servidor:"
echo "----------------------------------------"
echo "   Puertos IMAP/SMTP escuchando:"
NETSTAT_MAIL=$(netstat -tuln 2>/dev/null | grep -iE ":993|:143|:587|:465|:25" || ss -tuln 2>/dev/null | grep -iE ":993|:143|:587|:465|:25")
if [ -n "$NETSTAT_MAIL" ]; then
    echo "$NETSTAT_MAIL"
else
    echo "   ⚠️  No se encontraron puertos de correo escuchando"
fi
echo ""

# 7. Resumen y recomendaciones
echo "=========================================="
echo "💡 DIAGNÓSTICO Y RECOMENDACIONES"
echo "=========================================="
echo ""

# Verificar si el problema es de configuración
if [ "$DEFAULT_HOST" = "$IMAP_IP" ]; then
    echo "❌ PROBLEMA IDENTIFICADO:"
    echo "   El webmail está configurado para usar la IP directa ($IMAP_IP)"
    echo "   en lugar del dominio (mail.checkin24hs.com)"
    echo ""
    echo "   SOLUCIÓN:"
    echo "   1. Ve a EasyPanel → Servicio 'webmail' → Variables de Entorno"
    echo "   2. Cambia ROUNDCUBEMAIL_DEFAULT_HOST de $IMAP_IP a mail.checkin24hs.com"
    echo "   3. Asegúrate de tener configurado:"
    echo "      - ROUNDCUBEMAIL_DEFAULT_PORT=993 (o 143)"
    echo "      - ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true (si usas puerto 993)"
    echo "   4. Reinicia el servicio: docker service update --force $SERVICE_NAME"
    echo ""
fi

# Verificar si falta el puerto
if [ -z "$DEFAULT_PORT" ]; then
    echo "❌ PROBLEMA IDENTIFICADO:"
    echo "   Falta la configuración del puerto IMAP (ROUNDCUBEMAIL_DEFAULT_PORT)"
    echo ""
    echo "   SOLUCIÓN:"
    echo "   1. Ve a EasyPanel → Servicio 'webmail' → Variables de Entorno"
    echo "   2. Agrega ROUNDCUBEMAIL_DEFAULT_PORT=993 (con SSL) o 143 (sin SSL)"
    echo "   3. Si usas puerto 993, también agrega: ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true"
    echo ""
fi

# Verificar conectividad
if ! timeout 2 bash -c "echo > /dev/tcp/$IMAP_HOST/993" 2>/dev/null && ! timeout 2 bash -c "echo > /dev/tcp/$IMAP_IP/993" 2>/dev/null; then
    echo "❌ PROBLEMA IDENTIFICADO:"
    echo "   No se puede conectar al servidor IMAP en el puerto 993"
    echo ""
    echo "   POSIBLES CAUSAS:"
    echo "   1. No hay un servidor de correo configurado"
    echo "   2. El servidor de correo no está corriendo"
    echo "   3. El firewall está bloqueando el puerto 993"
    echo "   4. El servidor de correo está en otra IP o puerto"
    echo ""
    echo "   SOLUCIÓN:"
    echo "   1. Verifica si tienes un servidor de correo instalado (Postfix + Dovecot)"
    echo "   2. Si no lo tienes, necesitas:"
    echo "      - Instalar un servidor de correo, O"
    echo "      - Configurar el webmail para usar un servidor de correo externo"
    echo ""
fi

# Verificar si hay servidor de correo
if [ -z "$DOCKER_MAIL" ] && [ -z "$SYSTEM_MAIL" ]; then
    echo "⚠️  ADVERTENCIA:"
    echo "   No se encontró ningún servidor de correo corriendo"
    echo "   El webmail necesita un servidor IMAP para funcionar"
    echo ""
    echo "   OPCIONES:"
    echo "   1. Instalar un servidor de correo (Postfix + Dovecot)"
    echo "   2. Usar un servicio de correo externo (Gmail, Outlook, etc.)"
    echo "      y configurar el webmail para conectarse a ese servidor"
    echo ""
fi

echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
