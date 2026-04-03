#!/bin/bash

cd /root/checkin24hs

echo "=== Verificando configuración del dominio ==="
echo ""

# 1. Verificar configuración de Traefik para el dominio
echo "=== 1. Configuración de Traefik para dashboard.checkin24hs.com ==="
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Labels}}{{.}}{{println}}{{end}}' | grep -i traefik | grep -i dashboard

echo ""
echo "=== 2. Verificando routers en Traefik ==="
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Routers relacionados con dashboard:"
    docker exec "$TRAEFIK_CONTAINER" wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -i dashboard || echo "❌ No se encontraron routers"
fi

echo ""
echo "=== 3. Verificando DNS del dominio ==="
echo "Resolviendo dashboard.checkin24hs.com:"
nslookup dashboard.checkin24hs.com 2>/dev/null || dig dashboard.checkin24hs.com +short 2>/dev/null || echo "⚠️ No se pudo resolver el DNS"

echo ""
echo "=== 4. Verificando acceso HTTPS ==="
HOST_IP=$(hostname -I | awk '{print $1}')
echo "IP del servidor: $HOST_IP"
echo ""
echo "Probando acceso HTTPS al dominio:"
curl -k -s -o /dev/null -w "HTTP Code: %{http_code}\n" https://dashboard.checkin24hs.com/ || echo "❌ No se pudo conectar"

echo ""
echo "=== 5. Solución: Verificar y corregir configuración del dominio ==="
echo ""
echo "Para que funcione con la URL, necesitas:"
echo "1. Que el DNS de 'dashboard.checkin24hs.com' apunte a: $HOST_IP"
echo "2. Que Traefik tenga la regla correcta para el dominio"
echo "3. Que el certificado SSL esté configurado (si usas HTTPS)"
echo ""
echo "Verificando configuración actual de Traefik para el dominio..."

# Verificar si existe la regla del dominio
DOMAIN_RULE=$(docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Labels}}{{.}}{{println}}{{end}}' | grep "traefik.http.routers.dashboard.rule" | grep "dashboard.checkin24hs.com")

if [ -z "$DOMAIN_RULE" ]; then
    echo "⚠️ No se encontró la regla del dominio. Agregándola..."
    
    docker service update \
      --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
      --label-add "traefik.http.routers.dashboard.entrypoints=websecure,web" \
      --label-add "traefik.http.routers.dashboard.tls=true" \
      --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
      checkin24hs_dashboard
    
    echo "✅ Regla del dominio agregada"
    echo "Esperando 20 segundos para que Traefik actualice..."
    sleep 20
else
    echo "✅ La regla del dominio ya está configurada"
fi

echo ""
echo "=== Instrucciones ==="
echo "1. Verifica que el DNS de 'dashboard.checkin24hs.com' apunta a: $HOST_IP"
echo "2. Prueba acceder con: https://dashboard.checkin24hs.com (HTTPS)"
echo "3. Si no funciona con HTTPS, prueba con: http://dashboard.checkin24hs.com (HTTP)"
echo "4. Espera 1-2 minutos después de cambiar el DNS para que se propague"


