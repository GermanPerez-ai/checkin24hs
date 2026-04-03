#!/bin/bash

echo "=========================================="
echo "🔍 IDENTIFICANDO PROCESOS EN PUERTOS 80, 443, 8080"
echo "=========================================="
echo ""

# Verificar qué proceso está usando el puerto 80
echo "1️⃣ Proceso usando puerto 80:"
echo "=========================================="
lsof -i :80 2>/dev/null || netstat -tlnp | grep :80 || ss -tlnp | grep :80
echo ""

# Verificar qué proceso está usando el puerto 443
echo "2️⃣ Proceso usando puerto 443:"
echo "=========================================="
lsof -i :443 2>/dev/null || netstat -tlnp | grep :443 || ss -tlnp | grep :443
echo ""

# Verificar qué proceso está usando el puerto 8080
echo "3️⃣ Proceso usando puerto 8080:"
echo "=========================================="
lsof -i :8080 2>/dev/null || netstat -tlnp | grep :8080 || ss -tlnp | grep :8080
echo ""

# Verificar si hay otro nginx corriendo
echo "4️⃣ Procesos nginx corriendo:"
echo "=========================================="
ps aux | grep nginx | grep -v grep
echo ""

# Verificar si hay otro servidor web (apache, caddy, etc.)
echo "5️⃣ Otros servidores web corriendo:"
echo "=========================================="
ps aux | grep -E "apache|httpd|caddy|traefik" | grep -v grep
echo ""

# Verificar si hay contenedores Docker usando esos puertos
echo "6️⃣ Contenedores Docker usando puertos 80, 443, 8080:"
echo "=========================================="
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "80|443|8080"
echo ""

echo "=========================================="
echo "📋 SOLUCIONES POSIBLES:"
echo "=========================================="
echo ""
echo "Si hay otro nginx corriendo:"
echo "  - Detenerlo: pkill nginx o systemctl stop nginx (si está en otro modo)"
echo ""
echo "Si hay un contenedor Docker usando esos puertos:"
echo "  - Verificar si es necesario o si se puede cambiar"
echo ""
echo "Si hay otro servidor web:"
echo "  - Decidir cuál mantener (nginx o el otro)"
echo ""



