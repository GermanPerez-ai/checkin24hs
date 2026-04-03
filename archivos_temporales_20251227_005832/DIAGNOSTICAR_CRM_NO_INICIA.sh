#!/bin/bash

# Script para diagnosticar por qué el servicio CRM no inicia

SERVICE_NAME="checkin24hs_crm"

echo "=== Diagnóstico del servicio CRM ==="

# 1. Ver estado del servicio
echo ""
echo "1. Estado del servicio:"
docker service ps $SERVICE_NAME --no-trunc | head -10

# 2. Ver logs recientes (errores)
echo ""
echo "2. Últimos logs (últimas 50 líneas):"
docker service logs $SERVICE_NAME --tail 50 2>&1

# 3. Ver logs de errores específicos
echo ""
echo "3. Buscando errores específicos:"
docker service logs $SERVICE_NAME --tail 100 2>&1 | grep -i "error\|cannot\|failed\|not found" | head -20

# 4. Verificar imagen
echo ""
echo "4. Verificando imagen Docker:"
docker images | grep crm

# 5. Intentar ejecutar la imagen manualmente para ver el error
echo ""
echo "5. Intentando ejecutar la imagen manualmente:"
docker run --rm easypanel/checkin24hs/crm:latest node serve-crm.js 2>&1 | head -20

# 6. Verificar archivos en la imagen
echo ""
echo "6. Verificando archivos en la imagen:"
docker run --rm easypanel/checkin24hs/crm:latest ls -lah /app/ | head -20

# 7. Verificar si serve-crm.js existe
echo ""
echo "7. Verificando si serve-crm.js existe en la imagen:"
docker run --rm easypanel/checkin24hs/crm:latest ls -lh /app/serve-crm.js 2>&1

# 8. Verificar si crm.html existe
echo ""
echo "8. Verificando si crm.html existe en la imagen:"
docker run --rm easypanel/checkin24hs/crm:latest ls -lh /app/crm.html 2>&1

echo ""
echo "=== Diagnóstico completado ==="






