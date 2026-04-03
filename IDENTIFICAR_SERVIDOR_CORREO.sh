#!/bin/bash

# Script para identificar el servidor de correo y cómo resetear contraseñas

echo "=== Identificando servidor de correo ==="

# 1. Ver servicios Docker relacionados con correo
echo ""
echo "1. Servicios Docker relacionados con correo:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}" | grep -iE "mail|postfix|dovecot|imap|smtp"

# 2. Ver servicios del sistema
echo ""
echo "2. Servicios del sistema relacionados con correo:"
systemctl list-units --type=service --state=running | grep -iE "postfix|dovecot|imap|smtp|mail"

# 3. Verificar si hay base de datos de correo
echo ""
echo "3. Buscando bases de datos de correo:"
docker ps --format "{{.Names}}" | grep -iE "mysql|postgres|mariadb" || echo "No se encontraron bases de datos en Docker"
systemctl list-units --type=service | grep -iE "mysql|postgres|mariadb" || echo "No se encontraron bases de datos del sistema"

# 4. Verificar configuración de Postfix (si existe)
echo ""
echo "4. Verificando configuración de Postfix:"
if [ -f "/etc/postfix/main.cf" ]; then
    echo "Archivo de configuración encontrado: /etc/postfix/main.cf"
    grep -iE "virtual_mailbox|virtual_mailbox_domains|mysql|database" /etc/postfix/main.cf | head -10
else
    echo "No se encontró configuración de Postfix en /etc/postfix/"
fi

# 5. Verificar configuración de Dovecot (si existe)
echo ""
echo "5. Verificando configuración de Dovecot:"
if [ -d "/etc/dovecot" ]; then
    echo "Directorio de configuración encontrado: /etc/dovecot"
    find /etc/dovecot -name "*.conf" -type f | head -5
else
    echo "No se encontró configuración de Dovecot en /etc/dovecot/"
fi

# 6. Verificar si hay panel de gestión (cPanel, Plesk, etc.)
echo ""
echo "6. Buscando paneles de gestión:"
docker ps --format "{{.Names}}" | grep -iE "cpanel|plesk|webmin|roundcube" || echo "No se encontraron paneles en Docker"
systemctl list-units --type=service | grep -iE "cpanel|plesk|webmin" || echo "No se encontraron paneles del sistema"

echo ""
echo "=== Verificación completada ==="


















