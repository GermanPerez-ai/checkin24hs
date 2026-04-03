#!/bin/bash
# Script para diagnosticar whatsapp1.checkin24hs.com

echo "=== Diagnóstico de whatsapp1.checkin24hs.com ==="
echo ""

# 1. Verificar DNS
echo "1. Verificando DNS..."
nslookup whatsapp1.checkin24hs.com 2>&1 | head -10
echo ""

# 2. Verificar servicios Docker relacionados con WhatsApp
echo "2. Verificando servicios Docker de WhatsApp..."
docker service ls | grep -i whatsapp
docker ps | grep -i whatsapp
echo ""

# 3. Verificar puerto 3001
echo "3. Verificando puerto 3001..."
netstat -tuln 2>/dev/null | grep 3001 || ss -tuln 2>/dev/null | grep 3001
echo ""

# 4. Verificar contenedores en puerto 3001
echo "4. Verificando contenedores en puerto 3001..."
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 3001
echo ""

# 5. Verificar configuración de Traefik para whatsapp1
echo "5. Verificando configuración de Traefik..."
docker service ls --format "{{.Name}}" | while read service; do
    echo "Servicio: $service"
    docker service inspect $service --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "whatsapp1\|3001" | head -5
done
echo ""

# 6. Probar conexión directa al puerto 3001
echo "6. Probando conexión directa al puerto 3001..."
curl -I http://localhost:3001 2>&1 | head -5
curl -I http://72.61.58.240:3001 2>&1 | head -5
echo ""

# 7. Verificar logs de Traefik relacionados con whatsapp1
echo "7. Verificando logs de Traefik (últimas 50 líneas)..."
docker service logs traefik --tail 50 2>&1 | grep -i "whatsapp1\|3001" | tail -10
echo ""

# 8. Verificar si hay algún servicio corriendo en puerto 3001
echo "8. Verificando procesos en puerto 3001..."
lsof -i :3001 2>/dev/null || echo "lsof no disponible, usando netstat..."
netstat -tulpn 2>/dev/null | grep 3001 || ss -tulpn 2>/dev/null | grep 3001
echo ""

echo "=== Diagnóstico completado ==="






