# Resetear Contraseña de Correo

## Métodos según el Tipo de Servidor

### Método 1: Si usas cPanel/Plesk/Webmin

1. Accede al panel de control (cPanel, Plesk, etc.)
2. Ve a "Cuentas de Correo" o "Email Accounts"
3. Busca la cuenta `reservas@checkin24hs.com`
4. Haz clic en "Cambiar Contraseña" o "Reset Password"
5. Ingresa la nueva contraseña
6. Guarda los cambios

### Método 2: Si usas Postfix + Dovecot con Base de Datos MySQL/MariaDB

```bash
# 1. Conectarte a la base de datos
mysql -u root -p

# 2. Ver bases de datos disponibles
SHOW DATABASES;

# 3. Buscar la base de datos de correo (puede ser "mail", "postfix", "vmail", etc.)
USE mail;  # O el nombre que corresponda

# 4. Ver tablas
SHOW TABLES;

# 5. Ver cuentas de correo
SELECT * FROM mailbox;  # O la tabla que corresponda

# 6. Cambiar contraseña (ejemplo con tabla "mailbox")
UPDATE mailbox SET password = ENCRYPT('NUEVA_CONTRASEÑA') WHERE username = 'reservas@checkin24hs.com';
# O si usa otro método de hash:
UPDATE mailbox SET password = MD5('NUEVA_CONTRASEÑA') WHERE username = 'reservas@checkin24hs.com';
```

### Método 3: Si usas Postfix + Dovecot con archivos de sistema

```bash
# 1. Buscar archivos de usuarios
find /var/mail -name "*reservas*" 2>/dev/null
find /home -name "*reservas*" 2>/dev/null

# 2. Cambiar contraseña del usuario del sistema
passwd reservas
```

### Método 4: Si usas un servicio de correo externo

1. Accede al panel de control del proveedor (Gmail, Outlook, etc.)
2. Ve a la configuración de la cuenta
3. Cambia la contraseña desde ahí

### Método 5: Si usas Docker con servidor de correo

```bash
# 1. Identificar el contenedor del servidor de correo
docker ps | grep -iE "mail|postfix|dovecot"

# 2. Entrar al contenedor
docker exec -it [NOMBRE_CONTENEDOR] bash

# 3. Seguir los pasos del Método 2 o 3 según corresponda
```

## Verificar Tipo de Servidor

Ejecuta este comando para identificar qué tipo de servidor tienes:

```bash
# Ver servicios de correo
docker ps | grep -iE "mail|postfix|dovecot"
systemctl list-units --type=service | grep -iE "postfix|dovecot"

# Ver si hay base de datos
docker ps | grep -iE "mysql|postgres|mariadb"
systemctl list-units --type=service | grep -iE "mysql|postgres|mariadb"
```

## Crear Nueva Cuenta (Si no existe)

Si la cuenta `reservas@checkin24hs.com` no existe, necesitas crearla primero:

### Con cPanel/Plesk:
- Ve a "Crear Cuenta de Correo"
- Ingresa: `reservas@checkin24hs.com`
- Establece la contraseña
- Guarda

### Con Postfix + Dovecot:
Depende de cómo esté configurado. Puede ser:
- A través de una base de datos
- A través de archivos de configuración
- A través de un script de administración

## Próximos Pasos

1. Ejecuta el script de identificación para saber qué tipo de servidor tienes
2. Usa el método correspondiente para resetear la contraseña
3. Prueba iniciar sesión en el webmail con la nueva contraseña


















