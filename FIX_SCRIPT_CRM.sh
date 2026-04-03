#!/bin/bash
# Convertir terminaciones de línea y ejecutar

cd ~/checkin24hs

# Convertir CRLF a LF
sed -i 's/\r$//' ELIMINAR_SERVICIO_CRM.sh

# Dar permisos
chmod +x ELIMINAR_SERVICIO_CRM.sh

# Ejecutar
./ELIMINAR_SERVICIO_CRM.sh
