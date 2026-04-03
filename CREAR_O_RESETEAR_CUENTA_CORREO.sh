#!/bin/bash

# Script para crear o resetear cuenta de correo

EMAIL="reservas@checkin24hs.com"
NUEVA_PASSWORD=""

echo "=== Crear o Resetear Cuenta de Correo ==="

# 1. Verificar si hay base de datos MySQL/MariaDB
echo ""
echo "1. Buscando base de datos de correo..."

# Buscar en Docker
DB_CONTAINER=$(docker ps --format "{{.Names}}" | grep -iE "mysql|mariadb|postgres" | head -1)

if [ ! -z "$DB_CONTAINER" ]; then
    echo "Base de datos encontrada en Docker: $DB_CONTAINER"
    echo ""
    echo "Para resetear la contraseña, ejecuta:"
    echo "  docker exec -it $DB_CONTAINER mysql -u root -p"
    echo ""
    echo "Luego en MySQL:"
    echo "  SHOW DATABASES;"
    echo "  USE [nombre_base_datos];  # Busca 'mail', 'postfix', 'vmail', etc."
    echo "  SHOW TABLES;"
    echo "  SELECT * FROM mailbox WHERE username='$EMAIL';"
    echo "  UPDATE mailbox SET password=ENCRYPT('NUEVA_CONTRASEÑA') WHERE username='$EMAIL';"
else
    echo "No se encontró base de datos en Docker"
fi

# 2. Verificar servicios del sistema
echo ""
echo "2. Verificando servicios del sistema..."
if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
    echo "MySQL/MariaDB está corriendo en el sistema"
    echo ""
    echo "Para resetear la contraseña, ejecuta:"
    echo "  mysql -u root -p"
    echo ""
    echo "Luego sigue los mismos pasos que arriba"
else
    echo "No se encontró MySQL/MariaDB del sistema"
fi

# 3. Verificar si hay panel de gestión
echo ""
echo "3. Buscando paneles de gestión..."
if docker ps --format "{{.Names}}" | grep -qiE "cpanel|plesk|webmin"; then
    echo "Panel de gestión encontrado en Docker"
    echo "Accede al panel y ve a 'Cuentas de Correo' para resetear la contraseña"
elif systemctl list-units --type=service | grep -qiE "cpanel|plesk|webmin"; then
    echo "Panel de gestión encontrado en el sistema"
    echo "Accede al panel y ve a 'Cuentas de Correo' para resetear la contraseña"
else
    echo "No se encontró panel de gestión"
fi

# 4. Verificar archivos de usuarios
echo ""
echo "4. Buscando archivos de usuarios de correo..."
find /var/mail -type d -name "*reservas*" 2>/dev/null | head -5
find /home -type d -name "*reservas*" 2>/dev/null | head -5

echo ""
echo "=== Verificación completada ==="
echo ""
echo "Si necesitas crear una nueva contraseña, puedes usar:"
echo "  openssl rand -base64 12"
echo ""
echo "Esto generará una contraseña segura aleatoria"


















