#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNÓSTICO COMPLETO - Webmail y EasyPanel"
echo "=========================================="
echo ""

# 1. DIAGNÓSTICO WEBMAIL
echo "📧 === 1. DIAGNÓSTICO WEBMAIL ==="
echo ""
echo "Servicios Docker relacionados con webmail:"
docker ps | grep -i webmail || echo "❌ No se encontraron servicios webmail"
docker ps | grep -i roundcube || echo "❌ No se encontraron servicios roundcube"
echo ""

echo "Servicios Docker Swarm:"
docker service ls | grep -i webmail || echo "❌ No se encontraron servicios webmail en Swarm"
echo ""

echo "Configuración Traefik para webmail:"
grep -A 10 -i "webmail\|roundcube" /etc/easypanel/traefik/config/main.yaml 2>/dev/null || echo "❌ No se encontró configuración en Traefik"
echo ""

# 2. DIAGNÓSTICO EASYPANEL
echo "⚙️ === 2. DIAGNÓSTICO EASYPANEL ==="
echo ""
echo "Servicios Docker relacionados con EasyPanel:"
docker ps | grep -i easypanel
echo ""

echo "Puertos de EasyPanel:"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -i easypanel
echo ""

echo "Configuración Traefik para EasyPanel:"
grep -B 5 -A 15 -i "easypanel\|3000" /etc/easypanel/traefik/config/main.yaml 2>/dev/null | head -30 || echo "❌ No se encontró configuración"
echo ""

# 3. VERIFICAR PUERTO 3000 (Dashboard)
echo "📊 === 3. VERIFICAR PUERTO 3000 (Dashboard) ==="
echo ""
echo "¿Qué está corriendo en el puerto 3000?"
netstat -tulpn | grep :3000 || ss -tulpn | grep :3000
echo ""

echo "Proceso en puerto 3000:"
lsof -i :3000 2>/dev/null || echo "No se pudo determinar"
echo ""

# 4. VERIFICAR PUERTO 8080 (Posible EasyPanel)
echo "⚙️ === 4. VERIFICAR PUERTO 8080 (Posible EasyPanel) ==="
echo ""
netstat -tulpn | grep :8080 || ss -tulpn | grep :8080 || echo "❌ Nada corriendo en 8080"
echo ""

# 5. RESUMEN
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "Servicios Docker activos:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
echo ""

