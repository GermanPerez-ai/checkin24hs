#!/bin/bash

# Script para verificar la configuración IMAP del webmail

SERVICE_NAME="checkin24hs_webmail"

echo "=== Verificando configuración IMAP del webmail ==="

# 1. Ver variables de entorno
echo ""
echo "1. Variables de entorno del servicio:"
docker service inspect $SERVICE_NAME --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{printf "%s\n" .}}{{end}}' | grep -iE "ROUNDCUBE|IMAP|SMTP|MAIL|HOST|PORT"

# 2. Ver configuración dentro del contenedor
echo ""
echo "2. Configuración dentro del contenedor:"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo ""
    echo "Archivo config.inc.php (últimas 30 líneas):"
    docker exec $CONTAINER_ID tail -30 /var/www/html/config/config.inc.php 2>&1 | grep -v "^$" || echo "No se pudo leer el archivo"
    
    echo ""
    echo "Archivo config.docker.inc.php:"
    docker exec $CONTAINER_ID cat /var/www/html/config/config.docker.inc.php 2>&1 | head -50
fi

# 3. Verificar conectividad con el servidor IMAP
echo ""
echo "3. Verificando conectividad con el servidor IMAP:"
echo "Intentando conectar a 72.61.58.240:993 (IMAP SSL)..."
timeout 5 bash -c "echo > /dev/tcp/72.61.58.240/993" 2>&1 && echo "✅ Puerto 993 accesible" || echo "❌ Puerto 993 no accesible"

echo "Intentando conectar a 72.61.58.240:143 (IMAP)..."
timeout 5 bash -c "echo > /dev/tcp/72.61.58.240/143" 2>&1 && echo "✅ Puerto 143 accesible" || echo "❌ Puerto 143 no accesible"

# 4. Verificar si hay un servidor de correo corriendo
echo ""
echo "4. Verificando servicios de correo en el servidor:"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -iE "mail|postfix|dovecot|imap|smtp" || echo "No se encontraron servicios de correo en Docker"

# Verificar servicios del sistema
systemctl list-units --type=service --state=running | grep -iE "postfix|dovecot|imap|smtp" || echo "No se encontraron servicios de correo del sistema"

echo ""
echo "=== Verificación completada ==="






