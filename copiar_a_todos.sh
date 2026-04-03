#!/bin/bash
cd /root/checkin24hs

echo "=== COPIANDO A TODOS LOS CONTENEDORES ==="
echo ""

# Lista de contenedores
CONTAINERS=(
    "checkin24hs_dashboard.1.v05zfiv0m8tnhqxlg52ugi3ur"
    "checkin24hs_dashboard.1.d7nv4sbj67mk1du60og7ih90t"
    "checkin24hs_dashboard.1.1n4i84vqrhrr82iohy4fp39x2"
    "checkin24hs_dashboard.1.2953li8rsiyllvpy2uhii45n8"
    "checkin24hs_dashboard.1.jrfny1ufj3lmt4w877ufcag4n"
)

# Detener primero
echo "🛑 Deteniendo contenedores..."
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3
echo "✅ Detenidos"
echo ""

# Copiar a cada uno
for c in "${CONTAINERS[@]}"; do
    echo "Copiando a: $c"
    if docker cp deploy/dashboard.html "$c:/app/dashboard.html" 2>/dev/null; then
        echo "✅ $c - Copiado a /app/dashboard.html"
    elif docker cp deploy/dashboard.html "$c:/usr/share/nginx/html/dashboard.html" 2>/dev/null; then
        echo "✅ $c - Copiado a /usr/share/nginx/html/dashboard.html"
    else
        echo "❌ $c - Error al copiar"
    fi
done
echo ""

# Reiniciar
echo "🚀 Reiniciando contenedores..."
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3
echo "✅ Reiniciados"
echo ""

echo "=== ESTADO FINAL ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep checkin24hs_dashboard
echo ""
echo "✅ Proceso completado!"










