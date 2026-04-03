#!/bin/bash
# Configurar Traefik para que apunte al dashboard en puerto 3000

echo "=== Ver logs del contenedor dashboard de EasyPanel ==="
docker logs checkin24hs_dashboard.1.mc8n7q6mrajiqcipq9rf2qg2p --tail 20

echo ""
echo "=== Verificar configuración de Traefik ==="
docker exec traefik.1.1qfkazdh5m0czg2hslan0ny0g cat /etc/traefik/traefik.yml 2>/dev/null || echo "No se puede acceder a la configuración"

echo ""
echo "=== Opciones ==="
echo "1. El dashboard de EasyPanel debería estar configurado desde la interfaz de EasyPanel"
echo "2. O necesitamos configurar Traefik para que apunte al puerto 3000"
echo ""
echo "Para configurar desde EasyPanel:"
echo "- Acceder a EasyPanel"
echo "- Ir al proyecto 'checkin24hs'"
echo "- Editar el servicio 'dashboard'"
echo "- Configurar el dominio 'dashboard.checkin24hs.com'"
echo "- Asegurarse de que apunte al puerto correcto"

