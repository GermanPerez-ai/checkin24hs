#!/bin/bash
# Script para liberar puerto 3000 e instalar EasyPanel

echo "=========================================="
echo "LIBERAR PUERTO 3000 E INSTALAR EASYPANEL"
echo "=========================================="
echo ""

# 1. Detener PM2 dashboard
echo "1. Deteniendo PM2 dashboard..."
pm2 stop dashboard 2>/dev/null
pm2 delete dashboard 2>/dev/null
echo "✅ PM2 dashboard detenido"
echo ""

# 2. Ver qué proceso está usando el puerto 3000
echo "2. Verificando qué está usando el puerto 3000..."
sudo lsof -i :3000
echo ""

# 3. Matar cualquier proceso usando el puerto 3000
echo "3. Liberando puerto 3000..."
PID=$(sudo lsof -ti :3000)
if [ ! -z "$PID" ]; then
    echo "   Matando proceso PID: $PID"
    sudo kill -9 $PID 2>/dev/null
    sleep 2
fi

# Verificar que el puerto esté libre
if sudo lsof -i :3000 > /dev/null 2>&1; then
    echo "⚠️  El puerto 3000 aún está en uso"
    sudo lsof -i :3000
else
    echo "✅ Puerto 3000 liberado"
fi
echo ""

# 4. Detener contenedor Docker dashboard-nginx-proxy si existe
echo "4. Deteniendo contenedor Docker dashboard-nginx-proxy..."
docker stop dashboard-nginx-proxy 2>/dev/null
docker rm dashboard-nginx-proxy 2>/dev/null
echo "✅ Contenedor Docker detenido (si existía)"
echo ""

# 5. Instalar EasyPanel
echo "5. Instalando EasyPanel..."
echo "   Ejecutando comando de instalación oficial..."

# Comando oficial de instalación de EasyPanel
curl -fsSL https://easypanel.io/install.sh | bash

echo ""
echo "=========================================="
echo "INSTALACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📋 Próximos pasos:"
echo "   1. Accede a EasyPanel en: http://72.61.58.240:3000"
echo "   2. Crea un nuevo servicio para el dashboard"
echo "   3. Configura el servicio para servir dashboard.html"
echo ""
echo "✅ Puerto 3000 liberado y EasyPanel instalado"


