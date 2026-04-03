#!/bin/bash
# Verificar cómo EasyPanel está configurando Traefik

echo "=== VERIFICANDO CONFIGURACIÓN DE TRAEFIK ==="
echo ""

TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ Traefik no encontrado"
    exit 1
fi

echo "✅ Traefik: $TRAEFIK_CONTAINER"
echo ""

# 1. Ver configuración de Traefik
echo "1️⃣ Configuración de Traefik..."
echo "=========================================="
docker exec $TRAEFIK_CONTAINER cat /etc/traefik/traefik.yml 2>/dev/null | head -50 || echo "   (no se encontró traefik.yml)"

# 2. Ver archivos de configuración dinámica
echo ""
echo "2️⃣ Archivos de configuración dinámica..."
echo "=========================================="
docker exec $TRAEFIK_CONTAINER ls -la /etc/traefik/dynamic/ 2>/dev/null || echo "   (no existe directorio dynamic)"
docker exec $TRAEFIK_CONTAINER find /etc/traefik -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -10

# 3. Ver variables de entorno de Traefik
echo ""
echo "3️⃣ Variables de entorno de Traefik..."
echo "=========================================="
docker inspect $TRAEFIK_CONTAINER --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -i "docker\|swarm\|provider" | head -10

# 4. Ver otros servicios que funcionan
echo ""
echo "4️⃣ Otros servicios en Docker Swarm..."
echo "=========================================="
docker service ls --format "{{.Name}}" | head -10

# 5. Verificar si hay otros servicios con dominios configurados
echo ""
echo "5️⃣ Verificando otros servicios con labels traefik..."
echo "=========================================="
for service in $(docker service ls --format "{{.Name}}" | head -5); do
    labels=$(docker service inspect $service --format '{{range $k, $v := .Spec.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' | grep traefik | head -3)
    if [ -n "$labels" ]; then
        echo "   $service:"
        echo "$labels" | sed 's/^/      /'
    fi
done

echo ""
echo "=========================================="
echo "📋 CONCLUSIÓN"
echo "=========================================="
echo ""
echo "Si Traefik no tiene configuración de Docker Swarm:"
echo "   → EasyPanel está usando otro método (archivos de configuración)"
echo "   → Necesitas configurar el dominio desde EasyPanel"
echo ""
