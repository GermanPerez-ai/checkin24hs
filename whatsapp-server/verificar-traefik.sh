#!/bin/bash
# 🔍 Verificar si Traefik está bloqueando las peticiones

echo "=============================================================="
echo "🔍 VERIFICANDO TRAEFIK Y CONECTIVIDAD"
echo "=============================================================="
echo ""

# 1. Obtener contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "1️⃣  Contenedor: $CONTAINER_ID"
echo ""

# 2. Intentar conexión desde dentro del contenedor
echo "2️⃣  Probando conexión desde DENTRO del contenedor..."
echo "--------------------------------------------------------------"
docker exec $CONTAINER_ID sh -c "wget -qO- --timeout=3 http://localhost:3001/api/health 2>&1 || echo 'No responde desde dentro'" 2>&1
echo ""

# 3. Verificar puerto desde el host
echo "3️⃣  Verificando puerto 3001 desde el HOST..."
echo "--------------------------------------------------------------"
netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001 || echo "   ⚠️  Puerto 3001 no está escuchando en el host"
echo ""

# 4. Verificar servicios Traefik
echo "4️⃣  Verificando servicios Traefik..."
echo "--------------------------------------------------------------"
docker service ls | grep -i traefik || docker ps | grep -i traefik || echo "   ℹ️  No se encontró Traefik"
echo ""

# 5. Verificar si hay un proxy/reverse proxy configurado
echo "5️⃣  Verificando configuración de red del contenedor..."
echo "--------------------------------------------------------------"
docker inspect $CONTAINER_ID 2>/dev/null | grep -iE "network|proxy|traefik" | head -10 || echo "   ℹ️  No se encontró configuración especial"
echo ""

# 6. Intentar conexión directa al IP del contenedor
echo "6️⃣  Obteniendo IP del contenedor y probando conexión directa..."
echo "--------------------------------------------------------------"
CONTAINER_IP=$(docker inspect $CONTAINER_ID 2>/dev/null | grep -i "IPAddress" | head -1 | awk '{print $2}' | tr -d '",')
if [ -n "$CONTAINER_IP" ]; then
    echo "   IP del contenedor: $CONTAINER_IP"
    timeout 3 curl -s --max-time 2 http://$CONTAINER_IP:3001/api/health 2>&1 || echo "   ⚠️  No responde por IP directa"
else
    echo "   ⚠️  No se pudo obtener la IP del contenedor"
fi
echo ""

# 7. Verificar logs del contenedor para ver si recibe peticiones
echo "7️⃣  Verificando si el servidor recibe peticiones..."
echo "--------------------------------------------------------------"
echo "   (Esto requiere que hagas una petición mientras se ejecuta)"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
echo "💡 Si el servidor responde desde dentro pero no desde fuera:"
echo "   - Puede ser un problema de Traefik/proxy"
echo "   - Puede ser un problema de mapeo de puertos"
echo "   - Puede ser un firewall"
echo ""
