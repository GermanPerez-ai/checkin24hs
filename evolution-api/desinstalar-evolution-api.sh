#!/bin/bash

cd /root/checkin24hs/evolution-api

echo "🗑️  DESINSTALANDO EVOLUTION API"
echo "================================"
echo ""

# Verificar si existe docker-compose.yml
if [ ! -f docker-compose.yml ]; then
    echo "⚠️  docker-compose.yml no encontrado"
    echo "   Puede que Evolution API ya esté desinstalado"
    echo ""
fi

echo "1️⃣  Deteniendo y eliminando contenedores..."
echo ""

# Detener y eliminar contenedores
if docker ps -a | grep -q evolution-api-checkin24hs; then
    echo "   🛑 Deteniendo contenedor..."
    docker stop evolution-api-checkin24hs 2>/dev/null || true
    docker rm evolution-api-checkin24hs 2>/dev/null || true
    echo "   ✅ Contenedor eliminado"
else
    echo "   ℹ️  No hay contenedores de Evolution API"
fi

if docker ps -a | grep -q evolution-redis; then
    echo "   🛑 Deteniendo contenedor Redis..."
    docker stop evolution-redis 2>/dev/null || true
    docker rm evolution-redis 2>/dev/null || true
    echo "   ✅ Contenedor Redis eliminado"
fi

echo ""
echo "2️⃣  Eliminando volúmenes (datos guardados)..."
echo ""

# Eliminar volúmenes
if docker volume ls | grep -q evolution_instances; then
    echo "   🗑️  Eliminando volumen evolution_instances..."
    docker volume rm evolution_instances 2>/dev/null || true
    echo "   ✅ Volumen eliminado"
fi

if docker volume ls | grep -q evolution_store; then
    echo "   🗑️  Eliminando volumen evolution_store..."
    docker volume rm evolution_store 2>/dev/null || true
    echo "   ✅ Volumen eliminado"
fi

if docker volume ls | grep -q redis_data; then
    echo "   🗑️  Eliminando volumen redis_data..."
    docker volume rm redis_data 2>/dev/null || true
    echo "   ✅ Volumen eliminado"
fi

if docker volume ls | grep -q evolution-api_evolution_instances; then
    echo "   🗑️  Eliminando volumen evolution-api_evolution_instances..."
    docker volume rm evolution-api_evolution_instances 2>/dev/null || true
    echo "   ✅ Volumen eliminado"
fi

if docker volume ls | grep -q evolution-api_evolution_store; then
    echo "   🗑️  Eliminando volumen evolution-api_evolution_store..."
    docker volume rm evolution-api_evolution_store 2>/dev/null || true
    echo "   ✅ Volumen eliminado"
fi

echo ""
echo "3️⃣  Eliminando redes..."
echo ""

# Eliminar redes
if docker network ls | grep -q evolution-network; then
    echo "   🗑️  Eliminando red evolution-network..."
    docker network rm evolution-network 2>/dev/null || true
    echo "   ✅ Red eliminada"
fi

if docker network ls | grep -q evolution-api_evolution-network; then
    echo "   🗑️  Eliminando red evolution-api_evolution-network..."
    docker network rm evolution-api_evolution-network 2>/dev/null || true
    echo "   ✅ Red eliminada"
fi

echo ""
echo "4️⃣  Usando docker-compose down (si existe)..."
echo ""

# Intentar docker-compose down si existe el archivo
if [ -f docker-compose.yml ]; then
    echo "   🔄 Ejecutando docker-compose down..."
    docker-compose down -v 2>/dev/null || true
    echo "   ✅ docker-compose down completado"
else
    echo "   ℹ️  docker-compose.yml no existe, saltando..."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RESUMEN DE LIMPIEZA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar qué quedó
REMAINING_CONTAINERS=$(docker ps -a | grep -i evolution | wc -l)
REMAINING_VOLUMES=$(docker volume ls | grep -i evolution | wc -l)
REMAINING_NETWORKS=$(docker network ls | grep -i evolution | wc -l)

echo "📊 Verificando elementos restantes:"
echo ""

if [ "$REMAINING_CONTAINERS" -gt 0 ]; then
    echo "   ⚠️  Contenedores restantes: $REMAINING_CONTAINERS"
    docker ps -a | grep -i evolution
else
    echo "   ✅ No hay contenedores restantes"
fi

echo ""

if [ "$REMAINING_VOLUMES" -gt 0 ]; then
    echo "   ⚠️  Volúmenes restantes: $REMAINING_VOLUMES"
    docker volume ls | grep -i evolution
else
    echo "   ✅ No hay volúmenes restantes"
fi

echo ""

if [ "$REMAINING_NETWORKS" -gt 0 ]; then
    echo "   ⚠️  Redes restantes: $REMAINING_NETWORKS"
    docker network ls | grep -i evolution
else
    echo "   ✅ No hay redes restantes"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❓ ¿Eliminar archivos de configuración?"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Los siguientes archivos aún existen:"
echo ""

if [ -f docker-compose.yml ]; then
    echo "   📄 docker-compose.yml"
fi

if [ -f docker-compose.yml.backup.* ]; then
    echo "   📄 docker-compose.yml.backup.*"
fi

echo ""
read -p "¿Deseas eliminar estos archivos también? (s/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[SsYy]$ ]]; then
    echo ""
    echo "🗑️  Eliminando archivos de configuración..."
    
    # Crear backup antes de eliminar
    if [ -f docker-compose.yml ]; then
        cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        rm -f docker-compose.yml
        echo "   ✅ docker-compose.yml eliminado (backup creado)"
    fi
    
    rm -f docker-compose.yml.backup.* 2>/dev/null || true
    
    echo "   ✅ Archivos eliminados"
else
    echo ""
    echo "   ℹ️  Archivos preservados (puedes eliminarlos manualmente después)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DESINSTALACIÓN COMPLETADA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Lo que se eliminó:"
echo "   ✅ Contenedores de Evolution API"
echo "   ✅ Volúmenes (instancias y datos)"
echo "   ✅ Redes de Docker"
echo ""
echo "📋 Lo que se preservó:"
echo "   📁 Directorio: /root/checkin24hs/evolution-api"
echo "   📄 Scripts de diagnóstico/instalación"
echo ""
echo "💡 Para eliminar el directorio completo:"
echo "   rm -rf /root/checkin24hs/evolution-api"
echo ""
echo "✅ Evolution API desinstalado"
echo ""
