#!/bin/bash

# Script para verificar si hay un servidor de correo configurado

echo "=== Verificando servidor de correo ==="

# 1. Ver servicios Docker relacionados con correo
echo ""
echo "1. Servicios Docker relacionados con correo:"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -iE "mail|postfix|dovecot|imap|smtp" || echo "No se encontraron servicios de correo en Docker"

# 2. Ver servicios del sistema relacionados con correo
echo ""
echo "2. Servicios del sistema relacionados con correo:"
systemctl list-units --type=service --state=running | grep -iE "postfix|dovecot|imap|smtp" || echo "No se encontraron servicios de correo del sistema"

# 3. Verificar puertos IMAP/SMTP
echo ""
echo "3. Verificando puertos IMAP/SMTP:"
for port in 25 143 465 587 993 995; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        SERVICE=$(lsof -i :$port 2>/dev/null | tail -1 | awk '{print $1}' || echo "desconocido")
        echo "Puerto $port: OCUPADO (por $SERVICE)"
    else
        echo "Puerto $port: LIBRE"
    fi
done

# 4. Verificar configuración del webmail
echo ""
echo "4. Configuración del webmail (variables de entorno):"
docker service inspect checkin24hs_webmail --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{printf "%s\n" .}}{{end}}' | grep -iE "ROUNDCUBE|IMAP|SMTP|HOST|MAIL" | head -10

# 5. Verificar si mail.checkin24hs.com resuelve
echo ""
echo "5. Verificando resolución DNS de mail.checkin24hs.com:"
nslookup mail.checkin24hs.com 2>&1 | head -5

# 6. Verificar conectividad con mail.checkin24hs.com
echo ""
echo "6. Verificando conectividad con mail.checkin24hs.com:"
timeout 5 bash -c "echo > /dev/tcp/72.61.58.240/993" 2>&1 && echo "✅ Puerto 993 (IMAP SSL) accesible" || echo "❌ Puerto 993 no accesible"
timeout 5 bash -c "echo > /dev/tcp/72.61.58.240/143" 2>&1 && echo "✅ Puerto 143 (IMAP) accesible" || echo "❌ Puerto 143 no accesible"
timeout 5 bash -c "echo > /dev/tcp/72.61.58.240/587" 2>&1 && echo "✅ Puerto 587 (SMTP) accesible" || echo "❌ Puerto 587 no accesible"

echo ""
echo "=== Verificación completada ==="
echo ""
echo "Si los puertos están LIBRES, necesitas configurar un servidor de correo."
echo "Si los puertos están OCUPADOS, el servidor de correo está corriendo."






