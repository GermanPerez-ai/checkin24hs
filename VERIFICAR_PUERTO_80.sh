#!/bin/bash
# Verificar qué está usando el puerto 80

echo "=== Verificando qué servicios están usando el puerto 80 ==="

# 1. Ver servicios de Docker Swarm
echo ""
echo "1. Servicios de Docker Swarm:"
docker service ls

# 2. Ver qué puertos están expuestos en cada servicio
echo ""
echo "2. Puertos expuestos por servicios:"
docker service ls --format "table {{.Name}}\t{{.Ports}}"

# 3. Ver específicamente webmail
echo ""
echo "3. Configuración del servicio webmail:"
docker service inspect checkin24hs_webmail --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{println}}{{end}}' 2>/dev/null || echo "Servicio webmail no encontrado"

# 4. Ver configuración del servicio cotizador
echo ""
echo "4. Configuración del servicio cotizador:"
docker service inspect cotizador --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}}/{{.Protocol}}{{println}}{{end}}' 2>/dev/null || echo "Sin puertos publicados"

# 5. Ver qué está escuchando en el puerto 80 del host
echo ""
echo "5. Procesos escuchando en puerto 80 del host:"
sudo netstat -tulpn | grep :80 || sudo ss -tulpn | grep :80

# 6. Ver contenedores que exponen puerto 80
echo ""
echo "6. Contenedores que exponen puerto 80:"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 80

# 7. Ver redes y qué servicios están en cada una
echo ""
echo "7. Redes y servicios:"
echo "Red easypanel:"
docker network inspect xmv09tpxwryie79b0jv531623 --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | tr ' ' '\n' | grep -v "^$"
