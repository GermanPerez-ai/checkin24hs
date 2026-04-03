#!/bin/bash
# Verificar qué está usando el puerto 8080

echo "🔍 Verificando qué está usando el puerto 8080..."
echo ""

# Verificar procesos en el puerto 8080
echo "1️⃣  Procesos usando puerto 8080:"
lsof -i :8080 2>/dev/null || netstat -tulpn | grep :8080 || ss -tulpn | grep :8080
echo ""

# Verificar contenedores Docker usando puerto 8080
echo "2️⃣  Contenedores Docker usando puerto 8080:"
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}" | grep 8080
echo ""

# Verificar servicios Docker Swarm usando puerto 8080
echo "3️⃣  Servicios Docker Swarm usando puerto 8080:"
docker service ls --format "table {{.Name}}\t{{.Ports}}" | grep 8080
echo ""

echo "💡 Si encuentras algo usando el puerto 8080, puedes:"
echo "   1. Usar otro puerto (ej: 8081, 8082, etc.)"
echo "   2. Detener el servicio que usa el puerto 8080"
echo ""
